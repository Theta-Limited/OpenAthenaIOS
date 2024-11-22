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
    var teal2DroneImage: DroneImage!
    var teal2Dem: DigitalElevationModel!
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
        //var image = UIImage(data: data)
        //djiDroneImage = DroneImageDJI()
        //djiDroneImage.rawData = data
        //djiDroneImage.updateMetaData()
        //djiDroneImage.theImage = image
        djiDroneImage = DroneImageFactory.createDroneImage(data: data)
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
        //image = UIImage(data: data)
        //skydioDroneImage = DroneImageSkydio()
        //skydioDroneImage.rawData = data
        //skydioDroneImage.updateMetaData()
        //skydioDroneImage.theImage = image
        skydioDroneImage = DroneImageFactory.createDroneImage(data: data)
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
        //image = UIImage(data: data)
        //autelDroneImage = DroneImageAutel()
        //autelDroneImage.rawData = data
        //autelDroneImage.updateMetaData()
        //autelDroneImage.theImage = image
        autelDroneImage = DroneImageFactory.createDroneImage(data: data)
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
        //image = UIImage(data: data)
        //parrotDroneImage = DroneImageParrot()
        //parrotDroneImage.rawData = data
        //parrotDroneImage.updateMetaData()
        //parrotDroneImage.theImage = image
        parrotDroneImage = DroneImageFactory.createDroneImage(data: data)
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
        //image = UIImage(data: data)
        //thermalDroneImage = DroneImageSkydio()
        //thermalDroneImage.rawData = data
        //thermalDroneImage.updateMetaData()
        //thermalDroneImage.theImage = image
        thermalDroneImage = DroneImageFactory.createDroneImage(data: data)
        thermalDroneImage.targetXprop = 0.5
        thermalDroneImage.targetYprop = 0.5
        
        imagePath = Bundle.main.path(forResource: "examples/S1008521", ofType: "tiff")
        XCTAssert(imagePath != nil)
        thermalDem = DigitalElevationModel(fromURL: URL(fileURLWithPath: imagePath!))
        XCTAssert(thermalDem != nil)
        
        imagePath = Bundle.main.path(forResource: "examples/teal2_img_eo_00015", ofType: "jpg")
        XCTAssert(imagePath != nil)
        data = try Data(contentsOf: URL(fileURLWithPath: imagePath!))
        //image = UIImage(data: data)
        //teal2DroneImage = DroneImageTeal()
        //teal2DroneImage.rawData = data
        //teal2DroneImage.updateMetaData()
        //teal2DroneImage.theImage = image
        teal2DroneImage = DroneImageFactory.createDroneImage(data: data)
        teal2DroneImage.targetXprop = 0.5
        teal2DroneImage.targetYprop = 0.5
        
        imagePath = Bundle.main.path(forResource: "examples/teal2", ofType: "tiff")
        XCTAssert(imagePath != nil)
        teal2Dem = DigitalElevationModel(fromURL: URL(fileURLWithPath: imagePath!))
        XCTAssert(teal2Dem != nil)
        
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
        XCTAssertEqual(target[3],245.25839721158042)

        // distance to target
        // XCTAssertEqual(target[0],239.16353221862235)
        XCTAssertEqual(target[0],240.16422446122968)

        // target lat, lon
        // XCTAssertEqual(target[1],33.835465932500185)
        // XCTAssertEqual(target[2],-84.53849326691132)
        XCTAssertEqual(target[1],33.83545871335009)
        XCTAssertEqual(target[2],-84.53849210727509)
    
        djiDroneImage.targetXprop = 0.25
        djiDroneImage.targetYprop = 0.25
        try target = djiDroneImage.resolveTarget(dem: djiDem,
                                                 altReference: DroneTargetResolution.AltitudeFromGPS)
        
        print("testDJIExif35: \(target)")
        
        // now that we are using drone ccd info and IDW, test numbers
        // have changed just slightly for alpha 1.1 and newer
        
        // altitude
        XCTAssertEqual(target[3],263.5616922531621)

        // distance to target
        XCTAssertEqual(target[0],354.325092364044)
                       
        // target lat, lon
        XCTAssertEqual(target[1],33.83455698068224)
        XCTAssertEqual(target[2],-84.53707400420772)
        
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
        XCTAssertEqual(target[3],960.2743743564303)
        // distance to target
        XCTAssertEqual(target[0],343.32610444880345)
        // target lat, lon
        XCTAssertEqual(target[1],32.5170760363771)
        XCTAssertEqual(target[2],-110.9216681289032)
        
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
        XCTAssertEqual(target[3],323.95101262995206)

        // distance to target
        XCTAssertEqual(target[0],84.10228375270978)

        // target lat, lon
        XCTAssertEqual(target[1],41.3033315794224)
        XCTAssertEqual(target[2],-96.34221452075164)
    
        autelDroneImage.targetXprop = 0.25
        autelDroneImage.targetYprop = 0.25
        try target = autelDroneImage.resolveTarget(dem: autelDem,altReference: DroneTargetResolution.AltitudeFromGPS)
        
        print("testAutelExif35 \(target)")
                
        // altitude
        XCTAssertEqual(target[3],320.1422880639665)

        // distance to target
        XCTAssertEqual(target[0],447.6471938791034)
                       
        // target lat, lon
        XCTAssertEqual(target[1],41.30647981607087)
        XCTAssertEqual(target[2],-96.34378361429144)
        
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
        XCTAssertEqual(target[3],245.25839721158042)

        // distance to target
        // XCTAssertEqual(target[0],239.16353221862235)
        XCTAssertEqual(target[0],240.16422446122968)

        // target lat, lon
        // XCTAssertEqual(target[1],33.835465932500185)
        // XCTAssertEqual(target[2],-84.53849326691132)
        XCTAssertEqual(target[1],33.83545871335009)
        XCTAssertEqual(target[2],-84.53849210727509)
    
        djiDroneImage.targetXprop = 0.25
        djiDroneImage.targetYprop = 0.25
        try target = djiDroneImage.resolveTarget(dem: djiDem,
                                                 altReference: DroneTargetResolution.AltitudeFromGPS)
        
        print("testDJI: \(target)")
        
        // now that we are using drone ccd info and IDW, test numbers
        // have changed just slightly for alpha 1.1 and newer
        
        // altitude
        XCTAssertEqual(target[3],253.78917001237238)

        // distance to target
        XCTAssertEqual(target[0],319.27572813788794)
                       
        // target lat, lon
        XCTAssertEqual(target[1],33.83487293589259)
        XCTAssertEqual(target[2],-84.53732436470915)
        
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
        XCTAssertEqual(target[3],960.2743743564303)
        // distance to target
        XCTAssertEqual(target[0],343.32610444880345)
        // target lat, lon
        XCTAssertEqual(target[1],32.5170760363771)
        XCTAssertEqual(target[2],-110.9216681289032)
        
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
        XCTAssertEqual(target[3],1.888934027508045)

        // distance to target
        XCTAssertEqual(target[0],18.003780268917858)

        // target lat, lon
        XCTAssertEqual(target[1],29.786015030498834)
        XCTAssertEqual(target[2],-95.63541650179769)
    
        thermalDroneImage.targetXprop = 0.25
        thermalDroneImage.targetYprop = 0.25
        try target = thermalDroneImage.resolveTarget(dem: thermalDem,altReference: DroneTargetResolution.AltitudeFromGPS)
        
        print("testSkydioX2DThermal \(target)")
        
        // now that we are using drone ccd info and IDW, test numbers
        // have changed just slightly for alpha 1.1 and newer
        
        // altitude
        XCTAssertEqual(target[3],1.9008330425538593)

        // distance to target
        XCTAssertEqual(target[0],19.005201884671287)
                       
        // target lat, lon
        XCTAssertEqual(target[1],29.786031278946766)
        XCTAssertEqual(target[2],-95.63542828517778)
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
        XCTAssertEqual(target[3],323.95101262995206)

        // distance to target
        XCTAssertEqual(target[0],84.10228375270978)

        // target lat, lon
        XCTAssertEqual(target[1],41.3033315794224)
        XCTAssertEqual(target[2],-96.34221452075164)
    
        autelDroneImage.targetXprop = 0.25
        autelDroneImage.targetYprop = 0.25
        try target = autelDroneImage.resolveTarget(dem: autelDem,altReference: DroneTargetResolution.AltitudeFromGPS)
        
        print("testAutel \(target)")
        
        // now that we are using drone ccd info and IDW, test numbers
        // have changed just slightly for alpha 1.1 and newer
        
        // altitude
        XCTAssertEqual(target[3],320.85522855374927)

        // distance to target
        XCTAssertEqual(target[0],222.31464110937708)
                       
        // target lat, lon
        XCTAssertEqual(target[1],41.30453111283675)
        XCTAssertEqual(target[2],-96.3429899318648)
        
    } // testAutel
    
    func testTeal2() throws
    {
        var target: [Double] = [0,0,0,0,0]
        
        XCTAssert(teal2Dem != nil)
        XCTAssert(teal2DroneImage != nil)
        
        print("testTeal2 starting")
        
        // find the CCDInfo for this drone
        do {
            let ccdInfo = try droneParams!.lookupDrone(make: teal2DroneImage.getCameraMake(),
                                                       model: teal2DroneImage.getCameraModel(),
                                                       targetWidth: teal2DroneImage!.theImage!.size.width)
            teal2DroneImage.ccdInfo = ccdInfo
        }
        catch {
            print("testTeal2: failed to find \(try teal2DroneImage.getCameraMake()) \(try teal2DroneImage.getCameraModel())")
        }
        
        teal2DroneImage.targetXprop = 0.50
        teal2DroneImage.targetYprop = 0.50
        
        try target = teal2DroneImage.resolveTarget(dem: teal2Dem, altReference: DroneTargetResolution.AltitudeFromGPS)
        
        // altitude
        XCTAssertEqual(target[3],1283.7435183873504)
        
        // distance to target
        XCTAssertEqual(target[0],23.009090808226624)
        
        // target lat, lon
        XCTAssertEqual(target[1],40.71041728540079)
        XCTAssertEqual(target[2],-111.8944343566073)
        
    }
    
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
