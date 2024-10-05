// TestDigitalElevationModel.swift
// OpenAthenaIOSTests
//
// Created by Bobby Krupczak on 5/18/23.
//
// Copyright 2024, Theta Informatics LLC
// AGPLv3
// https://www.gnu.org/licenses/agpl-3.0.txt

import XCTest
@testable import OpenAthena

final class TestDigitalElevationModel: XCTestCase {

    // load the cobb.tiff and check it
    // against known parameters
    var dem: DigitalElevationModel!
    var mslDem: DigitalElevationModel!
    
    override func setUpWithError() throws {
        
        print("TestDigitalElevationModule: setup starting")
        
        try super.setUpWithError()
        
        var imagePath = Bundle.main.path(forResource: "examples/cobb",
                                         ofType: "tiff")
        XCTAssert(imagePath != nil)
            
        dem = DigitalElevationModel(fromURL: URL(fileURLWithPath: imagePath!))
    
        XCTAssert(dem != nil)
        
        mslDem = SeaLevelDEMEmulator()
        XCTAssert(mslDem != nil)
    }
    
    func testLoadDEM()
    {
        XCTAssert(dem != nil)
        XCTAssertEqual(dem.directory.numEntries(),19)
        XCTAssertEqual(dem.xParams.start,-84.7348611110986)
        XCTAssertEqual(dem.xParams.end,-84.34236111109854)
        XCTAssertEqual(dem.yParams.start,34.0801388888853)
        XCTAssertEqual(dem.yParams.end,33.74986111110748)
    }
    
    func testDEMParams()
    {
        XCTAssert(dem != nil)

    }
    
    func testMaritimeDEM()
    {
        var alt: Double
        
        do {
            try alt = mslDem.getAltitudeFromLatLong(targetLat: 0.0, targetLong: 0.0)
            XCTAssertEqual(-17.16,alt)
            
            try alt = mslDem.getAltitudeFromLatLong(targetLat: -10.0, targetLong: -10.0)
            XCTAssertEqual(-12.66,alt)
            
            try alt = mslDem.getAltitudeFromLatLong(targetLat: 20.0, targetLong: -50.0)
            XCTAssertEqual(32.98,alt)
            
            try alt = mslDem.getAltitudeFromLatLong(targetLat: 20.0,targetLong: -150.0)
            XCTAssertEqual(6.97,alt)
        }
        catch {
            XCTFail("testMaritimeDEM failed")
        }
    }
    
}
