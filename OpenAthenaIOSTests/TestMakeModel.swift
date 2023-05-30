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
        
    } // setup with errors
    
    func testDJIMakeModel() throws
    {
        try XCTAssertEqual(djiImage.getCameraMake(),"DJI")
        try XCTAssertEqual(djiImage.getCameraModel(),"FC2204")
    }
    
    func testAutellMakeModel() throws
    {
        try XCTAssertEqual(autellImage.getCameraMake(),"Autel Robotic")
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
    }}
