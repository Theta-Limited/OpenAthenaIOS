//
//  DroneImageAutel.swift
//  OpenAthenaIOS
//
//  Created by Bobby Krupczak on 1/5/24.
//  Subclass DroneImage with Autel specific code, data, methods

import Foundation
import UIKit

public class DroneImageAutel: DroneImage
{
    // get altitude in meters
    // Use GPS data from digested metadata
    // For aolder autel drones, check if GPSAltitudeRef exists and is 1
    // if so, its below seal level and we should negate the value
    // return altitude in WGS84
    override public func getAltitude() throws -> Double
    {
        print("getAltitudeAutel started")
        let superAlt = try super.getAltitude()
        var alt = 0.0
        
        if metaData == nil {
            print("getAltitudeAutel: no metadata")
            throw DroneImageError.NoMetaData
        }
        
        if xmpDataRead == false {
            parseXmpMetaDataNoError()
        }
        
        if metaData!["drone:AbsoluteAltitude"] != nil {
            alt = (metaData!["drone:AbsoluteAltitude"] as! NSString).doubleValue
            print("getAltitudeAutel: drone:AbsoluteAltitude \(alt)")
        }
        
        // what about Camera:AboveGroundAltitude value? XXX
        // Autel also has exif:GPSAltitude and exif:GPSAltitudeRef
        
        print("getAltitudeAutel: alt is \(alt)")
        
        if alt == 0.0 {
            print("getAltitudeAutel: older autel model, using super class altitutde")
            return superAlt
        }
        
        var rtkFlag: Bool = false
        if metaData!["drone:RtkFlag"] != nil {
            rtkFlag = true
            print("getAltitudeAutel: rtkFlag \(rtkFlag) \(metaData!["drone:RtkFlag"])")
        }
        else {
            // convert from EGM96 to WGS84
            var offset = try EGM96Geoid.getOffset(lat: getLatitude(), lng: getLongitude())
            print("getAltitudeAutel: adjusting \(alt) with offset \(offset)")
            alt = alt - offset
        }
        
        print("getAltitudeAutel: \(alt) superAlt: \(superAlt)")
        
        if alt == 0.0  { return superAlt }
        
        return alt
    }
    
}
