//
//  TestCalculations.swift
//  OpenAthenaIOSTests
//
//  Created by Bobby Krupczak on 5/19/23.
//

import XCTest
@testable import OpenAthena

final class TestCalculations: XCTestCase {

    var djiDroneImage: DroneImage!
    var djiDem: DigitalElevationModel!
    var skydioDroneImage: DroneImage!
    var skydioDem: DigitalElevationModel!
    var autelDroneImage: DroneImage!
    var autelDem: DigitalElevationModel!
    var parrotDroneImage: DroneImage!
    var parrotDem: DigitalElevationModel!
    
    // load cobb.tiff DEM and DJI_0419.JPG image for use
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        print("TestCalculations starting")
        
        // load DJI image
        
        var imagePath = Bundle.main.path(forResource: "examples/DJI_0419", ofType: "JPG")
        XCTAssert(imagePath != nil)
        var data = try Data(contentsOf: URL(fileURLWithPath: imagePath!))
        var image = UIImage(data: data)
        djiDroneImage = DroneImage()
        djiDroneImage.rawData = data
        djiDroneImage.updateMetaData()
        djiDroneImage.theImage = image
        djiDroneImage.targetXprop = 0.5
        djiDroneImage.targetYprop = 0.5
        
        imagePath = Bundle.main.path(forResource: "examples/cobb", ofType: "tiff")
        XCTAssert(imagePath != nil)
        djiDem = DigitalElevationModel(fromURL: URL(fileURLWithPath: imagePath!))
        XCTAssert(djiDem != nil)
        
        // load skydio image
        
        imagePath = Bundle.main.path(forResource: "examples/skydio-catilina",
                                     ofType: "jpg")
        XCTAssert(imagePath != nil)
        data = try Data(contentsOf: URL(fileURLWithPath: imagePath!))
        image = UIImage(data: data)
        skydioDroneImage = DroneImage()
        skydioDroneImage.rawData = data
        skydioDroneImage.updateMetaData()
        skydioDroneImage.theImage = image
        skydioDroneImage.targetXprop = 0.5
        skydioDroneImage.targetYprop = 0.5
        
        imagePath = Bundle.main.path(forResource: "examples/skydio-catilina-dem", ofType: "tiff")
        XCTAssert(imagePath != nil)
        skydioDem = DigitalElevationModel(fromURL: URL(fileURLWithPath: imagePath!))
        XCTAssert(skydioDem != nil)
        
        // load autel image
        imagePath = Bundle.main.path(forResource: "examples/waterloo-autell",
                                     ofType: "jpg")
        XCTAssert(imagePath != nil)
        data = try Data(contentsOf: URL(fileURLWithPath: imagePath!))
        image = UIImage(data: data)
        autelDroneImage = DroneImage()
        autelDroneImage.rawData = data
        autelDroneImage.updateMetaData()
        autelDroneImage.theImage = image
        autelDroneImage.targetXprop = 0.5
        autelDroneImage.targetYprop = 0.5
        
        imagePath = Bundle.main.path(forResource: "examples/waterloo-autell-dem", ofType: "tiff")
        XCTAssert(imagePath != nil)
        autelDem = DigitalElevationModel(fromURL: URL(fileURLWithPath: imagePath!))
        XCTAssert(autelDem != nil)

        // load parrot image
        imagePath = Bundle.main.path(forResource: "examples/parrot-1", ofType: "jpg")
        XCTAssert(imagePath != nil)
        data = try Data(contentsOf: URL(fileURLWithPath: imagePath!))
        image = UIImage(data: data)
        parrotDroneImage = DroneImage()
        parrotDroneImage.rawData = data
        parrotDroneImage.updateMetaData()
        parrotDroneImage.theImage = image
        parrotDroneImage.targetXprop = 0.5
        parrotDroneImage.targetYprop = 0.5
        
