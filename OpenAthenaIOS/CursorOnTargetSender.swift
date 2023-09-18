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

enum CursorOnTargetError: String, Error {
    case IllegalArgumentException = "CoT: illegal argument"
}

extension Double {
    var degreesToRadians: Self { self * .pi / 180.0 }
}

public class CursorOnTargetSender
{
    var group: NWConnectionGroup?
    var eventUid: Int64 = 0
    var settings: AthenaSettings
    
    init(params: AthenaSettings) {
        settings = params
        let host: NWEndpoint.Host = NWEndpoint.Host(settings.takMulticastIP)
        let port: NWEndpoint.Port = NWEndpoint.Port(rawValue: settings.takMulticastPort)!
        
        guard let multicast = try? NWMulticastGroup(for: [ .hostPort(host: host,
                                                                     port: port) ]) else {
            print("Failed to initialize multicast group")
            return
        }

        let parameters = NWParameters.udp
        parameters.allowLocalEndpointReuse = true
        //group = NWConnectionGroup(with: multicast, using: .udp)
        group = NWConnectionGroup(with: multicast, using: parameters)
        group?.stateUpdateHandler = { (newState) in
            print("Group entered state \(String(describing: newState))")
        }
        
        // even though we are not intending to receive messages, we need to
        // set a receiver lest we will not be able to send; why?  No idea
        group?.setReceiveHandler(maximumMessageSize: 16384, rejectOversizedMessages: true) { (message,content,isComplete) in
            print("Received message")
        }
        group?.start(queue: .main)
    }
    
    deinit
    {
        print("CursorOnTargetSender: deinit")
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
    
    public func sendCoT(targetLat: Double, targetLon: Double, Hae: Double, Theta: Double, exifDateTimeISO: String) -> Bool {
        
        // check args
        if exifDateTimeISO == "" || exifDateTimeISO == "unknown" {
            print("Invalid image date")
            return false
        }
        if targetLat == 0.0 && targetLon == 0.0 && Hae == 0.0 && Theta == 0.0 {
            print("Invalid target")
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
        
        let uidStr = "openathena-ios+\(UIDevice.current.identifierForVendor!.uuidString)+\(Int(NSDate().timeIntervalSince1970))"
        
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
        print("sendCot: xml string is: ")
        print("\(xmlString)")
        let sendContent = Data(xmlString.utf8)
        
        // send away!
        group?.send(content: sendContent) { (error) in
            if error == nil {
                print("Send completed with no error")
            }
            else {
                print("Send completed with error \(String(describing:  error))")
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
    
    
} // CursorOnTargetSender
