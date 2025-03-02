// DroneImageAutel.swift
// OpenAthenaIOS
// Created by Bobby Krupczak on 1/5/24.
// Copyright 2024, Theta Informatics LLC
// AGPLv3
// https://www.gnu.org/licenses/agpl-3.0.txt

// Subclass DroneImage with Autel specific code, data, methods

import Foundation
import UIKit

public class DroneImageAutel: DroneImage
{
    // get altitude in meters
    // Use GPS data from digested metadata
    // For older autel drones, check if GPSAltitudeRef exists and is 1
    // if so, its below seal level and we should negate the value
    // return altitude in WGS84
    // ref about="Autel Robotics Meta Data" -> old metadata format
    // old metadata format is WGS84
    // if it does not have AbsoluteAltitude then old metadata
    // looks like both old and new is WGS84
    // re issue #65 fix altitude
    
    override public func getAltitude() throws -> Double
    {
        print("getAltitudeAutel started")
        let superAlt = try super.getAltitude()
        var alt = 0.0
        var gpsInfo: NSDictionary
        
        if metaData == nil {
            print("getAltitudeAutel: no metadata")
            throw DroneImageError.NoMetaData
        }
        
        if xmpDataRead == false {
            parseXmpMetaDataNoError()
        }
        
        print("getAltitudeAutel: meta data format is \(getMetaDataFormat())")
        
        // DJI metadata; its in WGS84; return it
        if metaData!["drone:AbsoluteAltitude"] != nil {
            alt = (metaData!["drone:AbsoluteAltitude"] as! NSString).doubleValue
            print("getAltitudeAutel: drone:AbsoluteAltitude \(alt)")
            return alt;
        }
        
        // what about Camera:AboveGroundAltitude value? XXX
        // Autel also has exif:GPSAltitude and exif:GPSAltitudeRef
                
        // if we're here, thus old metadat format and its WGS84 too
        // get GPS altitude

        if metaData!["{GPS}"] == nil {
            print("getAltitudeAutel: no gps meta data, bugging out")
            throw DroneImageError.NoMetaGPSData
        }
        gpsInfo = metaData!["{GPS}"] as! NSDictionary
        if gpsInfo["Altitude"] == nil {
            print("getAltitudeAutel: no altitude within GPS data, bugging out")
            throw DroneImageError.MissingAltitude
        }
        alt = gpsInfo["Altitude"] as! Double
                
        // re autel drones, check altitude ref for 1 meaning below sea level XXX
        if gpsInfo["GPSAltitudeRef"] != nil {
            let ref = gpsInfo["GPSAltitudeRef"] as! Int
            print("getAltitudeAutel: GPSAltitude ref is \(ref)")
            if ref == 1 {
                alt = -1.0 * alt
            }
        }
        if gpsInfo["AltitudeRef"] != nil {
            let ref = gpsInfo["AltitudeRef"] as! Int
            print("getAltitudeAutel: Altitude ref is \(ref)")
            if ref == 1 {
                alt = -1.0 * alt
            }
        }
        if metaData!["exif:GPSAltitudeRef"] != nil {
            let ref = (metaData!["exif:GPSAltitudeRef"] as! NSString).intValue
            print("getAltitudeAutel: GPS exif:GPSAltitudeRef is \(ref)")
            if ref == 1 {
                alt = -1.0 * alt
            }
        }
                
        print("getAltitudeAutel: exif/gps alt \(alt) superAlt: \(superAlt)")
        
        if alt == 0.0  { return superAlt }
        
        return alt
    }
    
    // relative altitude in meters either above takeoff point (DJI)
    override public func getRelativeAltitude() throws -> Double
    {
        throw DroneImageError.ParameterNotImplemented
    }
    override public func getAltitudeViaRelative(dem: DigitalElevationModel) throws -> Double
    {
        throw DroneImageError.ParameterNotImplemented
    }
    
    // does this drone image have RTK flag set?
    override public func isRTK() -> ExtendedBoolean
    {
        return .ExtendedBooleanUnknown
    }
    
    
    //  altitude above ground allegedly below drone
    override public func getAltitudeAboveGround() throws -> Double
    {
        var relativeAlt: Double = 0.0
        
        if metaData == nil {
            print("getAltitudeAboveGroundAutel: no meta data")
            throw DroneImageError.NoMetaData
        }
        
        if xmpDataRead == false {
            parseXmpMetaDataNoError()
        }
        
        if metaData!["Camera:AboveGroundAltitude"] != nil {
            let aStr = metaData!["Camera:AboveGroundAltitude"] as! NSString
            // some values have a division / instead of just plain value
            relativeAlt = try convertDivisionString(str: aStr)
            print("getAltitudeAboveGroundAutel: Camera AboveGroundAltitude is \(relativeAlt)")
            return relativeAlt
        }
        
        // throw error
        throw DroneImageError.MissingAltitude
    }
    
    override public func getAltitudeViaAboveGround(dem: DigitalElevationModel) throws -> Double
    {
        var lat,lon: Double
        
        let altAboveGround = try getAltitudeAboveGround()
        
        // find alt of lat/lon and
        try lat = getLatitude()
        try lon = getLongitude()
        let terrainAlt = try dem.getAltitudeFromLatLong(targetLat: lat, targetLong: lon)
        let alt = altAboveGround + terrainAlt
        
        print("getAltitudeViaAboveGroundAutel: aboveGround: \(altAboveGround), terrain: \(terrainAlt), alt: \(alt)")
        
        return alt
    }
    
    private func isAutelMetadata() -> Bool
    {
        if xmlStringCopy?.lowercased().contains("autel robotics meta data") == true {
            return true
        }
        return false
    }
    
    private func isDJIMetadata() -> Bool
    {
        if xmlStringCopy?.lowercased().contains("dji meta data") == true {
            return true
        }
        return false
    }
    
    private func getMetaDataFormat() -> String
    {
        if isAutelMetadata() {
            return "Autel Robotics Meta Data"
        }
        if isDJIMetadata() {
            return "DJI Meta Data"
        }
        
        return "Unknown meta data format"
    }
    
    // return the vertical datum used by this drone
    // which lets us know what the altitude in meta data is
    
    override public func getVerticalDatum() -> AthenaSettings.VerticalDatumType
    {
        return AthenaSettings.VerticalDatumType.WGS84
    }
    

} // DroneImageAutel
