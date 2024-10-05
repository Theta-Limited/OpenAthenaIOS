// SeaLevelDEMEmulator.swift
// OpenAthenaIOS
// Created by Robert Krupczak on 10/4/24.
// Copyright 2024, Theta Informatics LLC
// https://openagthena.com
// AGPLv3
// https://www.gnu.org/licenses/agpl-3.0.txt

// Mean Sea Level DEM emulator
// support MSL and DEM info over water when
// no real DEM data exists
// re issue #56

import Foundation
import UIKit

public class SeaLevelDEMEmulator: DigitalElevationModel 
{
    override init()
    {
        super.init()
        
        xParams = GeoDataAxisParams()
        xParams.start = -180.0
        xParams.stepwiseIncrement = 1.0
        xParams.numberOfSteps = 360
        xParams.end = 180.0
        
        yParams = GeoDataAxisParams()
        yParams.start = 90
        yParams.stepwiseIncrement = -1.0
        yParams.numberOfSteps = 180
        yParams.end = -90
        
    }
    
    override public func getAltitudeFromLatLong(targetLat lat: Double, targetLong lon: Double) throws -> Double
    {
        // instead of using any DEM, this provider just returns average MSL height
        // converts to WGS84 height above ellipsoide (HAE)
        
        let offset = EGM96Geoid.getOffset(lat: lat, lng: lon)
        let alt = 0.0 - offset
        
        return alt
    }
    
} // SeaLevelDEMEmulator
