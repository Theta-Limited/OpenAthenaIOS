//
//  AthenaSettings.swift
//  OpenAthenaIOS
//  https://github.com/Theta-Limited/OpenAthenaIOS
//  https://openathena.com//
//  Created by Bobby Krupczak on 1/30/23.

import Foundation
import UIKit

public class AthenaSettings {
    
    enum DEMLookupModes: Int, CaseIterable {
        case DEMStatic = 0   // use static tiff file that is downloaded
        case DEMOnline = 1   // use online lookup assuming mobile data
        
        var description: String {
            switch self {
            case .DEMStatic: return "Static TIFF"
            case .DEMOnline: return "Online lookup"
            }
        }
    } // DEM lookup modes
    
    enum OutputModes: Int, CaseIterable {
        case WGS84 = 0               // standard lat, long format
        case MGRS1m = 1              // NATO Military grid ref 1m square
        case MGRS10m = 2             // NATO Military grid ref 10m square
        case MGRS100m = 3            // NATO Military grid ref 100m square
        
        // Alternate geodisc system using Krasovsky 1940 ellipsoid.  Commonly used
        // in former Warsaw pact countries
        case CK42Geodetic = 4
        
        // Alternate geodisc system using Krasovsky 1940 ellipsoid.
        // A longitudinal ZONE in 6-degree increments, possible values 1-60 inclusive, northing
        // defined by X value, and East defined by Y value describe exact position on Earth
        case CK42GaussKruger = 5
        
        var description: String {
            switch self {
            case .WGS84: return "WGS84"
            case .MGRS1m: return "MGRS1m"
            case .MGRS10m: return "MGRS10m"
            case .MGRS100m: return "MGRS100m"
            case .CK42Geodetic: return "CK42Geodetic"
            case .CK42GaussKruger: return "CK42GaussKruger"
            }
        }
    } // enum outputmodes
    
    // initial/default defaults
    static let OutputMode: OutputModes = .WGS84
    static let LookupMode: DEMLookupModes = .DEMStatic
    
    // saved defaults
    var outputMode = OutputMode
    var lookupMode = LookupMode
    
    public func loadDefaults()
    {
        let defaults = UserDefaults.standard
        
        if let outputModeRaw = defaults.object(forKey: "outputMode") as? Int {
            outputMode = OutputModes(rawValue: outputModeRaw)!
        }
        if let lookupModeRaw = defaults.object(forKey: "lookupMode") as? Int {
            lookupMode = DEMLookupModes(rawValue: lookupModeRaw)!
        }
        
    }
    
    public func writeDefaults()
    {
        let defaults = UserDefaults.standard
        defaults.set(outputMode.rawValue, forKey: "outputMode")
        defaults.set(lookupMode.rawValue, forKey: "lookupMode")
        
    }
}
