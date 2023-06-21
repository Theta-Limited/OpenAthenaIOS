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
    
    enum VerticalDatumTypes: Int, CaseIterable {
        case WGS84 = 0
        case EGM96 = 1
        case NAVD88 = 2
        case UNKNOWN_OTHER = 3
        
        var description: String {
            switch self {
            case .WGS84: return "WGS84"    // HAE, GPS, or WGS84 ref ellipsoid
            case .EGM96: return "EGM96"    // MSL or orthometric
            case .NAVD88: return "NAVD88"
            case .UNKNOWN_OTHER: return "Unknown/other"
            }
        }
    }
    
    enum OutputModes: Int, CaseIterable {
        case WGS84 = 0               // standard lat, long format
        
        //case MGRS1m = 1              // NATO Military grid ref 1m square
        //case MGRS10m = 2             // NATO Military grid ref 10m square
        //case MGRS100m = 3            // NATO Military grid ref 100m square
        
        // Alternate geodisc system using Krasovsky 1940 ellipsoid.  Commonly used
        // in former Warsaw pact countries
        case CK42Geodetic = 1
        
        // Alternate geodisc system using Krasovsky 1940 ellipsoid.
        // A longitudinal ZONE in 6-degree increments, possible values 1-60 inclusive, northing
        // defined by X value, and East defined by Y value describe exact position on Earth
        case CK42GaussKruger = 2
        
        // UTM universal transverse mercator coordinate system
        case UTM = 3
        
        // all MGRS
        case MGRS = 4
        
        var description: String {
            switch self {
            case .WGS84: return "WGS84"
            //case .MGRS1m: return "MGRS1m"
            //case .MGRS10m: return "MGRS10"
            //case .MGRS100m: return "MGRS100m"
            case .CK42Geodetic: return "CK42Geodetic"
            case .CK42GaussKruger: return "CK42GaussKruger"
            case .UTM: return "UTM"
            case .MGRS: return "MGRS"
            }
        }
    } // enum outputmodes
    
    // initial/default defaults
    static let OutputMode: OutputModes = .WGS84
    static let LookupMode: DEMLookupModes = .DEMStatic
    static let UseCCDInfo: Bool = true
    static let FontSize: Int = 14
    
    // saved defaults first set to defaults before loading
    var outputMode = OutputMode
    var lookupMode = LookupMode
    var useCCDInfo = UseCCDInfo
    var fontSize = FontSize
    
    public func loadDefaults()
    {
        let defaults = UserDefaults.standard
        
        if var outputModeRaw = defaults.object(forKey: "outputMode") as? Int {
            print("loadSettings: read outputModeRaw \(outputModeRaw)")
            if outputModeRaw < 0 || outputModeRaw > 4 {
                outputModeRaw = 0
            }
            outputMode = OutputModes(rawValue: outputModeRaw)!
            print("loadSettings: outputMode to \(outputMode)")
            print("loadSettings: outputMode.rawValue \(outputMode.rawValue)")
        }
        if let lookupModeRaw = defaults.object(forKey: "lookupMode") as? Int {
            lookupMode = DEMLookupModes(rawValue: lookupModeRaw)!
        }
        if let useCCDInfoNew = defaults.object(forKey: "useCCDInfo") as? Bool {
            useCCDInfo = useCCDInfoNew
        }
        if let fontSizeNew = defaults.object(forKey: "fontSize") as? Int {
            if fontSizeNew > 0 && fontSizeNew < 48 {
                fontSize = fontSizeNew
            }
        }
        
        print("loadDefaults: returning, outputMode is \(outputMode), \(outputMode.rawValue)")
    }
    
    public func writeDefaults()
    {
        let defaults = UserDefaults.standard
        defaults.set(outputMode.rawValue, forKey: "outputMode")
        defaults.set(lookupMode.rawValue, forKey: "lookupMode")
        defaults.set(useCCDInfo, forKey: "useCCDInfo")
        defaults.set(fontSize, forKey: "fontSize")
        
        print("writeDefault: outputMode is \(outputMode) \(outputMode.rawValue)")
            
    }
    
} // AthenaSettings

