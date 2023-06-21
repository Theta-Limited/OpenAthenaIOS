//
//  TestDroneImage.swift
//  OpenAthenaIOSTests
//
//  Created by Bobby Krupczak on 5/17/23.
//

import XCTest 
@testable import OpenAthena

final class TestDroneImage: XCTestCase {

    var djiImage: DroneImage!
    var parrotImage: DroneImage!
    var autelImage: DroneImage!
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
        autelImage = DroneImage()
        autelImage.rawData = data
        autelImage.theImage = image
        autelImage.updateMetaData()
        
    } // setup with errors
    
    // test that all drone images loaded and are
    // considered drone images
    func testLoadDroneImage()
    {
        XCTAssertTrue(djiImage.isDroneImage())
        XCTAssertTrue(parrotImage!.isDroneImage())
        XCTAssertTrue(skydioImage!.isDroneImage())
        XCTAssertTrue(autelImage!.isDroneImage())
    }
    
    func testDJIDroneImageMetaData()
    {
        XCTAssert(djiImage != nil)
        
        // check lat, lon
        do {
            try XCTAssertEqual(djiImage.getLatitude(),33.8371893)
            try XCTAssertEqual(djiImage.getLongitude(),-84.5387701)
            try XCTAssertEqual(djiImage.getAltitude(),447.65314223822855)
            
            // check drone maker
            try XCTAssertTrue(djiImage.getCameraMake() == "DJI")
            
            // check theta
            try XCTAssertEqual(djiImage.getGimbalPitchDegree(),36.0)
            
            // check azimuth or yaw degree
            try XCTAssertEqual(djiImage.getGimbalYawDegree(),172.40)
            
            // check meta data from Xmp
            try XCTAssertEqual(djiImage.getFocalLength(),4.386)
            try XCTAssertEqual(djiImage.getFocalLengthIn35mm(),24.0)
            try XCTAssertEqual(djiImage.getRoll(),0.0)
        }
        catch {
            XCTAssert(false)
        }
    } // testDJIDroneImageMetaData()
    
    func testSkydioImageMetaData() {
        
        XCTAssert(skydioImage != nil)
        
        // check lat, lon, others
        do {
            try XCTAssertEqual(skydioImage.getLatitude(),32.518935)
            try XCTAssertEqual(skydioImage.getLongitude(),-110.924547)
            try XCTAssertEqual(skydioImage.getAltitude(),1064.0255019203844)
            
            // check drone maker
            try XCTAssertTrue(skydioImage.getCameraMake() == "Skydio")
            
            // check theta
            try XCTAssertEqual(skydioImage.getGimbalPitchDegree(),7.468572)
            
            // check azimuth or yaw degree
            try XCTAssertEqual(skydioImage.getGimbalYawDegree(),127.444323)
            
            // check meta data from Xmp
            try XCTAssertEqual(skydioImage.getFocalLength(),4.7)
            try XCTAssertEqual(skydioImage.getFocalLengthIn35mm(),21.0)
            try XCTAssertEqual(skydioImage.getRoll(),0.186841)
        }
        catch {
            XCTAssert(false)
        }
        
    } // skydio catilina
    
    func testAutelImageMetaData() {
        
        XCTAssert(autelImage != nil)
        
        // check lat, lon, others
        do {
            try XCTAssertEqual(autelImage.getLatitude(),41.302641666666666)
            try XCTAssertEqual(autelImage.getLongitude(),-96.34225333333333)
            try XCTAssertEqual(autelImage.getAltitude(),385.34811)
            
            // check drone maker
            try XCTAssertTrue(autelImage.getCameraMake() == "Autel Robotics")
            
            // check theta
            try XCTAssertEqual(autelImage.getGimbalPitchDegree(),66.04)
            
            // check azimuth or yaw degree
            try XCTAssertEqual(autelImage.getGimbalYawDegree(),2.42)
            
            // check meta data from Xmp
            try XCTAssertEqual(autelImage.getFocalLength(),4.74)
            try XCTAssertEqual(autelImage.getFocalLengthIn35mm(),26.0)
            try XCTAssertEqual(autelImage.getRoll(),0.0)
        }
        catch {
            XCTAssert(false)
        }
        
    } // autel waterloo
    
    func testParrotImageMetaData() {
        
        XCTAssert(parrotImage != nil)
        
        // check lat, lon, others
        do {
            try XCTAssertEqual(parrotImage.getLatitude(),57.99953166666667)
            try XCTAssertEqual(parrotImage.getLongitude(),25.549638333333334)
            try XCTAssertEqual(parrotImage.getAltitude(),78.98716050710475)
            
            // check drone maker
            try XCTAssertTrue(parrotImage.getCameraMake() == "PARROT")
            
            // check theta
            try XCTAssertEqual(parrotImage.getGimbalPitchDegree(),2.054081678)
            
            // check azimuth or yaw degree
            try XCTAssertEqual(parrotImage.getGimbalYawDegree(),18.678611755)
            
            // check meta data from Xmp
            try XCTAssertEqual(parrotImage.getFocalLength(),1.8300001180412324)
            try XCTAssertEqual(parrotImage.getFocalLengthIn35mm(),6.0)
            try XCTAssertEqual(parrotImage.getRoll(),-2.391976595)
        }
        catch {
            XCTAssert(false)
        }
        
    } // autel waterloo
} // TestDroneImage
