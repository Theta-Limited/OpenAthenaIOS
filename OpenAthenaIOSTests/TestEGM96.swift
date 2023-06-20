//
//  TestEGM96.swift
//  OpenAthenaIOSTests
//
//  Created by Bobby Krupczak on 6/19/23.
//

import XCTest
@testable import OpenAthena

final class TestEGM96: XCTestCase {
    
    override func setUpWithError() throws {
        
        try super.setUpWithError()
        
        print("Testing EGM96Geoid")
        
        let status = EGM96Geoid.initEGM96Geoid()
        
        if status == false {
            print("failed to initialize EGM96Geoid")
            
        }
        
    }
    
    func testEGM96Model()
    {
        let status = EGM96Geoid.initEGM96Geoid()
        XCTAssertTrue(status)
    }

    
} // TestEGM96