        imagePath = Bundle.main.path(forResource: "examples/parrot-1-dem", ofType: "tiff")
        XCTAssert(imagePath != nil)
        parrotDem = DigitalElevationModel(fromURL: URL(fileURLWithPath: imagePath!))
        XCTAssert(parrotDem != nil)
        
    } // setUpWithError

    // call resolveTarget with cobb.tiff and DJI_0419.JPG and
    // check results
    
    func testDJI() throws
    {
        var target: [Double] = [0,0,0,0,0]
        
        XCTAssert(djiDem != nil)
        XCTAssert(djiDroneImage != nil)
        
        djiDroneImage.targetXprop = 0.50
        djiDroneImage.targetYprop = 0.50
        try target = djiDroneImage.resolveTarget(dem: djiDem, altReference: DroneTargetResolution.AltitudeFromGPS)
        
        print("testResolveTarget: \(target)")
        
        // now that we are using drone ccd info and IDW, test numbers
        // have changed just slightly for alpha 1.1 and newer
        
        // altitude
        // XCTAssertEqual(target[3], 276.5093247021014)
        XCTAssertEqual(target[3],306.5846816880375)

        // distance to target
        // XCTAssertEqual(target[0],239.16353221862235)
        XCTAssertEqual(target[0],240.164222893169)

        // target lat, lon
        // XCTAssertEqual(target[1],33.835465932500185)
        // XCTAssertEqual(target[2],-84.53849326691132)
        XCTAssertEqual(target[1],33.835458730005925)
        XCTAssertEqual(target[2],-84.53849210995045)
    
        djiDroneImage.targetXprop = 0.25
        djiDroneImage.targetYprop = 0.25
        try target = djiDroneImage.resolveTarget(dem: djiDem,
                                                 altReference: DroneTargetResolution.AltitudeFromGPS)
        
        print("testResolveTarget: \(target)")
        
        // now that we are using drone ccd info and IDW, test numbers
        // have changed just slightly for alpha 1.1 and newer
        
        // altitude
        XCTAssertEqual(target[3],324.8879767296192)

        // distance to target
        XCTAssertEqual(target[0],354.32508924079326)
                       
        // target lat, lon
        XCTAssertEqual(target[1],33.834557006016766)
        XCTAssertEqual(target[2],-84.53707402053148)
        
    } // testDJI
    
    func testSkydio() throws
    {
        var target: [Double] = [0,0,0,0,0]
        
        XCTAssert(skydioDem != nil)
        XCTAssert(skydioDroneImage != nil)
        
        skydioDroneImage.targetXprop = 0.50
        skydioDroneImage.targetYprop = 0.50
        try target = skydioDroneImage.resolveTarget(dem: skydioDem,altReference: DroneTargetResolution.AltitudeFromGPS)
        
        print("target is \(target)")
        
        // altitude
        XCTAssertEqual(target[3],1019.4415581971641)
        // distance to target
        XCTAssertEqual(target[0],343.32610143042746)
        // target lat, lon
        XCTAssertEqual(target[1],32.517076053635684)
        XCTAssertEqual(target[2],-110.92166815563021)
        
        // 0.25, 0.25 throws DEM out of bounds on OA iOS and Android
        // thats OK; make sure an error is thrown
        skydioDroneImage.targetXprop = 0.25
        skydioDroneImage.targetYprop = 0.25
        XCTAssertThrowsError(target = try skydioDroneImage.resolveTarget(dem: skydioDem,altReference: DroneTargetResolution.AltitudeFromGPS))
        
        print("testResolveTarget: \(target)")
    } // testSkydio
    
    func testAutel() throws
    {
        var target: [Double] = [0,0,0,0,0]
        
        XCTAssert(autelDem != nil)
        XCTAssert(autelDroneImage != nil)
        
        autelDroneImage.targetXprop = 0.50
        autelDroneImage.targetYprop = 0.50
        try target = autelDroneImage.resolveTarget(dem: autelDem,altReference: DroneTargetResolution.AltitudeFromGPS)
        
        print("testResolveTarget: \(target)")
        
        // now that we are using drone ccd info and IDW, test numbers
        // have changed just slightly for alpha 1.1 and newer
        
        // altitude
        XCTAssertEqual(target[3],378.5206141840482)

        // distance to target
        XCTAssertEqual(target[0],84.10228287675572)

        // target lat, lon
        XCTAssertEqual(target[1],41.30333157351147)
        XCTAssertEqual(target[2],-96.34221452108417)
    
        autelDroneImage.targetXprop = 0.25
        autelDroneImage.targetYprop = 0.25
        try target = autelDroneImage.resolveTarget(dem: autelDem,altReference: DroneTargetResolution.AltitudeFromGPS)
        
        print("testResolveTarget: \(target)")
        
        // now that we are using drone ccd info and IDW, test numbers
        // have changed just slightly for alpha 1.1 and newer
        
        // altitude
        XCTAssertEqual(target[3],374.7118896180626)

        // distance to target
        XCTAssertEqual(target[0],447.64718832788265)
                       
        // target lat, lon
        XCTAssertEqual(target[1],41.30647978318685)
        XCTAssertEqual(target[2],-96.3437836011802)
        
    } // testAutel
    
    func testParrot() throws
    {
        var target: [Double] = [0,0,0,0,0]
        
        XCTAssert(parrotDem != nil)
        XCTAssert(parrotDroneImage != nil)
        
        parrotDroneImage.targetXprop = 0.50
        parrotDroneImage.targetYprop = 0.50
        
        // right now, this parrot-1 image throws exception for out of bounds
        // need to test on parrot-2 XXX
        XCTAssertThrowsError(try target = parrotDroneImage.resolveTarget(dem: parrotDem,altReference: DroneTargetResolution.AltitudeFromGPS))
        
//        print("testResolveTarget: \(target)")
//
//        // now that we are using drone ccd info and IDW, test numbers
//        // have changed just slightly for alpha 1.1 and newer
//
//        // altitude
//        XCTAssertEqual(target[3],0.0)
//
//        // distance to target
//        XCTAssertEqual(target[0],0.0)
//
//        // target lat, lon
//        XCTAssertEqual(target[1],0.0)
//        XCTAssertEqual(target[2],0.0)
//
//        parrotDroneImage.targetXprop = 0.25
//        parrotDroneImage.targetYprop = 0.25
//        try target = parrotDroneImage.resolveTarget(dem: parrotDem)
//
//        print("testResolveTarget: \(target)")
//
//        // now that we are using drone ccd info and IDW, test numbers
//        // have changed just slightly for alpha 1.1 and newer
//
//        // altitude
//        XCTAssertEqual(target[3],0.0)
//
//        // distance to target
//        XCTAssertEqual(target[0],0.0)
//
//        // target lat, lon
//        XCTAssertEqual(target[1],0.0)
//        XCTAssertEqual(target[2],0.0)
        
    } // testParrot
        
} // TestCalculations
