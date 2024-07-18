// TestEGM96.swift
// OpenAthenaIOSTests
//
// Created by Bobby Krupczak on 6/19/23.
//
// Copyright 2024, Theta Informatics LLC
// AGPLv3
// https://www.gnu.org/licenses/agpl-3.0.txt

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
    
    func testEGM96Offsets() {
        
        // atlanta +33.7490, -84.3880
        XCTAssertEqual(-30.413448028014034, EGM96Geoid.getOffset(lat: 33.7490, lng: -84.3880))
        
        // 0.0, 0.0 in midle atlantic off coast of Africa
        XCTAssertEqual(17.16,EGM96Geoid.getOffset(lat: 0.0, lng: 0.0))
        
        // LA: 34.0522, -118.2437,  -35.422992382534765
        XCTAssertEqual(-35.422992382534765, EGM96Geoid.getOffset(lat:34.0522, lng: -118.2437))

        // Reykjavík: 64.1466, -21.9426, 66.26275258040069
        XCTAssertEqual(66.26275258040069, EGM96Geoid.getOffset(lat:64.1466, lng: -21.9426))

        // London: 51.5074, -0.1278, 46.19035376421903
        XCTAssertEqual(46.19035376421903, EGM96Geoid.getOffset(lat: 51.5074, lng: -0.1278))
        
        // Kyiv: 50.4501, 30.5234, 25.471509018494615
        XCTAssertEqual(25.471509018494615, EGM96Geoid.getOffset(lat: 50.4501, lng: 30.5234))

        // Melbourne, Australia: -37.8136, 144.9631, 4.105052826603198
        XCTAssertEqual(4.105052826603198, EGM96Geoid.getOffset(lat: -37.8136, lng: 144.9631))
        
        // Beijing, China: 39.9042, 116.4074, -10.187067662099095
        XCTAssertEqual(-10.187067662099095, EGM96Geoid.getOffset(lat: 39.9042, lng: 116.4074))

        // Cape Town, South Africa: -33.9249, 18.4241, 31.109644518382122
        XCTAssertEqual(31.109644518382122, EGM96Geoid.getOffset(lat: -33.9249, lng: 18.4241))

        // Santiago, Chile: -33.4489, -70.6693, 26.411616854944732
        XCTAssertEqual(26.411616854944732, EGM96Geoid.getOffset(lat: -33.4489, lng:  -70.6693))
        
    }

    
} // TestEGM96
