// DroneParams.swift
// OpenAthenaIOS
// https://github.com/Theta-Limited/OpenAthenaIOS
// https://openathena.com//
// Created by Bobby Krupczak on 5/26/23.
// Encapsulate drone parameter data in this class
// both for static out of box and for
// updating via local data file or network download
// Copyright 2024, Theta Informatics LLC
// AGPLv3
// https://www.gnu.org/licenses/agpl-3.0.txt

// for Drones, we are tracking make, model, width and height (in mm) of a pixel
// and the width-pixels and height-pixels of the drone's specific CCD/CMOS sensor
// ccd_width(mm) / width_pixels = pixel_width(mm/pixel)
// width-pixels, height-pixels, width, height
// makeModel is concatenation of make and model (e.g. DJIFC220)

import Foundation
import UIKit

public struct DroneCCDInfo {
    let makeModel: String  // also the dictionary key
    let ccdWidthMMPerPixel: Double
    let ccdHeightMMPerPixel: Double
    let widthPixels: Double
    let heightPixels: Double
    let comment: String
    // re issue #41, don't forget focalLength
    let isThermal: Bool
    let focalLength: Double
    let lensType: String // perspective or fisheye
    let radialR1: Double // R1,2,3, T1,T2: only if perspective
    let radialR2: Double
    let radialR3: Double
    let tangentialT1: Double
    let tangentialT2: Double
    let c: Double        // c,d,e,f: only if fisheye
    let d: Double
    let e: Double
    let f: Double
    let poly0: Double // only for fisheye lens
    let poly1: Double
    let poly2: Double
    let poly3: Double
    let poly4: Double
}

public enum DroneParamsError: String, Error {
    case droneNotFound = "No CCD info for drone"
    case fileReadError = "Error reading drone data file"
    case droneDataError = "Drone data error"
}

public class DroneParams
{
    var droneParamsLastUpdate = Date()
    var droneParamsDate: String?
    var droneCCDParams = [
        // mavic pro
        DroneCCDInfo(makeModel: "djiFC220", ccdWidthMMPerPixel: 6.17/4000.0,
                     ccdHeightMMPerPixel: 4.55/3000.0, widthPixels: 4000.0,
                     heightPixels: 3000.0, comment: "",
                     isThermal: false,
                     focalLength: 0.0,
                     lensType: "persective",
                     radialR1: 0.032984,
                     radialR2: -0.085597,
                     radialR3: 0.0777778,
                     tangentialT1: 0.000409773,
                     tangentialT2: -0.000806846,
                     c: 0,
                     d: 0,
                     e: 0,
                     f: 0,
                     poly0: 0,
                     poly1: 0,
                     poly2: 0,
                     poly3: 0,
                     poly4: 0)
    ]
    
    // load drone params from the target url; this url must be converted
    // to/from bookmark if it was saved from another UIDocumentPicker usage
    // re issue #19
    
    init(jsonURL theURL: URL)
    {
        let fileManager = FileManager.default
        var securityFlag: Bool = false
        
        do {
            
            // re issue #19, make sure we have permission and if not, try to
            // raise our permission level
            if fileManager.isReadableFile(atPath: theURL.path) == false {
                print("DroneParams: not readable so trying to scope resource")
                securityFlag = theURL.startAccessingSecurityScopedResource()
                guard securityFlag == true else {
                    print("I don't have permission to read this drone models json file \(theURL.lastPathComponent)")
                    return
                }
            }
            
            let data = try Data(contentsOf: theURL)
            let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
            //print("Json obj is: \(jsonObject)")
            
            if securityFlag == true {
                theURL.stopAccessingSecurityScopedResource()
            }
            
            if let dictionary = jsonObject as? [String: Any] {
                print("Drone models dictionary created!")
                //let dateFormatter = DateFormatter()
                //let fileDate = convertUnixDateOutputToDate(unixDateOutput: dictionary["lastUpdate"] as! String)
            
                let fileDate = dictionary["lastUpdate"] as! String
            
                let anArray = convertNSArray(array: dictionary["droneCCDParams"] as! NSArray)
            
                if !anArray.isEmpty {
                    print("Setting drone ccd params array \(fileDate)")
                    droneParamsDate = fileDate
                    droneCCDParams = anArray
                    print("\(droneCCDParams.count) drone ccd entries")
                }
                else {
                    print("Empty drone ccd params array \(fileDate)")
                }
            }
            else {
                print("Dictionary not created!")
            }
        }
        catch {
            print("Error reading json file \(error)")
        }
        
    } // init(theURL)
    
    // init with baked in hardcoded values loaded from
    // droneModels.json
    // file that is located in bundled and convert to dictionary
    convenience init()
    {
        
        // adapted from ChatGPT code plus mods
        let filePath = Bundle.main.path(forResource: "droneModels", ofType: "json")
            
        self.init(jsonURL: URL(fileURLWithPath: filePath!))
    }
    
    // init with local data file
    // init(file: dataFile)
    // func readDataFile
    
    // get matching drones; many drone models have make/model collision between
    // main color camera and their secondary thermal camera; this function returns
    // array of matches and caller will have to further match based on pixel width or
    // other distinguishing parameter
    
    func getMatchingDrones(makeModel: String) throws -> [DroneCCDInfo]
    {
        var matchingDrones: [DroneCCDInfo] = []
        
        for drone in droneCCDParams {
            if drone.makeModel.lowercased() == makeModel.lowercased() {
                matchingDrones.append(drone)
            }
        }
        
        if matchingDrones.isEmpty {
            throw DroneParamsError.droneNotFound
        }
        
        return matchingDrones
    }
    
