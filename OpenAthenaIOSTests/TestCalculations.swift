//
//  TestCalculations.swift
//  OpenAthenaIOSTests
//
//  Created by Bobby Krupczak on 5/19/23.
//

import XCTest
@testable import OpenAthenaIOS

final class TestCalculations: XCTestCase {

    var droneImage: DroneImage!
    var dem: DigitalElevationModel!
    
    // load cobb.tiff DEM and DJI_0419.JPG image for use
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        print("TestCalculations starting")
        
        var imagePath = Bundle.main.path(forResource: "examples/DJI_0419", ofType: "JPG")
        XCTAssert(imagePath != nil)
        var data = try Data(contentsOf: URL(fileURLWithPath: imagePath!))
        var image = UIImage(data: data)
        droneImage = DroneImage()
        droneImage.rawData = data
        droneImage.updateMetaData()
        droneImage.theImage = image
        droneImage.targetXprop = 0.5
        droneImage.targetYprop = 0.5
        
        imagePath = Bundle.main.path(forResource: "examples/cobb", ofType: "tiff")
        XCTAssert(imagePath != nil)
        dem = DigitalElevationModel(fromURL: URL(fileURLWithPath: imagePath!))
        XCTAssert(dem != nil)
        
    } // setUpWithError

    // call resolveTarget with cobb.tiff and DJI_0419.JPG and
    // check results
    func testResolveTarget5050() throws
    {
        var target: [Double] = [0,0,0,0,0]
        
        XCTAssert(dem != nil)
        XCTAssert(droneImage != nil)
        
        droneImage.targetXprop = 0.50
        droneImage.targetYprop = 0.50
        try target = droneImage.resolveTarget(dem: dem)
        
        print("testResolveTarget: \(target)")
        
        // now that we are using drone ccd info and IDW, test numbers
        // have changed just slightly for alpha 1.1 and newer
        
        // altitude
        // XCTAssertEqual(target[3], 276.5093247021014)
        XCTAssertEqual(target[3],275.92153944980896)

        // distance to target
        // XCTAssertEqual(target[0],239.16353221862235)
        XCTAssertEqual(target[0],240.1642236791355)

        // target lat, lon
        // XCTAssertEqual(target[1],33.835465932500185)
        // XCTAssertEqual(target[2],-84.53849326691132)
        XCTAssertEqual(target[1],33.83545872167802)
        XCTAssertEqual(target[2],-84.53849210861283)
        
    } // testResolveTarget

    func testResolveTarget2525() throws
    {
        var target: [Double] = [0,0,0,0,0]
        
        XCTAssert(dem != nil)
        XCTAssert(droneImage != nil)
        
        droneImage.targetXprop = 0.25
        droneImage.targetYprop = 0.25
        try target = droneImage.resolveTarget(dem: dem)
        
        print("testResolveTarget: \(target)")
        
        // now that we are using drone ccd info and IDW, test numbers
        // have changed just slightly for alpha 1.1 and newer
        
        // altitude
        XCTAssertEqual(target[3],294.22483449139065)

        // distance to target
        XCTAssertEqual(target[0],354.32509079433487)
                       
        // target lat, lon
        XCTAssertEqual(target[1],33.83455699334952)
        XCTAssertEqual(target[2],-84.53707401236993)
        
    } // testResolveTarget
} // TestCalculations
