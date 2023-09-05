//
//  DroneParams.swift
//  OpenAthenaIOS
//  https://github.com/Theta-Limited/OpenAthenaIOS
//  https://openathena.com//
//  Created by Bobby Krupczak on 5/26/23.
//  Encapsulate drone parameter data in this class
//  both for static out of box and for
//  updating via local data file or network download

// for Drones, we are tracking make, model, width and height (in mm) of a pixel
// and the width-pixels and height-pixels of the drone's specific CCD/CMOS sensor
// ccd_width(mm) / width_pixels = pixel_width(mm/pixel)
// width-pixels, height-pixels, width, height
// makeModel is concatenation of make and model (e.g. DJIFC220)

import Foundation

public struct DroneCCDInfo {
    let makeModel: String  // also the dictionary key
    let ccdWidthMMPerPixel: Double
    let ccdHeightMMPerPixel: Double
    let widthPixels: Double
    let heightPixels: Double
    let comment: String
    let isThermal: Bool
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
    
    // init with baked in hardcoded values loaded from
    // droneModels.json
    // file that is located in bundled and convert to dictionary
    init()
    {
        do {
            // adapted from ChatGPT code plus mods
            let filePath = Bundle.main.path(forResource: "droneModels", ofType: "json")
            let data = try Data(contentsOf: URL(fileURLWithPath: filePath!))
            let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
            //print("Json obj is: \(jsonObject)")
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
    func getMatchingDrone(makeModel: String, targetWidth: Double) throws -> DroneCCDInfo?
    {
        var theDrones: [DroneCCDInfo]
        var smallestDifference = Double.infinity
        var closestDrone: DroneCCDInfo?
        var difference: Double
                
        try theDrones = getMatchingDrones(makeModel: makeModel)
        
        for drone in theDrones {
            difference = fabs(drone.widthPixels - targetWidth)
            if difference < smallestDifference {
                closestDrone = drone
                smallestDifference = difference
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
