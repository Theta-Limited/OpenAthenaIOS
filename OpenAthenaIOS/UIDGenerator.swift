// UIDGenerator.swift
// OpenAthenaIOS
//
// Created by Bobby Krupczak on 7/1/24.
// Java conversion via ChatGPT
// Copyright 2024, Theta Informatics LLC
// AGPLv3
// https://www.gnu.org/licenses/agpl-3.0.txt

import Foundation
import CryptoKit
import Network
import UIKit

public class UIDGenerator
{
    static let phoneticalAlphabet = [
        "Alfa", "Bravo", "Charlie", "Delta", "Echo", "Foxtrot",
        "Golf", "Hotel", "Indeia", "Juliett", "Kilo", "Lima",
        "Mike", "November", "Oscar", "Papa", "Quebec", "Romeo",
        "Sierra", "Tango", "Uniform", "Victor", "Whiskey", "Xray",
        "Yankee", "Zulu"
    ]
    
    // written with aid of ChatGPT
    public class func getDeviceHostnameHash() -> String {
        var aString: String = ""
        
        aString = UIDevice.current.name
        if aString == "" {
            aString = "unknown-hostname"
        }
        print("getDeviceHostnameHash: hostname is \(aString)")
        if let inputData = aString.data(using: .utf8) {
            let hashData = SHA256.hash(data: inputData)
            let hashString = hashData.compactMap { String(format: "%02x",$0) }.joined()
            let truncatedHash = String(hashString.prefix(8))
            return truncatedHash
        }
        
        return "feedface"
    }
    
    class func getDeviceUniqueID() -> String
    {
        let uniqueID = getDeviceHostnameHash().prefix(8)

        print("getDeviceUniqueID: hash is \(uniqueID)")
        return String(uniqueID)
    }
    
    public class func getDeviceHostnamePhonetic() -> String
    {
        let phoneticUID:String = "unknown"
        let uniqueID:String = getDeviceUniqueID()
        
        // take the unique id hash and convert to a phonetic plus 2-digit e.g. tango01
        
        guard uniqueID.count >= 6 else {
            return "idError0"
        }
        let lastFour = String(uniqueID.suffix(4))
        guard let num = Int(lastFour, radix: 16) else {
            return "idError1"
        }
        let alpha = phoneticalAlphabet[num % 26]
        
        let index = uniqueID.index(uniqueID.endIndex, offsetBy: -6)
        let range = index..<uniqueID.index(after: index)
        let twoChars = uniqueID[range]
        
        guard let num = Int(twoChars, radix: 16) else {
            return "idError2"
        }
        
        print("getDeviceHostnamePhonetic: \(alpha) \(num%100)")
        
        return alpha + String(format: "%02d",num%100)
    }
    
    
} // UIDGenerator
