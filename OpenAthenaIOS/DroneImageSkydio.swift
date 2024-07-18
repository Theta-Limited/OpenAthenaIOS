// DroneImageSkydio.swift
// OpenAthenaIOS
// Created by Bobby Krupczak on 1/5/24.
// Copyright 2024, Theta Informatics LLC
// AGPLv3
// https://www.gnu.org/licenses/agpl-3.0.txt

// Subclass DroneImage with Skydio specific code, data, methods

import Foundation
import UIKit

public class DroneImageSkydio: DroneImage
{
    // get altitude in meters
    // use GPS data from digested metadata
    // return altitude in WGS84
    
    override public func getAltitude() throws -> Double
    {
        var alt = 0.0
        
        print("getAltitudeSkydio started")
        var superAlt = try super.getAltitude()
        
        if metaData == nil {
            print("getAltitudeSkydio: no metadata")
            throw DroneImageError.NoMetaData
        }
        if xmpDataRead == false {
            parseXmpMetaDataNoError()
        }
        if metaData!["drone-skydio:AbsoluteAltitude"] != nil {
            alt = (metaData!["drone-skydio:AbsoluteAltitude"] as! NSString).doubleValue
            print("getAltitudeSkydio: drone-skydio:AbsoluteAltitude is \(alt)")
        }
        
        print("getAltitudeSkydio: \(alt), now going to make corrections")
        
        // Skydio is EGM96
        var offset: Double = 0.0
        offset = try EGM96Geoid.getOffset(lat: getLatitude(), lng: getLongitude())
        print("getAltitudeSkydio: \(alt) offset: \(offset)")
        alt = alt - offset
        
        print("getAltitudeSkydio: alt: \(alt), superAlt: \(superAlt)")
        
        if alt == 0.0 { return superAlt }
        return alt
    }
    
    // does this drone image have RTK flag set?
    override public func isRTK() -> ExtendedBoolean
    {
        return .ExtendedBooleanUnknown
    }
    
    override public func getRelativeAltitude() throws -> Double
    {
        throw DroneImageError.ParameterNotImplemented
    }
    override public func getAltitudeViaRelative(dem: DigitalElevationModel) throws -> Double
    {
        throw DroneImageError.ParameterNotImplemented
    }
    override public func getAltitudeAboveGround() throws -> Double {
        throw DroneImageError.ParameterNotImplemented
    }
    override public func getAltitudeViaAboveGround(dem: DigitalElevationModel) throws -> Double {
        throw DroneImageError.ParameterNotImplemented
    }
    
} // DroneImageSkydio
