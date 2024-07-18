// DroneImageParrot.swift
// OpenAthenaIOS
// Created by Bobby Krupczak on 1/5/24.
// Copyright 2024, Theta Informatics LLC
// AGPLv3
// https://www.gnu.org/licenses/agpl-3.0.txt

// Subclass DroneImage with Parrot specific code, data, methods

import Foundation
import UIKit

public class DroneImageParrot: DroneImage
{
    // get parrot software version
    // return 0.0 if unknown
    
    public func getVersion() -> String
    {
        var version: String = "0.0"
        
        //drone-parrot:SoftwareVersion
        if metaData!["drone-parrot:SoftwareVersion"] != nil {
            version = metaData!["drone-parrot:SoftwareVersion"] as! String
        }
        
        print("getVersionParrot: \(version)")
        
        var ret = compareVersions("1.8.0",version)
        
        print("getVersionParrot 1.8.0 <=> \(version) is \(ret)")
        
        ret = compareVersions("1.9","1.9.0")
        print("getVersionParrot 1.9 <=> 1.9.0 is \(ret)")
        
        return version
    }
    
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
            throw DroneImageError.MissingAltitude
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
    
    override public func getRelativeAltitude() throws -> Double {
        throw DroneImageError.ParameterNotImplemented
    }
    override public func getAltitudeViaRelative(dem: DigitalElevationModel) throws -> Double {
        throw DroneImageError.ParameterNotImplemented
    }
    
    override public func getAltitudeAboveGround() throws -> Double
    {
        var relativeAlt: Double = 0.0
        
        if metaData == nil {
            print("getAltitudeAboveGroundParrot: no meta data")
            throw DroneImageError.NoMetaData
        }
        
        if xmpDataRead == false {
            parseXmpMetaDataNoError()
        }
        
        if metaData!["Camera:AboveGroundAltitude"] != nil {
            let aStr = metaData!["Camera:AboveGroundAltitude"] as! NSString
            // some values have a division / instead of just plain value
            relativeAlt = try super.convertDivisionString(str: aStr)
            print("getAltitudeAboveGroundParrot: Camera AboveGroundAltitude is \(relativeAlt)")
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
        
        print("getAltitudeViaAboveGroundParrot: altAboveGround: \(altAboveGround), terrain: \(terrainAlt), alt: \(alt)")
        
        return alt
    }
    
    // Parrots use NED -- north, east, down -- just like always
    // no need to do anything special; code is here just in
    // case we want to tweak it.  4/26/2024
    
    override public func getGimbalYawDegree() throws -> Double
    {
        var superYawDegree: Double
        
        try superYawDegree = super.getGimbalYawDegree()
        
        print("getGimbalYawDegree parrot is \(superYawDegree)")
        
        return superYawDegree
    }
    
    // does this drone image have RTK flag set?
    override public func isRTK() -> ExtendedBoolean
    {
        return .ExtendedBooleanUnknown
    }
    
    // chatgpt derived code!
    // compare two version strings of format x.y.z
    
    func compareVersions(_ version1: String, _ version2: String) -> Int {
        let components1 = version1.components(separatedBy: ".")
        let components2 = version2.components(separatedBy: ".")
        
        // Ensure both versions have the same number of components
        let maxLength = max(components1.count, components2.count)
        let paddedComponents1 = components1 + Array(repeating: "0", count: maxLength - components1.count)
        let paddedComponents2 = components2 + Array(repeating: "0", count: maxLength - components2.count)
        
        // Compare each component numerically
        for (component1, component2) in zip(paddedComponents1, paddedComponents2) {
            if let num1 = Int(component1), let num2 = Int(component2) {
                if num1 < num2 {
                    return -1
                } else if num1 > num2 {
                    return 1
                }
            } else {
                // If components are not numeric, compare them lexicographically
                let comparisonResult = component1.compare(component2)
                if comparisonResult != .orderedSame {
                    return comparisonResult == .orderedAscending ? -1 : 1
                }
            }
        }
        
        // If all components are equal, versions are equal
        return 0
    }

} // DroneImageParrot
