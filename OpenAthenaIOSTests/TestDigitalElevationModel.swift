//
//  TestDigitalElevationModel.swift
//  OpenAthenaIOSTests
//
//  Created by Bobby Krupczak on 5/18/23.
//

import XCTest
@testable import OpenAthenaIOS

final class TestDigitalElevationModel: XCTestCase {

    // load the cobb.tiff and check it
    // against known parameters
    
    func testLoadDEM()
    {
        var imagePath = Bundle.main.path(forResource: "cobb.tiff",
                                         ofType: "tiff")
        do {
            
            
        }
        catch {
            XCTAssert(false)
        }
    }
    
    func testDEMParams()
    {
        
        
    }
    
}
