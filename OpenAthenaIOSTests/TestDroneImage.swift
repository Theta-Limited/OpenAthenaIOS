//
//  TestDroneImage.swift
//  OpenAthenaIOSTests
//
//  Created by Bobby Krupczak on 5/17/23.
//

import XCTest 
@testable import OpenAthenaIOS

final class TestDroneImage: XCTestCase {

    var droneImage: DroneImage!
    
    override func setUpWithError() throws {
        
        print("TestDroneImage: setup starting")
        
        try super.setUpWithError()
        let imagePath = Bundle.main.path(forResource: "examples/DJI_0419",
                                         ofType: "JPG")
        
        print("testLoadDrone: imagePath is \(imagePath!)")
                        
        XCTAssert(imagePath != nil)
        
        var data = try Data(contentsOf: URL(fileURLWithPath: imagePath!))
        var image = UIImage(data: data)
        droneImage = DroneImage()
        droneImage.rawData = data
        droneImage.updateMetaData()
    }
    
    // load DJI_0419.JPG drone image and verify
    // that its a drone image
    // should run this test for each of drone types
    // we support
    func testLoadDroneImage()
    {
        XCTAssertTrue(droneImage.isDroneImage())
    }
    
    func testDroneImageMetaData()
    {
        XCTAssert(droneImage != nil)
        
        // check lat, lon
        do {
            try XCTAssertEqual(droneImage.getLatitude(),33.8371893)
            try XCTAssertEqual(droneImage.getLongitude(),-84.5387701)
            try XCTAssertEqual(droneImage.getAltitude(),416.99)
            
            // check drone maker
            try XCTAssertTrue(droneImage.getCameraMake() == "DJI")
            
            // check theta
            try XCTAssertEqual(droneImage.getGimbalPitchDegree(),36.0)
            
            // check azimuth or yaw degree
            try XCTAssertEqual(droneImage.getGimbalYawDegree(),172.40)
            
            // check meta data from Xmp
            
        }
        catch {
            XCTAssert(false)
        }
        
        
    }
    
    
    
} // TestDroneImage
