//
//  TestDigitalElevationModel.swift
//  OpenAthenaIOSTests
//
//  Created by Bobby Krupczak on 5/18/23.
//

import XCTest
@testable import OpenAthena

final class TestDigitalElevationModel: XCTestCase {

    // load the cobb.tiff and check it
    // against known parameters
    var dem: DigitalElevationModel!
    
    override func setUpWithError() throws {
        
        print("TestDigitalElevationModule: setup starting")
        
        try super.setUpWithError()
        
        var imagePath = Bundle.main.path(forResource: "examples/cobb",
                                         ofType: "tiff")
        XCTAssert(imagePath != nil)
            
        dem = DigitalElevationModel(fromURL: URL(fileURLWithPath: imagePath!))
    
        XCTAssert(dem != nil)
    }
    
    func testLoadDEM()
    {
        XCTAssert(dem != nil)
        XCTAssertEqual(dem.directory.numEntries(),19)
        XCTAssertEqual(dem.xParams.start,-84.7348611110986)
        XCTAssertEqual(dem.xParams.end,-84.34236111109854)
        XCTAssertEqual(dem.yParams.start,34.0801388888853)
        XCTAssertEqual(dem.yParams.end,33.74986111110748)
    }
    
    func testDEMParams()
    {
        XCTAssert(dem != nil)

    }
    
}
