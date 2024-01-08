//
//  DroneImageDJI.swift
//  OpenAthenaIOS
//
//  Created by Bobby Krupczak on 1/5/24.
//  Subclass DroneImage with DJI specific methods/code/data

import Foundation
import UIKit

public class DroneImageDJI: DroneImage
{
    
    // get altitude in meters
    // use GPS data from digested metadata
    // GPS->Altitude or drone specific AbsoluteAltitude
    // if below sea level, we should negate the value
    // return altitude in WGS84
    
    override public func getAltitude() throws -> Double
    {
        var alt = 0.0
        var gpsInfo: NSDictionary
        
        print("getAltitudeDJI: invoked")
        
        let superAlt = try super.getAltitude()
        
        if metaData == nil {
            print("getAltitudeDJI: no metadata, returning")
            throw DroneImageError.NoMetaData
        }
        
        if xmpDataRead == false {
            parseXmpMetaDataNoError()
        }
        
        if metaData!["drone-dji:AbsoluteAltitude"] != nil {
            alt = (metaData!["drone-dji:AbsoluteAltitude"] as! NSString).doubleValue
            print("getAltitudeDJI: drone-dji:AbsoluteAltitude \(alt)")
        }
        
        print("getAltitudeDJI: alt is \(alt) now going to make corrections")
        
        // for DJI drones, look for this flag bug ignore RtkAlt in drone-dji:AltitudeType=RtkAlt
        var rtkFlag = false
        
        if xmlStringCopy?.lowercased().contains("rtkflag") == true {
            print("getAltitudeDJI: rtkflag is true")
            rtkFlag = true
        }
        
        do {
            // DJI are EGM96
            // if tag rtkflag then its already in WGS84
            var offset: Double = 0.0
            
            if rtkFlag == false {
                offset = try EGM96Geoid.getOffset(lat: getLatitude(), lng: getLongitude())
                alt = alt - offset
                print("getAltitudeDJI: EGM96 offset is \(offset)")
            }
        }
        catch {
            print("getAltitudeDJI: error getting alt offset \(error)")
            throw error
        }
                
        print("getAltitudeDJI: alt is \(alt), super is \(superAlt)")
        
        if alt == 0.0 {
            return superAlt
        }
        
        return alt
    }
}

