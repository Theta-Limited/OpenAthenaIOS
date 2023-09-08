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
    
    func testLookupDroneParams()
    {
        let ccdInfo = try? droneParams!.lookupDrone(makeModel: "djiFC3582")
        let ccdInfo1 = try? droneParams!.lookupDrone(make: "DJI", model: "FC3582")
        
        XCTAssert(ccdInfo != nil)
        XCTAssert(ccdInfo1 != nil)
        XCTAssert(ccdInfo!.widthPixels == 8064)
        XCTAssert(ccdInfo!.heightPixels == 6048)
        XCTAssert(ccdInfo!.ccdWidthMMPerPixel == 9.7/8064.0)
        XCTAssert(ccdInfo!.ccdHeightMMPerPixel == 7.3/6048.0)
        
        XCTAssert(ccdInfo1!.widthPixels == 8064)
        XCTAssert(ccdInfo1!.heightPixels == 6048)
        XCTAssert(ccdInfo1!.ccdWidthMMPerPixel == 9.7/8064.0)
        XCTAssert(ccdInfo1!.ccdHeightMMPerPixel == 7.3/6048.0)
        
        XCTAssert(ccdInfo1!.isThermal == false)
        XCTAssert(ccdInfo1!.radialR1 == 0.0)
        XCTAssert(ccdInfo1!.radialR2 == 0.0)
        XCTAssert(ccdInfo1!.lensType == "perspective")
        XCTAssert(ccdInfo1!.radialR3 == 0.0)
        XCTAssert(ccdInfo1!.c == 0)
        XCTAssert(ccdInfo1!.d == 0)
        XCTAssert(ccdInfo1!.e == 0)
        XCTAssert(ccdInfo1!.f == 0)
        XCTAssert(ccdInfo1!.tangentialT1 == 0.0)
        XCTAssert(ccdInfo1!.tangentialT2 == 0.0)

    }

} // TestDroneParams
