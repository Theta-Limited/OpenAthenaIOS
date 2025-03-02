// DroneImageTeal.swift
// OpenAthenaIOS
// Created by Bobby Krupczak on 8/24/2024
// Copyright 2024, Theta Informatics LLC
// AGPLv3
// https://www.gnu.org/licenses/agpl-3.0.txt

// Subclass DroneImage with Teal specific code, data, methods

import Foundation
import UIKit

public class DroneImageTeal: DroneImage
{
    
    override public func isThermal() -> Bool
    {
        if ccdInfo != nil {
            if ccdInfo!.isThermal == true {
                return true;
            }
        }
        do {
            let modelStr: String = try getCameraModel()
            if modelStr.lowercased().contains("boson 640") == true {
                return true;
            }
        } catch {
            return false;
        }
        return false;
    }
    
    // <exif:CameraPitch>-86831/1600</exif:CameraPitch>
    // <exif:PlatformPitch>-785007/200000</exif:PlatformPitch>
    // pitch or theta
    
    override public func getGimbalPitchDegree() throws -> Double
    {
        var theta,p : Double
        var aStr: NSString
        
        if metaData == nil {
            throw DroneImageError.NoMetaData
        }
        if xmpDataRead == false {
            parseXmpMetaDataNoError()
        }
        theta = 0.0
        p = 0.0
        if metaData!["exif:CameraPitch"] != nil {
            aStr = metaData!["exif:CameraPitch"] as! NSString
            theta = try convertDivisionString(str: aStr)
            print("getGimbalPitchDegreeTeal \(theta)")
        }
        if metaData!["exif:PlatformPitch"] != nil {
            aStr = metaData!["exif:PlatformPitch"] as! NSString
            p = try convertDivisionString(str: aStr)
            print("getGimbalPitchDegreeTeal \(p)")
        }
        
        theta = theta + p
        theta = theta * -1.0
        
        return theta
    }
    
    // <exif:CameraYaw>359986359/1000000</exif:CameraYaw>
    // <exif:PlatformYaw>31901593/100000</exif:PlatformYaw>
    
    override public func getGimbalYawDegree() throws -> Double
    {
        var aStr: NSString
        var az, p: Double
        
        if metaData == nil {
            throw DroneImageError.NoMetaData
        }
        if xmpDataRead == false {
            parseXmpMetaDataNoError()
        }
        az = 0
        p = 0
        if metaData!["exif:CameraYaw"] != nil {
            aStr = metaData!["exif:CameraYaw"] as! NSString
            az = try convertDivisionString(str: aStr)
            print("getGimbalYawDegreeTeal \(az)")
        }
        if metaData!["exif:PlatformYaw"] != nil {
            aStr = metaData!["exif:PlatformYaw"] as! NSString
            p = try convertDivisionString(str: aStr)
            print("getGimbalPitchYawTeal \(p)")
        }
        
        az = az + p
        
        if settings != nil {
            az = az + Double(settings!.compassCorrection)
        }
        return az.truncatingRemainder(dividingBy: 360.0)
    }
    
    override public func getFocalLengthIn35mm() throws -> Double 
    {
        var fl: Double = try getFocalLength()
        var cropFactorOptical: Double = 43.3 / 7.857
        var cropFactorThermal = 43.3 / 4.92
        
        if metaData == nil {
            throw DroneImageError.NoMetaData
        }
        if xmpDataRead == false {
            parseXmpMetaDataNoError()
        }

        if (isThermal() == true) {
            fl = fl * cropFactorThermal
        }
        else {
            fl = fl * cropFactorOptical
        }
        
        return fl
    }
    
    // <exif:PlatformRoll>-1044397/1000000</exif:PlatformRoll>
    // <exif:CameraRoll>16501/1000000</exif:CameraRoll>

    override public func getRoll() throws -> Double
    {
        var roll, p: Double
        var aStr: NSString
        
        if metaData == nil {
            throw DroneImageError.NoMetaData
        }
        if xmpDataRead == false {
            parseXmpMetaDataNoError()
        }
        
        roll = 0.0
        p = 0.0
        
        if metaData!["exif:CameraRoll"] != nil {
            aStr = metaData!["exif:CameraRoll"] as! NSString
            roll = try convertDivisionString(str: aStr)
            print("getRollTeal \(roll)")
        }
        if metaData!["exif:PlatformRoll"] != nil {
            aStr = metaData!["exif:PlatformRoll"] as! NSString
            p = try convertDivisionString(str: aStr)
            print("getRollTeal \(p)")
        }
        
        roll = roll + p
        
        return roll
    }
    
    // get altitude in meters
    // use GPS data from digested metadata
    // return altitude in WGS84
    // <exif:GPSAltitude>330113739/250000</exif:GPSAltitude>
    
    override public func getAltitude() throws -> Double
    {
        var alt, offset: Double
        var aStr: NSString
        
        alt =  try super.getAltitude()
        
        if metaData == nil {
            throw DroneImageError.NoMetaData
        }
        if xmpDataRead == false {
            parseXmpMetaDataNoError()
        }
        
        if metaData!["exif:GPSAltitude"] != nil {
            aStr = metaData!["exif:GPSAltitude"] as! NSString
            alt = try convertDivisionString(str: aStr)
            print("getAltitudeTeal: \(alt)")
        }
        
        // convert from sea level to WGS84
        offset = try EGM96Geoid.getOffset(lat: getLatitude(), lng: getLongitude())
        print("getAltitudeTeal: \(alt) \(offset)")
        // re issue #61 wgs84alt = egm96alt + offset
        alt = alt + offset
        
        return alt
    }
    
    // return the vertical datum used by this drone
    // which lets us know what the altitude in meta data is
    
    override public func getVerticalDatum() -> AthenaSettings.VerticalDatumType
    {
        return AthenaSettings.VerticalDatumType.ORTHOMETRIC
    }
    
        
} // DroneImageTeal
