// TestConversions.swift
// OpenAthenaIOSTests
//
// Created by Robert Krupczak on 10/4/24.
// Test various unit conversions
// and validate one
// Copyright 2024, Theta Informatics LLC
// AGPLv3
// https://www.gnu.org/licenses/agpl-3.0.txt

import XCTest
import UTMConversion

@testable import OpenAthena

final class TestConversions: XCTestCase 
{
    func testMGRSConversion()
    {
        let wgs84lat = 41.303337
        let wgs84lon = -96.342215
        let expectedMGRS = "14TQL2250675838"

        let mgrs = MGRSGeodetic.WGS84_MGRS1m(Lat: wgs84lat, Lon: wgs84lon, Alt: 0.0)

        print("testMGRSConversion: \(mgrs)")
        XCTAssertEqual(mgrs, expectedMGRS)

        // Convert back to lat,lon XXX
       
    }

    func testCK42Conversion() {
        let wgs84lat = 41.303337
        let wgs84lon = -96.342215
        let wgs84alt = 378.0
        let ck42Lat = 41.304679
        let ck42Lon = -96.342686
        let ck42alt = 219.0

        let (lat,lon,alt) = CK42Geodetic.WGS84_CK42(Bd: wgs84lat, Ld: wgs84lon, H: wgs84alt)

        XCTAssertEqual(lat, ck42Lat, accuracy: 0.0001)
        XCTAssertEqual(lon, ck42Lon, accuracy: 0.0001)
    }

    func testCK42GKConversion() {
        let wgs84lat = 41.303337
        let wgs84lon = -96.342215
        let wgs84alt = 378.0
        let ckLat = 41.304679
        let ckLon = -96.342686
        let ckGkLat = 4577898.643701867
        let ckGkLon = 4.472255510485153E7
        
        let (lat,lon) = CK42GaussKruger.CK42_to_GaussKruger(CK42_LatDegrees: ckLat, CK42_LonDegrees: ckLon)
        
        print("testCK42GKConversion: \(lat) \(lon)")
        
    }

    // utm supported by underlying swift/ios libraries so no need to test?
    func testUTMConversion()
    {
    }

    func testUSNG()
    {
        let wgs84lat = 33.83655034474734
        let wgs84lon = -84.52260287037062
        let expectedUSNG = "16S GC 29240 46790"
        
        // the NGA MGRS functions add a trailing 0 to 2924 and 4679 XXX

        let usng = MGRSGeodetic.convertToUSNG(Lat: wgs84lat, Lon: wgs84lon)
        print("testUSNG: usng is \(usng)")
        
        XCTAssertEqual(usng, expectedUSNG)
    }

    func testWgs84Dms()
    {
        let wgs84lat = 33.83655034474734
        let wgs84lon = -84.52260287037062
        let expectedDMS = "33°50'11.6\" N, 84°31'21.4\" W"

        let dms = WGS84Geodetic.toLatLonDMS(latitude: wgs84lat, longitude: wgs84lon)
        XCTAssertEqual(dms, expectedDMS)
    }
    
    func testVersionStrings()
    {
        var ret: Int
        
        print("testVersionStringComparisons")
        
        ret = DroneImage.compareVersionStrings("1.8.0", "1.10.2")
        XCTAssertEqual(-1,ret)
        print("1.8.0 " + (ret < 0 ? "<": (ret > 0 ? ">" : "=")) + " 1.10.2")
        
        ret = DroneImage.compareVersionStrings("2.1.0", "2.1")
        XCTAssertEqual(0,ret)
        print("2.1.0 " + (ret < 0 ? "<" : (ret > 0 ? ">" : "=")) + " 2.1")
        
        ret = DroneImage.compareVersionStrings("3.0.5", "3.0.1")
        XCTAssertEqual(1,ret)
        print("3.0.5 " + (ret < 0 ? "<" : (ret > 0 ? ">" : "=")) + " 3.0.1")
        
        ret = DroneImage.compareVersionStrings("1.2.1", "1.20")
        XCTAssertEqual(-1,ret)
        print("1.2.1 " + (ret < 0 ? "<" : (ret > 0 ? ">" : "=")) + " 1.20")
    }
    
}
