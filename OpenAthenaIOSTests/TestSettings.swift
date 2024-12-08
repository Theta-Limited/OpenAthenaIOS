// TestSettings.swift
// OpenAthenaIOSTests
//
// Created by Bobby Krupczak on 5/18/23.
// Test app settings loading, saving
// Copyright 2024, Theta Informatics LLC
// AGPLv3
// https://www.gnu.org/licenses/agpl-3.0.txt

import XCTest
@testable import OpenAthena

final class TestSettings: XCTestCase {

    var settings: AthenaSettings = AthenaSettings()
    var outputMode: AthenaSettings.OutputModes!
    var lookupMode: AthenaSettings.DEMLookupModes!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        settings.loadDefaults()
    }
    
    func testLoadDefaults()
    {
        settings.loadDefaults()
        outputMode = settings.outputMode
        lookupMode = settings.lookupMode
    }
    
    func testWriteDefaults()
    {
        // save what we got then write and then read and compare
        outputMode = settings.outputMode
        lookupMode = settings.lookupMode
        
        settings.writeDefaults()
        settings.loadDefaults()
        
        XCTAssertEqual(outputMode,settings.outputMode)
        XCTAssertEqual(lookupMode,settings.lookupMode)
        
    }

}
