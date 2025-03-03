// TestDroneParams.swift
// OpenAthenaIOSTests
//
// Created by Bobby Krupczak on 5/30/23.
// Test loading drone CCD params from json file
// and validate one entry
// Copyright 2024, Theta Informatics LLC
// AGPLv3
// https://www.gnu.org/licenses/agpl-3.0.txt

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
    
    // current for Aug 24, 2024 droneModels release
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
        
        // verify fix for issue #38
        var ccdInfo2 = try? droneParams!.getMatchingDrone(makeModel: "parrotAnafiUSA", targetWidth: 2304.0)
        XCTAssert(ccdInfo2!.isThermal == false)
        XCTAssert(ccdInfo2!.radialR1 == -0.249096)
        XCTAssert(ccdInfo2!.radialR2 == 0.0199733)
        XCTAssert(ccdInfo2!.radialR3 == 0.0116606)
        XCTAssert(ccdInfo2!.tangentialT1 == 0.0001663350)
        XCTAssert(ccdInfo2!.tangentialT2 == 0.000881907)
        
        ccdInfo2 = try? droneParams!.getMatchingDrone(makeModel: "DJIfc2204", targetWidth: 4000.0)
        XCTAssert(ccdInfo2!.isThermal == false)
        XCTAssert(ccdInfo2!.radialR1 == 0.0)
        XCTAssert(ccdInfo2!.radialR2 == 0.0)
        XCTAssert(ccdInfo2!.radialR3 == 0.0)
        XCTAssert(ccdInfo2!.tangentialT1 == 0.0)
        XCTAssert(ccdInfo2!.tangentialT2 == 0.0)
        
        ccdInfo2 = try? droneParams!.getMatchingDrone(makeModel: "autel roboticsxl709", targetWidth: 640.0)
        XCTAssert(ccdInfo2!.isThermal == true)
        XCTAssert(ccdInfo2!.radialR1 == 0.0)
        XCTAssert(ccdInfo2!.radialR2 == 0.0)
        XCTAssert(ccdInfo2!.radialR3 == 0.0)
        XCTAssert(ccdInfo2!.tangentialT1 == 0.0)
        XCTAssert(ccdInfo2!.tangentialT2 == 0.0)
        
        ccdInfo2 = try? droneParams!.getMatchingDrone(makeModel: "parrotBEBOP 2", targetWidth: 4000)
        XCTAssert(ccdInfo2!.isThermal == false)
        XCTAssert(ccdInfo2!.lensType == "fisheye")
        XCTAssert(ccdInfo2!.c == 2203.93)
        XCTAssert(ccdInfo2!.d == 0.0)
        XCTAssert(ccdInfo2!.e == 0.0)
        XCTAssert(ccdInfo2!.f == 2203.93)

        ccdInfo2 = try? droneParams!.getMatchingDrone(makeModel: "parrotANAFITHERMAL", targetWidth: 320.0)
        XCTAssert(ccdInfo2!.isThermal == true)
        XCTAssert(ccdInfo2!.radialR1 == 0.0)
        XCTAssert(ccdInfo2!.radialR2 == 0.0) 
        XCTAssert(ccdInfo2!.radialR3 == 0.0)
        XCTAssert(ccdInfo2!.tangentialT1 == 0.0)
        XCTAssert(ccdInfo2!.tangentialT2 == 0.0)
        
        // re issue #41, find a skydiox2d thermal and check if focalLength has been parsed
        ccdInfo2 = try? droneParams!.getMatchingDrone(makeModel: "skydiox2d", targetWidth: 320.0)
        XCTAssert(ccdInfo2!.isThermal == true)
        XCTAssert(ccdInfo2!.focalLength == 9.1)
        XCTAssert(ccdInfo2!.radialR1 == 0.0)
        XCTAssert(ccdInfo2!.radialR2 == 0.0)
        XCTAssert(ccdInfo2!.radialR3 == 0.0)
        XCTAssert(ccdInfo2!.tangentialT1 == 0.0)
        XCTAssert(ccdInfo2!.tangentialT2 == 0.0)
        
        ccdInfo2 = try? droneParams!.getMatchingDrone(makeModel: "teledyne flirhadron 640r eo", targetWidth: 4624)
        XCTAssert(ccdInfo2!.isThermal == false)
        XCTAssert(ccdInfo2!.lensType == "perspective")
        XCTAssert(ccdInfo2!.widthPixels == 9248)
        
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
        
        // re issue #66 test a few thermal entries and see if our workaround works
        drone = try? droneParams!.getMatchingDrone(makeModel: "skydioX2 NARROW", targetWidth: 512.0)
        XCTAssert(drone != nil)
        XCTAssertEqual(drone!.isThermal,true)
        XCTAssertEqual(drone!.widthPixels,320.0)
        
        drone = try? droneParams!.getMatchingDrone(makeModel: "Autel RoboticsXL715", targetWidth: 2048.0)
        XCTAssert(drone != nil)
        XCTAssertEqual(drone!.isThermal,false)
        XCTAssertEqual(drone!.widthPixels,8000.0)
        
    }
    

} // TestDroneParams
