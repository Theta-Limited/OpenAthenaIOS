// DroneImageDJI.swift
// OpenAthenaIOS
// Created by Bobby Krupczak on 1/5/24.
// Copyright 2024, Theta Informatics LLC
// AGPLv3
// https://www.gnu.org/licenses/agpl-3.0.txt

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
        
        //print("getAltitudeDJI: invoked")
        
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
            //print("getAltitudeDJI: drone-dji:AbsoluteAltitude \(alt)")
        }
        
        //print("getAltitudeDJI: alt is \(alt) now going to make corrections")
        
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
                // re issue #61 wgs84alt = egm96alt + offset
                alt = alt + offset
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
    
    // does this drone image have RTK flag set?
    //override public func isRTK() -> ExtendedBoolean
    //{
    //   return .ExtendedBooleanUnknown
    //}
    
    override public func getRelativeAltitude() throws -> Double
    {
        var relativeAlt: Double = 0.0
        
        if metaData == nil {
            print("getRelativeAltitudeDJI: no meta data")
            throw DroneImageError.NoMetaData
        }
        
        if xmpDataRead == false {
            parseXmpMetaDataNoError()
        }
        
        if metaData!["drone-dji:RelativeAltitude"] != nil {
            relativeAlt = (metaData!["drone-dji:RelativeAltitude"] as! NSString).doubleValue
            print("getRelativeAltDJI: drone relative alt is \(relativeAlt)")
            return relativeAlt
        }
        
        // throw error
        throw DroneImageError.MissingAltitude
    }
    
    // DJIs don't provide Camera:AltitudeAboveGround
    override public func getAltitudeAboveGround() throws -> Double {
        throw DroneImageError.ParameterNotImplemented
    }
    override public func getAltitudeViaAboveGround(dem: DigitalElevationModel) throws -> Double {
        throw DroneImageError.ParameterNotImplemented
    }
    
    override public func getAltitudeViaRelative(dem: DigitalElevationModel) throws -> Double
    {
        var lat,lon: Double
        
        let relativeAlt = try getRelativeAltitude()
        
        // find alt of lat/lon and
        try lat = getLatitude()
        try lon = getLongitude()
        let terrainAlt = try dem.getAltitudeFromLatLong(targetLat: lat, targetLong: lon)
        let alt = relativeAlt + terrainAlt
        
        print("getAltitudeViaRelativeDJI: relative: \(relativeAlt), terrain: \(terrainAlt), alt: \(alt)")
        
        // altitude is in WGS84
        return alt
    }
} // DroneImageDJI

