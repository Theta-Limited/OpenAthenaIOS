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
        let expectedUSNG = "16SGC29244679"

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
    
}
