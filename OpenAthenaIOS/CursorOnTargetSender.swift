//
//  CursorOnTargetSender.swift
//  OpenAthenaIOS
//
//  Send TAK Cursor on Target messages via IP multicast
//
//  Requested com.apple.developer.networking.multicast.entitlement
//  via Apple developer website.
//  Multicast will work in the simulators in the interim
//  Once entitlement is granted, see
//  https://developer.apple.com/forums/thread/663271?answerId=639455022#639455022
//  To add entitlement to developer profile and app based on app ID
//  Then, in Xcode, go into project capabilities and add there.  You may need to
//  create .entitlements files for targets; I also needed to exit Xcode,
//  delete DerivedData, and then start Xcode for the entitlement to take effect
//  Verify entitlement is in app via codesign utility; see URL above for invocation
//
//  Created by Bobby Krupczak on 9/13/23.
//

import Foundation
import Network
import UIKit
import CryptoKit

enum CursorOnTargetError: String, Error {
    case IllegalArgumentException = "CoT: illegal argument"
}

extension Double {
    var degreesToRadians: Self { self * .pi / 180.0 }
}

public class CursorOnTargetSender
{
    var group: NWConnectionGroup?
    var settings: AthenaSettings
    var hashedHostname = ""
    
    init(params: AthenaSettings) {
        settings = params
        let host: NWEndpoint.Host = NWEndpoint.Host(settings.takMulticastIP)
        let port: NWEndpoint.Port = NWEndpoint.Port(rawValue: settings.takMulticastPort)!
        
        print("CursorOnTarget: init starting")
        
        hashedHostname = CursorOnTargetSender.getDeviceHostnameHash()
        
        guard let multicast = try? NWMulticastGroup(for: [ .hostPort(host: host,
                                                                     port: port) ]) else {
            print("CursorOnTarget: Failed to initialize multicast group")
            return
        }

        let parameters = NWParameters.udp
        parameters.allowLocalEndpointReuse = true
        //group = NWConnectionGroup(with: multicast, using: .udp)
        group = NWConnectionGroup(with: multicast, using: parameters)
        group?.stateUpdateHandler = { (newState) in
            print("CursorOnTarget: Group entered state \(String(describing: newState))")
        }
        
        // even though we are not intending to receive messages, we need to
        // set a receiver lest we will not be able to send; why?  No idea
        group?.setReceiveHandler(maximumMessageSize: 16384, rejectOversizedMessages: true) { (message,content,isComplete) in
            print("CursorOnTarget: received message")
        }
        group?.start(queue: .main)
        
        print("CursorOnTarget: init finished")
    }
    
    deinit
    {
        print("CursorOnTarget: deinit")
        group?.cancel()
    }
    
    // close group and
    public func close() {
        print("CursorOnTarget: closing")
        group?.cancel()
        
    }
    
    // return my status; true if group initialized and available to send
    // or false if not
    
    public func status() -> Bool {
        if group != nil { return true }
        return false
    }
    
    // send a CoT message given the selection parameters/location
    // exifDateTimeISO has already been converted
    
    public func sendCoT(targetLat: Double, targetLon: Double, Hae: Double, Theta: Double, exifDateTimeISO: String) -> Bool 
    {
        print("CursorOnTarget: sendCoT starting")
        
        // check args
        if exifDateTimeISO == "" || exifDateTimeISO == "unknown" {
            print("CursorOnTarget: invalid image date")
            return false
        }
        if targetLat == 0.0 && targetLon == 0.0 && Hae == 0.0 && Theta == 0.0 {
            print("CursorOnTarget: invalid target")
            return false
        }
        
        // calculate values, times
        let linearError:Double = 15.0 / 3.0
        let circularError:Double = 1.0 / tan(Theta.degreesToRadians) * linearError
        let ceStr = roundDigitsToString(val: circularError, precision: 6)
        let leStr = roundDigitsToString(val: linearError, precision: 6)
        let nowStr = getDateTimeISO()
        let nowPlusStr = getDateTimePlusFiveISO()
        let latStr = roundDigitsToString(val: targetLat, precision: 6)
        let lonStr = roundDigitsToString(val: targetLon, precision: 6)
        let haeStr = roundDigitsToString(val: Hae, precision: 6)
        
        //let uidStr = "openathena-ios+\(UIDevice.current.identifierForVendor!.uuidString)+\(Int(NSDate().timeIntervalSince1970))"
        
        // re issue #31 make this unique id shorter
        //let uidStr = "openathena-ios-\(hashedHostname)-\(Int(NSDate().timeIntervalSince1970))"
        
        let uidStr = "openathena-\(hashedHostname)-\(settings.eventUID)"
        settings.eventUID += 1
        settings.writeDefaults()
        
        // build the document and convert to string
        // because XMLDocument classes only available on MacOS, we'll
        // just build the doc by hand since the CoT message is pretty simple
        // this avoids having to add yet another CocoaPod and dealing with xcode
        
        // the document
        var xmlString = "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>"
        
        // add event
        xmlString += "<event version=\"2.0\" uid=\"\(uidStr)\" type=\"a-p-G\" how=\"h-c\" "
        xmlString += "time=\"\(exifDateTimeISO)\" start=\"\(nowStr)\" stale=\"\(nowPlusStr)\" >"
        
        // add point
        xmlString +=
          "<point lat=\"\(latStr)\" lon=\"\(lonStr)\" ce=\"\(ceStr)\" hae=\"\(haeStr)\" le=\"\(leStr)\" />"
        
        // add detail
        xmlString += "<detail>"
        xmlString += "<precisionLocation altsrc=\"DTED2\" geopointsrc=\"GPS\" />"
        xmlString += "<remarks>Generated by OpenAthena for iOS from sUAS data</remarks>"
        xmlString += "</detail>"

        // add closing
        xmlString += "</event>"
        
        // convert to Data to send
        //print("sendCot: xml string is: ")
        //print("\(xmlString)")
        let sendContent = Data(xmlString.utf8)
        
        // send away!
        group?.send(content: sendContent) { (error) in
            if error == nil {
                print("CursorOnTarget: sendCoT send completed with no error")
            }
            else {
                print("CursorOnTarget: sendCoT send completed with error \(String(describing:  error))")
            }
        }
       
        return true
    }
    
    // get current time plus 5 in iso8601 format
    // ChatGPT written
    private func getDateTimePlusFiveISO() -> String
    {
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime]
        let currentDateTime = Date()
        let currentDateTimePlus = currentDateTime.addingTimeInterval(300)
        return dateFormatter.string(from: currentDateTimePlus)
    }
    
    // ChatGPT written
    private func getDateTimeISO() -> String
    {
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime]
        let currentDateTime = Date()
        return dateFormatter.string(from: currentDateTime)
    }
    
    // take a double (e.g. lat, lon, elevation, etc. and round to x digits of precision
    // and return string
    
    private func roundDigitsToString(val: Double, precision: Double) -> String {
        let num = (val * pow(10,precision)).rounded(.toNearestOrAwayFromZero) / pow(10,precision)
        return String(num)
    }
    
    // written with aid of ChatGPT
    public class func getDeviceHostnameHash() -> String {
        var aString: String = ""
        
        aString = UIDevice.current.name
        if aString == "" {
            aString = "unknown-hostname"
        }
        if let inputData = aString.data(using: .utf8) {
            let hashData = SHA256.hash(data: inputData)
            let hashString = hashData.compactMap { String(format: "%02x",$0) }.joined()
            let truncatedHash = String(hashString.prefix(8))
            return truncatedHash
        }
        
        return "feedface"
    }
    
    
} // CursorOnTargetSender
