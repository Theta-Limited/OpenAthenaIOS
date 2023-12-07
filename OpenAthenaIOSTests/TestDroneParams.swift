//
//  TestDroneParams.swift
//  OpenAthenaIOSTests
//
//  Created by Bobby Krupczak on 5/30/23.
//  Test loading drone CCD params from json file
//  and validate one entry

import XCTest
@testable import OpenAthena

final class TestDroneParams: XCTestCase {

    var droneParams: DroneParams?
    
    override func setUpWithError() throws {
        
        print("TestDroneParams: setup starting")
        
        try super.setUpWithError()
        
        droneParams = DroneParams()
        
        print("Drone params json file dated \(droneParams!.droneParamsLastUpdate)")
    }

    func testDroneParamsLoad()
    {
        XCTAssert(droneParams != nil)
        XCTAssertTrue((droneParams!.numberDroneModels()) > 1)
    }
    
    // current for Nov 30 2023 droneModels release
    func testLookupDroneParams()
    {
        let ccdInfo = try? droneParams!.lookupDrone(makeModel: "djiFC3582")
        let ccdInfo1 = try? droneParams!.lookupDrone(make: "DJI", model: "FC3582")
        
        XCTAssert(ccdInfo != nil)
        XCTAssert(ccdInfo1 != nil)
        XCTAssert(ccdInfo!.widthPixels == 4032)
        XCTAssert(ccdInfo!.heightPixels == 3024)
        XCTAssert(ccdInfo!.ccdWidthMMPerPixel == 0.0023883764)
        XCTAssert(ccdInfo!.ccdHeightMMPerPixel == 0.002379536)
        
        XCTAssert(ccdInfo1!.widthPixels == 4032)
        XCTAssert(ccdInfo1!.heightPixels == 3024)
        XCTAssert(ccdInfo1!.ccdWidthMMPerPixel == 0.0023883764)
        XCTAssert(ccdInfo1!.ccdHeightMMPerPixel == 0.002379536)
        
        XCTAssert(ccdInfo1!.isThermal == false)
        XCTAssert(ccdInfo1!.radialR1 == 0.11416479395258083)
        XCTAssert(ccdInfo1!.radialR2 == -0.26230384345579)
        XCTAssert(ccdInfo1!.lensType == "perspective")
        XCTAssert(ccdInfo1!.radialR3 == 0.22906477778853437)
        XCTAssert(ccdInfo1!.c == 0)
        XCTAssert(ccdInfo1!.d == 0)
        XCTAssert(ccdInfo1!.e == 0)
        XCTAssert(ccdInfo1!.f == 0)
        XCTAssert(ccdInfo1!.tangentialT1 == -0.004601610146546272)
        XCTAssert(ccdInfo1!.tangentialT2 == 0.0026292475166887)
    }
    
    func testMatchingDroneParams()
    {
        let drones = try? droneParams!.getMatchingDrones(makeModel: "djiFC2403")
        XCTAssert(drones != nil)
        XCTAssert(drones!.first!.makeModel == "djiFC2403")
    }
    
    func testMatchingDroneByWidth()
    {
        var drone = try? droneParams!.getMatchingDrone(makeModel: "djiFC2403", targetWidth: 640)
        XCTAssert(drone != nil)
        XCTAssertEqual(drone!.widthPixels,640)
        drone = try? droneParams!.getMatchingDrone(makeModel: "djiFC2403", targetWidth: 4056)
        XCTAssert(drone != nil)
        XCTAssertEqual(drone!.widthPixels,4056)
    }

} // TestDroneParams
