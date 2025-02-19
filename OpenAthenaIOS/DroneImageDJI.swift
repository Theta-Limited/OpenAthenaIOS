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
    // re issue #65 fix for newer DJIs reporting in WGS84
    
    override public func getAltitude() throws -> Double
    {
        var alt = 0.0
        let superAlt = try super.getAltitude()
        
        if metaData == nil {
            print("getAltitudeDJI: no metadata, returning")
            throw DroneImageError.NoMetaData
        }
        
        if xmpDataRead == false {
            parseXmpMetaDataNoError()
        }
        
        var djiVersion = getDjiVersion();
        var offset = try EGM96Geoid.getOffset(lat: getLatitude(), lng: getLongitude())
        var rtkFlag:ExtendedBoolean = isRTK()
        var status = getGpsStatus()
        var altitudeRef = getAltitudeReference()
        
        print("getAltitudeDJI: version: \(djiVersion) offset: \(offset) rtk: \(rtkFlag) altRef: \(altitudeRef) status: \(status)")
        
        alt = superAlt
        
        if metaData!["drone-dji:AbsoluteAltitude"] != nil {
            alt = (metaData!["drone-dji:AbsoluteAltitude"] as! NSString).doubleValue
            
            print("getAltitudeDJI: AbsoluteAltitude is \(alt)")

            if DroneImage.compareVersionStrings(djiVersion,"1.5") == -1 && rtkFlag == .ExtendedBooleanFalse {
                alt = alt + offset // convert EGM96 to WGS84
            }
        }
        
        print("getAltitudeDJI: returning \(alt)")

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
    
    // return the vertical datum used by this drone
    // which lets us know what the altitude in meta data is
    // some DJIs report altitude in WGS84 while others
    // report in EGM96/Ortho/AMSL
    
    override public func getVerticalDatum() -> DroneVerticalDatumType
    {
        let djiVersion = getDjiVersion()
        let rtkFlag = isRTK()
        
        if DroneImage.compareVersionStrings(djiVersion,"1.5") == -1 && rtkFlag == .ExtendedBooleanFalse {
            // if older rev and not RTK, its orthometric altitude e.g. egm96
            return DroneVerticalDatumType.ORTHOMETRIC
        }
        return DroneVerticalDatumType.WGS84 
    }
    
    // find Xmp.drone-dji.Version and return it if found; 0 otherwise
    // return as string so that 1.10 > 1.6 > 1.5 > 1.2 > 0
    
    public func getDjiVersion() -> String
    {
        var version = "0.0";
        
        if metaData!["drone-dji:Version"] != nil {
            version = metaData!["drone-dji:Version"] as! String
        }
        
        print("getDjiVersion: \(version)")
        
        // run a few tests
//        var ret = DroneImage.compareVersionStrings(version,"2.0")
//        print("compareVersions \(version) 2.0 -> \(ret)")
//        
//        ret = DroneImage.compareVersionStrings("2.0",version)
//        print("compareVersions 2.0 \(version) -> \(ret)")
//        
//        ret = DroneImage.compareVersionStrings("1.9","1.9.0")
//        print("compareVersions 1.9 1.9.0 -> \(ret)")
//        
//        ret = DroneImage.compareVersionStrings("1.9","1.9.1")
//        print("compareVersions 1.9 1.9.1 -> \(ret)")
        
        return version;
    }
    
    // look for drone-dji:GpsStatus
    // return "unknown" or value if present
    // https://dl.djicdn.com/downloads/DJI_Mavic_3_Enterprise/20230829/Mavic_3M_Image_Processing_Guide_EN.pdf
    // rtk, invalid, normal
    // our mini3pro says invalid but it is giving appropriate WGS84 altitudes though
    // therefore, don't think we can rely on this value
    
    public func getGpsStatus() -> String
    {
        var status = "unknown";
        
        if metaData!["drone-dji:GpsStatus"] != nil {
            status = metaData!["drone-dji:GpsStatus"] as! String;
        }

        return status;
    }
    
    
} // DroneImageDJI

