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

struct DroneCCDInfo {
    let makeModel: String  // also the dictionary key
    let ccdWidthMMPerPixel: Double
    let ccdHeightMMPerPixel: Double
    let widthPixels: Double
    let heightPixels: Double
    let comment: String
}

enum DroneParamsError: String, Error {
    case droneNotFound = "No CCD info for drone"
    case fileReadError = "Error reading drone data file"
    case droneDataError = "Drone data error"
}

public class DroneParams
{
    var droneParamsLastUpdate = Date()
    var droneParamsDate: Date?
    var droneCCDParams = [
        // mavic pro
        DroneCCDInfo(makeModel: "djiFC220", ccdWidthMMPerPixel: 6.17/4000.0,
                                 ccdHeightMMPerPixel: 4.55/3000.0, widthPixels: 4000.0,
                                 heightPixels: 3000.0, comment: ""),
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
                print("Dictionary created!")
                let dateFormatter = DateFormatter()
                let fileDate = convertUnixDateOutputToDate(unixDateOutput: dictionary["lastUpdate"] as! String)
                let anArray = convertNSArray(array: dictionary["droneCCDParams"] as! NSArray)
                if !anArray.isEmpty {
                    print("Setting drone ccd params array \(fileDate)")
                    droneParamsDate = fileDate
                    droneCCDParams = anArray
                    print("\(droneCCDParams.count) drone ccd entries")
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
    private func convertUnixDateOutputToDate(unixDateOutput: String) -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEE MMM dd HH:mm:ss a zzz yyyy"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        
        return dateFormatter.date(from: unixDateOutput)
    }
    
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
               let comment = dictionary["comment"] as? String {
                let w = convertDivisonString(str: ccdWidthMMPerPixel)
                let h = convertDivisonString(str: ccdHeightMMPerPixel)
                return DroneCCDInfo(
                    makeModel: makeModel,
                    ccdWidthMMPerPixel: w,
                    ccdHeightMMPerPixel: h,
                    widthPixels: widthPixels,
                    heightPixels: heightPixels,
                    comment: comment)
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
