// WGS84Geodetic.swift
// OpenAthenaIOS
// Created by Robert Krupczak on 10/4/24.
// Copyright 2024, Theta Informatics LLC
// AGPLv3
// https://www.gnu.org/licenses/agpl-3.0.txt

// functions to convert between WGS84 and WGS84 DMS

import Foundation

public class WGS84Geodetic
{
    static func toLatLonDMS(latitude: Double, longitude: Double) -> String 
    {
        // Determine the hemisphere for latitude
        let latDirection = latitude >= 0 ? "N" : "S"
        // Determine the hemisphere for longitude
        let lonDirection = longitude >= 0 ? "E" : "W"
        
        // Convert latitude to absolute value for calculation
        var absLat = abs(latitude)
        // Extract degrees
        var latDegrees = Int(absLat)
        // Calculate the total minutes
        var latMinutesTotal = (absLat - Double(latDegrees)) * 60
        // Extract minutes
        var latMinutes = Int(latMinutesTotal)
        // Calculate seconds
        var latSeconds = (latMinutesTotal - Double(latMinutes)) * 60
        // Round seconds to one decimal place
        latSeconds = round(latSeconds * 10) / 10.0
        
        // Handle rounding that causes seconds to be 60.0
        if latSeconds >= 60.0 {
            latSeconds = 0.0
            latMinutes += 1
            if latMinutes >= 60 {
                latMinutes = 0
                latDegrees += 1
            }
        }
        
        // Convert longitude to absolute value for calculation
        let absLon = abs(longitude)
        // Extract degrees
        var lonDegrees = Int(absLon)
        // Calculate the total minutes
        let lonMinutesTotal = (absLon - Double(lonDegrees)) * 60
        // Extract minutes
        var lonMinutes = Int(lonMinutesTotal)
        // Calculate seconds
        var lonSeconds = (lonMinutesTotal - Double(lonMinutes)) * 60
        // Round seconds to one decimal place
        lonSeconds = round(lonSeconds * 10) / 10.0
        
        // Handle rounding that causes seconds to be 60.0
        if lonSeconds >= 60.0 {
            lonSeconds = 0.0
            lonMinutes += 1
            if lonMinutes >= 60 {
                lonMinutes = 0
                lonDegrees += 1
            }
        }
        
        // Format the DMS string
        return String(format: "%d°%d'%.1f\" %@, %d°%d'%.1f\" %@",
                      latDegrees, latMinutes, latSeconds, latDirection,
                      lonDegrees, lonMinutes, lonSeconds, lonDirection)
    } // toLatLonDMS

    
    
} // WGS84Geodetic
