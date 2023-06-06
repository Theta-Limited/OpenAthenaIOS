//
//  TestMakeModel.swift
//  OpenAthenaIOSTests
//
//  Created by Bobby Krupczak on 5/26/23.
//

import XCTest
@testable import OpenAthenaIOS

final class TestMakeModel: XCTestCase {

    var djiImage: DroneImage!
    var parrotImage: DroneImage!
    var autellImage: DroneImage!
    var skydioImage: DroneImage!
    var droneParams: DroneParams!
    
    override func setUpWithError() throws {
        
        print("TestMakeModel: setup starting")
        
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
        
        droneParams = DroneParams()
        
    } // setup with errors
    
    func testDJIMakeModel() throws
    {
        let cStr = try djiImage.getCameraMake()
        let mStr = try djiImage.getCameraModel()
        
        XCTAssertEqual(cStr,"DJI")
        XCTAssertEqual(mStr,"FC2204")
        
        let dinfo = try droneParams.lookupDrone(make: cStr,model: mStr)
        XCTAssertEqual(dinfo.widthPixels,4000.0)
        XCTAssertEqual(dinfo.heightPixels,3000.0)
        XCTAssertEqual(dinfo.ccdWidthMMPerPixel,6.17/4000.0)
        XCTAssertEqual(dinfo.ccdHeightMMPerPixel,4.55/3000.0)
    }
    
    func testAutellMakeModel() throws
    {
        try XCTAssertEqual(autellImage.getCameraMake(),"Autel Robotics")
        try XCTAssertEqual(autellImage.getCameraModel(),"XT701")
    }
    
    func testSkydioMakeModel() throws
    {
        try XCTAssertEqual(skydioImage.getCameraMake(),"Skydio")
        try XCTAssertEqual(skydioImage.getCameraModel(),"2")
    }
    
    // parrot sometimes reports PARROT and sometimes Parrot
    func testParrotMakeModel() throws
    {
        try XCTAssertEqual(parrotImage.getCameraMake(),"PARROT")
        try XCTAssertEqual(parrotImage.getCameraModel(),"Disco")
    }
    
    
} // TestMakeModel
