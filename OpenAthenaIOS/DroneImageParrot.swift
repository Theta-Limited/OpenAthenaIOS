//
//  DroneImageParrot.swift
//  OpenAthenaIOS
//
//  Created by Bobby Krupczak on 1/5/24.
//  Subclass DroneImage with Parrot specific code, data, methods

import Foundation
import UIKit

public class DroneImageParrot: DroneImage
{
    // get altitude in meters
    // use GPS data from digested metadata
    // GPS altitude or derone specific altitude
    // return altitude in WGS84
    
    override public func getAltitude() throws -> Double
    {
        print("getAltitude: Parrot started")
        var superAlt = try super.getAltitude()
        
        // ignore Camera:AboveGroundAltitude
        
        if metaData == nil {
            print("getAltitudeParrot no metadata")
            throw DroneImageError.NoMetaData
        }
        if xmpDataRead == false {
            parseXmpMetaDataNoError()
        }

        var alt = 0.0
        var altFromExif = true
        
        if metaData!["{GPS}"] == nil {
            print("getAltitudeParrot: no gps meta data")
            throw DroneImageError.NoMetaGPSData
        }
        var gpsInfo = metaData!["{GPS}"] as! NSDictionary
        if gpsInfo["Altitude"] == nil {
            print("getAltitudeParrot: no altitude within gps data")
            throw DroneImageError.MissingMetaDataKey
        }
        alt = gpsInfo["Altitude"] as! Double
    
        print("getAltitudeParrot: GPS alt is \(alt)")
        
        // check altitude ref; only check the first we find so as to not
        // convert more than once
        // Parrot often has multiple of these fields
        
        var ref: Int  = 0
        if gpsInfo["GPSAltitudeRef"] != nil {
            ref = gpsInfo["GPSAltitudeRef"] as! Int
            print("getAltitudeParrot: gps GPSAltitudeRef is \(ref)")
        }
        else if gpsInfo["AltitudeRef"] != nil {
            ref = gpsInfo["AltitudeRef"] as! Int
            print("getAltitudeParrot: gps AltitudeRef is \(ref)")
        }
        else if metaData!["exif:GPSAltitudeRef"] != nil {
            ref = (metaData!["exif:GPSAltitudeRef"] as! NSString).integerValue
            print("getAltitudeParrot: exif:GPSAltitudeRef is \(ref)")
        }            
        if ref == 1 { alt = -1.0 * alt }
        
        // parrots don't have rtkflag
        
        let model = try getCameraModel()
        print("getAltitudeParrot: model is \(model)")
                
        // if its parrot anafiai, alt is in wgs84
                
        if model.lowercased().contains("anafiai") == true {
            
            // Location altitude of where the photo was taken in meters expressed
            // as a fraction (e.g. “4971569/65536”) On ANAFI 4K/Thermal/USA, this
            // is the drone location with reference to the EGM96 geoid (AMSL); on
            // ANAFI Ai with firmware < 7.4, this is the drone location with with
            // reference to the WGS84 ellipsoid; on ANAFI Ai with firmware >= 7.4,
            // this is the front camera location with reference to the WGS84
            // ellipsoid https://developer.parrot.com/docs/groundsdk-tools/photo-metadata.html
            
            print("getAltitudeParrort: anafiai model")
            if alt == 0.0 { return superAlt }
            return alt
        }
        
        // otherwise, convert egm96 to wgs84
        let offset = try EGM96Geoid.getOffset(lat: getLatitude(), lng: getLongitude())
        print("getAltitudeParrot: alt \(alt) offset \(offset)")
        alt = alt - offset
        
        print("getAltitudeParrot: alt \(alt) superAlt \(superAlt)")
        
        if superAlt != alt { return superAlt }
        return alt
    }
    
}