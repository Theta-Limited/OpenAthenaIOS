// TestCalculations.swift
// OpenAthenaIOSTests
//
// Created by Bobby Krupczak on 5/19/23.
//
// Copyright 2024, Theta Informatics LLC
// AGPLv3
// https://www.gnu.org/licenses/agpl-3.0.txt

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
    var thermalDroneImage: DroneImage!
    var thermalDem: DigitalElevationModel!
    var droneParams: DroneParams?
    
    // load cobb.tiff DEM and DJI_0419.JPG image for use
    override func setUpWithError() throws
    {
        try super.setUpWithError()
        
        print("TestCalculations setup starting")
        
        droneParams = DroneParams()
        print("TestCalculations loaded; file dated \(droneParams!.droneParamsLastUpdate)")
        
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
        
        // re issue #41 load a thermal image w/o focalLength in meta data
        imagePath = Bundle.main.path(forResource: "examples/S1008521", ofType: "JPG")
        XCTAssert(imagePath != nil)
        data = try Data(contentsOf: URL(fileURLWithPath: imagePath!))
        image = UIImage(data: data)
        thermalDroneImage = DroneImage()
        thermalDroneImage.rawData = data
        thermalDroneImage.updateMetaData()
        thermalDroneImage.theImage = image
        thermalDroneImage.targetXprop = 0.5
        thermalDroneImage.targetYprop = 0.5
        
        imagePath = Bundle.main.path(forResource: "examples/S1008521", ofType: "tiff")
        XCTAssert(imagePath != nil)
        thermalDem = DigitalElevationModel(fromURL: URL(fileURLWithPath: imagePath!))
        XCTAssert(thermalDem != nil)
        
        
    } // setUpWithError

    // call resolveTarget with cobb.tiff and DJI_0419.JPG and
    // check result
    
    func testDJIExif35() throws
    {
        var target: [Double] = [0,0,0,0,0]
        
        XCTAssert(djiDem != nil)
        XCTAssert(djiDroneImage != nil)
        
        print("testDJIExif35 starting")
        
        djiDroneImage.ccdInfo = nil
        
        djiDroneImage.targetXprop = 0.50
        djiDroneImage.targetYprop = 0.50
        try target = djiDroneImage.resolveTarget(dem: djiDem, altReference: DroneTargetResolution.AltitudeFromGPS)
        
        print("testDJIExif35 \(target)")
        
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
        
        print("testDJIExif35: \(target)")
        
        // now that we are using drone ccd info and IDW, test numbers
        // have changed just slightly for alpha 1.1 and newer
        
        // altitude
        XCTAssertEqual(target[3],324.8879767296192)

        // distance to target
        XCTAssertEqual(target[0],354.32508924079326)
                       
        // target lat, lon
        XCTAssertEqual(target[1],33.834557006016766)
        XCTAssertEqual(target[2],-84.53707402053148)
        
    } // testDJIExif35
    
    func testSkydioExif35() throws
    {
        var target: [Double] = [0,0,0,0,0]
        
        XCTAssert(skydioDem != nil)
        XCTAssert(skydioDroneImage != nil)
        
        print("testSkydioExif35 starting")
        
        skydioDroneImage.ccdInfo = nil
        
        skydioDroneImage.targetXprop = 0.50
        skydioDroneImage.targetYprop = 0.50
        try target = skydioDroneImage.resolveTarget(dem: skydioDem,altReference: DroneTargetResolution.AltitudeFromGPS)
        
        print("testSkydioExif35 is \(target)")
        
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
        
        print("testSkydioExif35: \(target)")
        
    } // testSkydioExif35
    
    func testAutelExif35() throws
    {
        var target: [Double] = [0,0,0,0,0]
        
        XCTAssert(autelDem != nil)
        XCTAssert(autelDroneImage != nil)
        
        print("testAutelExif35")
        
        autelDroneImage.ccdInfo = nil
        
        autelDroneImage.targetXprop = 0.50
        autelDroneImage.targetYprop = 0.50
        try target = autelDroneImage.resolveTarget(dem: autelDem,altReference: DroneTargetResolution.AltitudeFromGPS)
        
        print("testAutelExif35: \(target)")
        
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
        
        print("testAutelExif35 \(target)")
                
        // altitude
        XCTAssertEqual(target[3],374.7118896180626)

        // distance to target
        XCTAssertEqual(target[0],447.64718832788265)
                       
        // target lat, lon
        XCTAssertEqual(target[1],41.30647978318685)
        XCTAssertEqual(target[2],-96.3437836011802)
        
    } // testAutelExif35
    
    func testParrotExif35() throws
    {
        var target: [Double] = [0,0,0,0,0]
        
        XCTAssert(parrotDem != nil)
        XCTAssert(parrotDroneImage != nil)
        
        print("testParrotExif35 starting")
        
        parrotDroneImage.ccdInfo = nil
        
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
        
    } // testParrotExif35
    
    func testDJI() throws
    {
        var target: [Double] = [0,0,0,0,0]
        
        XCTAssert(djiDem != nil)
        XCTAssert(djiDroneImage != nil)
        
        print("testDJI starting")
        
        // find the CCDInfo for this drone
        do {
            let ccdInfo = try droneParams!.lookupDrone(make: djiDroneImage.getCameraMake(),
                                                       model: djiDroneImage.getCameraModel(),
                                                       targetWidth: djiDroneImage!.theImage!.size.width)
            djiDroneImage.ccdInfo = ccdInfo
        }
        catch {
            XCTFail("Error looking up DJI drone model info")
        }
        
        djiDroneImage.targetXprop = 0.50
        djiDroneImage.targetYprop = 0.50
        try target = djiDroneImage.resolveTarget(dem: djiDem, altReference: DroneTargetResolution.AltitudeFromGPS)
        
        print("testDJI \(target)")
        
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
        
        print("testDJI: \(target)")
        
        // now that we are using drone ccd info and IDW, test numbers
        // have changed just slightly for alpha 1.1 and newer
        
        // altitude
        XCTAssertEqual(target[3],315.1154544888293)

        // distance to target
        XCTAssertEqual(target[0],319.27572548120145)
                       
        // target lat, lon
        XCTAssertEqual(target[1],33.83487295818643)
        XCTAssertEqual(target[2],-84.53732437862318)
        
    } // testDJI
    
    func testSkydio() throws
    {
        var target: [Double] = [0,0,0,0,0]
        
        XCTAssert(skydioDem != nil)
        XCTAssert(skydioDroneImage != nil)
        
        print("testSkydio starting")
        
        // find the CCDInfo for this drone
        do {
            let ccdInfo = try droneParams!.lookupDrone(make: skydioDroneImage.getCameraMake(),
                                                       model: skydioDroneImage.getCameraModel(),
                                                       targetWidth: skydioDroneImage!.theImage!.size.width)
            autelDroneImage.ccdInfo = ccdInfo
        }
        catch {
            XCTFail("Error looking up Skydio drone model info")
        }
        
        skydioDroneImage.targetXprop = 0.50
        skydioDroneImage.targetYprop = 0.50
        try target = skydioDroneImage.resolveTarget(dem: skydioDem,altReference: DroneTargetResolution.AltitudeFromGPS)
        
        print("testSkydio: \(target)")
        
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
        
        print("testSkydio: \(target)")
        
    } // testSkydio
    
    // re issue #41, we should test a thermal camera/drone that does
    // not include focalLength in exif/metadata
    // add S1008521.JPG to examples
    
    func testSkydioX2DThermal() throws
    {
        var target: [Double] = [0,0,0,0,0]
        
        XCTAssert(thermalDem != nil)
        XCTAssert(thermalDroneImage != nil)
        
        print("testSkydioX2DThermal() starting")
        
        // find the CCDInfo for this drone
        do {
            let ccdInfo = try droneParams!.lookupDrone(make: thermalDroneImage.getCameraMake(),
                                                       model: thermalDroneImage.getCameraModel(),
                                                       targetWidth: thermalDroneImage!.theImage!.size.width)
            thermalDroneImage.ccdInfo = ccdInfo
        }
        catch {
            XCTFail("Error looking up thermal drone model info")
        }
        
        thermalDroneImage.targetXprop = 0.50
        thermalDroneImage.targetYprop = 0.50
        try target = thermalDroneImage.resolveTarget(dem: thermalDem,altReference: DroneTargetResolution.AltitudeFromGPS)
        
        print("testSkydioX2DThermal: \(target)")
        
        // now that we are using drone ccd info and IDW, test numbers
        // have changed just slightly for alpha 1.1 and newer
        
        // altitude
        XCTAssertEqual(target[3],59.079129567708435)

        // distance to target
        XCTAssertEqual(target[0],18.003780235200725)

        // target lat, lon
        XCTAssertEqual(target[1],29.786015029765696)
        XCTAssertEqual(target[2],-95.63541650179917)
    
        thermalDroneImage.targetXprop = 0.25
        thermalDroneImage.targetYprop = 0.25
        try target = thermalDroneImage.resolveTarget(dem: thermalDem,altReference: DroneTargetResolution.AltitudeFromGPS)
        
        print("testSkydioX2DThermal \(target)")
        
        // now that we are using drone ccd info and IDW, test numbers
        // have changed just slightly for alpha 1.1 and newer
        
        // altitude
        XCTAssertEqual(target[3],59.091028582754305)

        // distance to target
        XCTAssertEqual(target[0],19.00520183825258)
                       
        // target lat, lon
        XCTAssertEqual(target[1],29.78603127806782)
        XCTAssertEqual(target[2],-95.6354282850735)
    }
    
    func testAutel() throws
    {
        var target: [Double] = [0,0,0,0,0]
        
        XCTAssert(autelDem != nil)
        XCTAssert(autelDroneImage != nil)
        
        print("testAutel starting")
        
        // find the CCDInfo for this drone
        do {
            let ccdInfo = try droneParams!.lookupDrone(make: autelDroneImage.getCameraMake(),
                                                       model: autelDroneImage.getCameraModel(),
                                                       targetWidth: autelDroneImage!.theImage!.size.width)
            autelDroneImage.ccdInfo = ccdInfo
        }
        catch {
            XCTFail("Error looking up Autel drone model info")
        }
        
        autelDroneImage.targetXprop = 0.50
        autelDroneImage.targetYprop = 0.50
        try target = autelDroneImage.resolveTarget(dem: autelDem,altReference: DroneTargetResolution.AltitudeFromGPS)
        
        print("testAutel: \(target)")
        
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
        
        print("testAutel \(target)")
        
        // now that we are using drone ccd info and IDW, test numbers
        // have changed just slightly for alpha 1.1 and newer
        
        // altitude
        XCTAssertEqual(target[3],375.4248301078454)

        // distance to target
        XCTAssertEqual(target[0],222.31463841691848)
                       
        // target lat, lon
        XCTAssertEqual(target[1],41.304531096648645)
        XCTAssertEqual(target[2],-96.34298992555385)
        
    } // testAutel
    
    func testParrot() throws
    {
        var target: [Double] = [0,0,0,0,0]
        
        XCTAssert(parrotDem != nil)
        XCTAssert(parrotDroneImage != nil)
        
        print("testParrot starting")
        
        // find the CCDInfo for this drone
        do {
            let ccdInfo = try droneParams!.lookupDrone(make: parrotDroneImage.getCameraMake(),
                                                       model: parrotDroneImage.getCameraModel(),
                                                       targetWidth: parrotDroneImage!.theImage!.size.width)
            parrotDroneImage.ccdInfo = ccdInfo
        }
        catch {
            //XCTFail("Error looking up Parrot drone model info")
            print("testParrot: failed to find \(try parrotDroneImage.getCameraMake()) \(try parrotDroneImage.getCameraModel())")
        }
        
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
