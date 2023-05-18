//
//  MGRSGeodetic.swift
//  OpenAthenaIOS
//
//  Created by Bobby Krupczak on 4/19/23.
//  Make use of mgrs-ios library provided by the NGA
//  https://github.com/ngaeoint
//  https://github.com/ngageoint/mgrs-ios
//  Cocoa pod ios-mgrs et al

import Foundation
import mgrs_ios
import grid_ios

public class MGRSGeodetic {
    
    // convert lat/lon to MGRS 1m, 10m, 100m
    
    static func WGS84_MGRS1m(Lat: Double, Lon: Double, Alt: Double) -> String {
        return convertToMGRS(Lat:Lat, Lon: Lon,G: GridType.METER)
    }
    
    static func WGS84_MGRS10m(Lat: Double, Lon: Double, Alt: Double) -> String {
        return convertToMGRS(Lat:Lat, Lon: Lon,G: GridType.TEN_METER)
    }
    
    static func WGS84_MGRS100m(Lat: Double, Lon: Double, Alt: Double) -> String {
        return convertToMGRS(Lat:Lat, Lon: Lon,G: GridType.HUNDRED_METER)
    }
    
    
    static func convertToMGRS(Lat: Double, Lon: Double, G: GridType) -> String {
        var p = GridPoint(Lon,Lat)
        var m = MGRS.from(p)

        return m.coordinate(G)
    }
    
} // MGRSGeodetic class
