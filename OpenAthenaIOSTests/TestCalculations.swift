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
        
        imagePath = Bundle.main.path(forResource: "examples/cobb", ofType: "tiff")
        XCTAssert(imagePath != nil)
        dem = DigitalElevationModel(fromURL: URL(fileURLWithPath: imagePath!))
        XCTAssert(dem != nil)
        
    } // setUpWithError

    // call resolveTarget with cobb.tiff and DJI_0419.JPG and
    // check results
    func testResolveTarget() throws
    {
        var target: [Double] = [0,0,0,0,0]
        
        XCTAssert(dem != nil)
        XCTAssert(droneImage != nil)
        
        try target = droneImage.resolveTarget(dem: dem)
        
        print("testResolveTarget: \(target)")
        
        // altitude
        XCTAssertEqual(target[3], 276.5093247021014)
        // distance to target
        XCTAssertEqual(target[0],239.16353221862235)
        // target lat, lon
        XCTAssertEqual(target[1],33.835465932500185)
        XCTAssertEqual(target[2],-84.53849326691132)
        
    } // testResolveTarget

    

} // TestCalculations
