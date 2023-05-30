//
//  TestDroneImage.swift
//  OpenAthenaIOSTests
//
//  Created by Bobby Krupczak on 5/17/23.
//

import XCTest 
@testable import OpenAthenaIOS

final class TestDroneImage: XCTestCase {

    var djiImage: DroneImage!
    var parrotImage: DroneImage!
    var autellImage: DroneImage!
    var skydioImage: DroneImage!
    
    override func setUpWithError() throws {
        
        print("TestDroneImage: setup starting")
        
        try super.setUpWithError()
        
        var imagePath = Bundle.main.path(forResource: "examples/DJI_0419",
                                         ofType: "JPG")
        XCTAssert(imagePath != nil)
        var data = try Data(contentsOf: URL(fileURLWithPath: imagePath!))
        var image = UIImage(data: data)
        djiImage = DroneImage()
        djiImage.rawData = data
        djiImage.theImage = image
        djiImage.updateMetaData()
        
        imagePath = Bundle.main.path(forResource: "examples/parrot-1",
                                         ofType: "jpg")
        XCTAssert(imagePath != nil)
        data = try Data(contentsOf: URL(fileURLWithPath: imagePath!))
        image = UIImage(data: data)
        parrotImage = DroneImage()
        parrotImage.rawData = data
        parrotImage.theImage = image
        parrotImage.updateMetaData()
        
        imagePath = Bundle.main.path(forResource: "examples/skydio-catilina",
                                         ofType: "jpg")
        XCTAssert(imagePath != nil)
        data = try Data(contentsOf: URL(fileURLWithPath: imagePath!))
        image = UIImage(data: data)
        skydioImage = DroneImage()
        skydioImage.rawData = data
        skydioImage.theImage = image
        skydioImage.updateMetaData()

        imagePath = Bundle.main.path(forResource: "examples/waterloo-autell",
                                         ofType: "jpg")
        XCTAssert(imagePath != nil)
        data = try Data(contentsOf: URL(fileURLWithPath: imagePath!))
        image = UIImage(data: data)
        autellImage = DroneImage()
        autellImage.rawData = data
        autellImage.theImage = image
        autellImage.updateMetaData()
        
    } // setup with errors
    
    // test that all drone images loaded and are
    // considered drone images
    func testLoadDroneImage()
    {
        XCTAssertTrue(djiImage.isDroneImage())
        XCTAssertTrue(parrotImage!.isDroneImage())
        XCTAssertTrue(skydioImage!.isDroneImage())
        XCTAssertTrue(autellImage!.isDroneImage())
    }
    
    func testDJIDroneImageMetaData()
    {
        XCTAssert(djiImage != nil)
        
        // check lat, lon
        do {
            try XCTAssertEqual(djiImage.getLatitude(),33.8371893)
            try XCTAssertEqual(djiImage.getLongitude(),-84.5387701)
            try XCTAssertEqual(djiImage.getAltitude(),416.99)
            
            // check drone maker
            try XCTAssertTrue(djiImage.getCameraMake() == "DJI")
            
            // check theta
            try XCTAssertEqual(djiImage.getGimbalPitchDegree(),36.0)
            
            // check azimuth or yaw degree
            try XCTAssertEqual(djiImage.getGimbalYawDegree(),172.40)
            
            // check meta data from Xmp
        }
        catch {
            XCTAssert(false)
        }
    }
    
    
    
} // TestDroneImage
