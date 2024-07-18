// MGRSGeodetic.swift
// OpenAthenaIOS
// Created by Bobby Krupczak on 4/19/23.
// Make use of mgrs-ios library provided by the NGA
// https://github.com/ngaeoint
// https://github.com/ngageoint/mgrs-ios
// Cocoa pod ios-mgrs et al
// Copyright 2024, Theta Informatics LLC
// AGPLv3
// https://www.gnu.org/licenses/agpl-3.0.txt

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
        
        let str = m.coordinate(G)
        
        // don't split components here because spaces in string
        // will break Google Maps URL search
        return str
    }
    
    // given an MGRS coordinate in string format, split it into
    // subcomponents GZD, square identifier, easting, and northing
    // ChatGPT derived code to split apart an MGRS coordinate
    // issue #40
    
    // this function uses the built-in class components to split the string apart
    static func splitMGRS(mgrs: MGRS) -> String
    {
        return "\(mgrs.zone)\(mgrs.band) \(mgrs.column)\(mgrs.row) \(mgrs.easting) \(mgrs.northing)"
    }
    
    // this function takes a string, converts to MGRS object, then returns split string
    // assumes 1m output
    static func splitMGRS(mgrs: String) -> String
    {
        let m = MGRS.parse(mgrs)
        let aStr = splitMGRS(mgrs: m)
        
        print("splitMGRS: \(mgrs) -> \(aStr)")
        return aStr
    }
    
    static func splitMGRSRegex(mgrs: String) -> String
    {
        let pattern = #"^(\d{1,2}[C-Xc-x])([A-HJ-NP-Za-hj-np-z]{2})(\d+)$"#
            
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            print("slitMGRS: regex pattern is invalid")
            return mgrs
        }

        let range = NSRange(mgrs.startIndex..<mgrs.endIndex, in: mgrs)
            
        if let match = regex.firstMatch(in: mgrs, options: [], range: range) {
            let gzd = String(mgrs[Range(match.range(at: 1), in: mgrs)!])
            let squareId = String(mgrs[Range(match.range(at: 2), in: mgrs)!])
                
            // Remaining digits are split into easting and northing
            let digits = String(mgrs[Range(match.range(at: 3), in: mgrs)!])
            if digits.count % 2 != 0 {
                print("splitMGRS: odd number of digits for easting/northing")
                return mgrs
            }
            let midIndex = digits.index(digits.startIndex, offsetBy: digits.count / 2)
            let easting = String(digits[..<midIndex])
            let northing = String(digits[midIndex...])
            
            return "\(gzd) \(squareId) \(easting) \(northing)"
        } else {
            print("splitMGRS: the input string does not match the MGRS pattern")
            return mgrs
        }
    }
    
} // MGRSGeodetic class
