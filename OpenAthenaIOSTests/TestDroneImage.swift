//
//  TestDroneImage.swift
//  OpenAthenaIOSTests
//
//  Created by Bobby Krupczak on 5/17/23.
//

import XCTest 
@testable import OpenAthenaIOS

final class TestDroneImage: XCTestCase {

    // load DJI_0419.JPG drone image and verify
    // that its a drone image
    func testLoadDroneImage()
    {
                
        var imagePath = Bundle.main.path(forResource: "DJI_0419.JPG",
                                         ofType: "jpg")
        do {
            var data = try Data(contentsOf: URL(fileURLWithPath: imagePath!))
            var image = UIImage(data: data)
            var droneImage = DroneImage()
            droneImage.rawData = data
            droneImage.updateMetaData()
            XCTAssertTrue(droneImage.isDroneImage())
        }
        catch {
            XCTAssert(false)
        }
    }
    
    func testDroneImageMetaData()
    {
        XCTAssert(false)
    }
    
    
    
} // TestDroneImage
