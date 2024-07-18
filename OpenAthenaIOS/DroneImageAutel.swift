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
    
} // DroneImageAutel