    // given an image width, find the make/model drone with the
    // closest match
    // re issue #38 sometimes we might match the wrong version of a drone
    // that reports same make/model for both thermal and non-thermal
    // so, use drone with nearest width by ratio rather than linear distance
    
    func getMatchingDrone(makeModel: String, targetWidth: Double) throws -> DroneCCDInfo?
    {
        var theDrones: [DroneCCDInfo]
        var smallestDifference = Double.infinity
        var closestDrone: DroneCCDInfo?
        //var difference: Double
        var difference_ratio: Double
        
        print("getMatchingDrone: looking for \(makeModel) \(targetWidth)")
                
        try theDrones = getMatchingDrones(makeModel: makeModel)
        
        for drone in theDrones {
            //difference = fabs(drone.widthPixels - targetWidth)
            difference_ratio = drone.widthPixels / targetWidth
            if difference_ratio < 1.0 {
                difference_ratio = 1 / difference_ratio
            }
            //if difference < smallestDifference {
            if difference_ratio < smallestDifference {
                closestDrone = drone
                //smallestDifference = difference
                smallestDifference = difference_ratio
            }
        }
        
        if closestDrone == nil {
            throw DroneParamsError.droneNotFound
        }
        
        return closestDrone 
    }

    // given makeModel, find drone ccd info
    // convert all makeModel strings to lowercase 
    func lookupDrone(makeModel: String) throws -> DroneCCDInfo
    {
        for drone in droneCCDParams {
            if drone.makeModel.lowercased() == makeModel.lowercased() {
                return drone
            }
        }
        throw DroneParamsError.droneNotFound
    }
    
    func lookupDrone(make: String, model: String) throws -> DroneCCDInfo
    {
        let makeModel:String = make+model
        return try lookupDrone(makeModel: makeModel.lowercased())
    }
    
    func lookupDrone(make: String, model: String, targetWidth: Double) throws -> DroneCCDInfo?
    {
        let makeModel:String = make+model
        return try getMatchingDrone(makeModel: makeModel.lowercased(), targetWidth: targetWidth)
    }
    
    func numberDroneModels() -> Int {
        return droneCCDParams.count
    }
    
    // written by ChatGPT; fixed to add am/pm marker "a"
//    private func convertUnixDateOutputToDate(unixDateOutput: String) -> Date? {
//        let dateFormatter = DateFormatter()
//        dateFormatter.dateFormat = "EEE MMM dd HH:mm:ss a zzz yyyy"
//        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
//
//        return dateFormatter.date(from: unixDateOutput)
//    }
    
    // written by ChatGPT; convert NSArray to an array of structures
    private func convertNSArray(array: NSArray) -> [DroneCCDInfo]
    {
        let structArray = array.compactMap { element -> DroneCCDInfo? in
            if let dictionary = element as? [String: Any],
               let makeModel = dictionary["makeModel"] as? String,
               let ccdWidthMMPerPixel = dictionary["ccdWidthMMPerPixel"] as? String,
               let ccdHeightMMPerPixel = dictionary["ccdHeightMMPerPixel"] as? String,
               let widthPixels = dictionary["widthPixels"] as? Double,
               let heightPixels = dictionary["heightPixels"] as? Double,
               let isThermal = dictionary["isThermal"] as? Bool,
               let focalLength = dictionary["focalLength", default: 0.0] as? Double,
               let lensType = dictionary["lensType"] as? String,
               let radialR1 = dictionary["radialR1", default: 0.0] as? Double,
               let radialR2 = dictionary["radialR2", default: 0.0] as? Double,
               let radialR3 = dictionary["radialR3", default: 0.0] as? Double,
               let tangentialT1 = dictionary["tangentialT1", default: 0.0] as? Double,
               let tangentialT2 = dictionary["tangentialT2", default: 0.0] as? Double,
               let c = dictionary["c", default: 0.0] as? Double,
               let d = dictionary["d", default: 0.0] as? Double,
               let e = dictionary["e", default: 0.0] as? Double,
               let f = dictionary["f", default: 0.0] as? Double,
               let poly0 = dictionary["poly0", default: 0.0] as? Double,
               let poly1 = dictionary["poly1", default: 0.0] as? Double,
               let poly2 = dictionary["poly2", default: 0.0] as? Double,
               let poly3 = dictionary["poly3", default: 0.0] as? Double,
               let poly4 = dictionary["poly4", default: 0.0] as? Double,
               let comment = dictionary["comment"] as? String {
                
                let w = convertDivisonString(str: ccdWidthMMPerPixel)
                let h = convertDivisonString(str: ccdHeightMMPerPixel)
                
                return DroneCCDInfo(
                    makeModel: makeModel,
                    ccdWidthMMPerPixel: w,
                    ccdHeightMMPerPixel: h,
                    widthPixels: widthPixels,
                    heightPixels: heightPixels,
                    comment: comment,
                    isThermal: isThermal,
                    focalLength: focalLength,
                    lensType: lensType,
                    radialR1: radialR1,
                    radialR2: radialR2,
                    radialR3: radialR3,
                    tangentialT1: tangentialT1,
                    tangentialT2: tangentialT2,
                    c: c,
                    d: d,
                    e: e,
                    f: f,
                    poly0: poly0,
                    poly1: poly1,
                    poly2: poly2,
                    poly3: poly3,
                    poly4: poly4
                )
            }
            return nil
        }
        return structArray
        
    } // convertNSArray
    
    // also written by ChatGPT
    func convertDivisonString(str: String) -> Double
    {
        let components = str.split(separator:"/")
        if let numerator = Double(components[0]), let denominator = Double(components[1]) {
            return numerator / denominator
        }
        return 0.0
    }
    
} // DroneParams
