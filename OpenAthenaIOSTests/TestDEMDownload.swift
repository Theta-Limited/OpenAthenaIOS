// TestDEMDownload.swift
// OpenAthenaIOSTests
//
// Created by Bobby Krupczak on 3/15/24.
// Test DEM auto download code
// One successful, one error
// Copyright 2024, Theta Informatics LLC
// AGPLv3
// https://www.gnu.org/licenses/agpl-3.0.txt

import XCTest
@testable import OpenAthena

final class TestDEMDownload: XCTestCase 
{

    func testDownloadSucceed() throws
    {
        let aDownloader = DemDownloader(lat: 36.5108691, lon: -104.9158341, length: 15000)
        aDownloader.download() { resultCode, bytes, filename in
            print("testDownloadSucceed: return code \(resultCode)")
            XCTAssert(resultCode == 200)
        }
    }

    func testDownloadFail() throws 
    {
        let aDownloader = DemDownloader(lat: 0, lon: 0, length: 1000)
        aDownloader.download() { resultCode, bytes, filename in
            print("testDownloadFail: return code \(resultCode)")
            XCTAssert(resultCode == 204)
        }
    }

}
