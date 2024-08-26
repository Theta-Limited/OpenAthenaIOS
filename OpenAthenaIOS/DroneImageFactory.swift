// DroneImageFactory.swift
// OpenAthenaIOS
// https://openathena.com
// Created by Bobby Krupczak 8/25/2024

// DroneImage Factory class

import Foundation
import UniformTypeIdentifiers
import ImageIO
import MobileCoreServices
import UTMConversion
import CoreLocation
import mgrs_ios
import UIKit

class DroneImageFactory 
{
    
    // create a drone image or subclass based on the image
    // and manufacturer; kinda a chicken and egg
    // in that we have to fetch some metadata
    // to make the determination
    // not all the EXIFF data is retrieved by
    // the ios/swift libs so we use tiff:Make
    // instead of exif.image.make
    
    public static func createDroneImage(imageURL: URL, vc: ViewController, app: AppDelegate) -> DroneImage?
    {
        do {
            
            let data = try Data(contentsOf: imageURL)
            var image = UIImage(data: data)
            
            let src = CGImageSourceCreateWithData(data as CFData, nil)
            let md = CGImageSourceCopyPropertiesAtIndex(src!,0,nil)! as NSDictionary
            let md2 = CGImageSourceCopyMetadataAtIndex(src!,0,nil)
            let exifDict = md[kCGImagePropertyExifDictionary as String] as? [String: Any]
            let metaData = md.mutableCopy() as! NSMutableDictionary
            let rawMetaData = md2

            //print("createDroneImage: exif dictionary is \(exifDict)")
            
            var makeStr = "unknown"
            if metaData["tiff:Make"] != nil {
                makeStr = metaData["tiff:Make"] as! String
            }
            else {
                if metaData["{TIFF}"] != nil {
                    var dict = metaData["{TIFF}"] as! NSDictionary
                    if dict["Make"] != nil {
                        makeStr = dict["Make"] as! String
                    }
                }
            }
            print("createDroneImage: make is \(makeStr)")
            
            switch makeStr.lowercased() {
            case let str where str.contains("dji"):
                vc.theDroneImage = DroneImageDJI()
            case let str where str.contains("skydio"):
                vc.theDroneImage = DroneImageSkydio()
            case let str where str.contains("parrot"):
                vc.theDroneImage = DroneImageParrot()
            case let str where str.contains("autel"):
                vc.theDroneImage = DroneImageAutel()
            case let str where str.contains("teledyne flir"):
                vc.theDroneImage = DroneImageTeal()
            default: // all else including unknown
                vc.theDroneImage = DroneImage()
            }
            vc.theDroneImage!.rawData = data
            vc.theDroneImage!.theImage = image
            vc.theDroneImage!.name = imageURL.lastPathComponent
            vc.theDroneImage!.droneParams = vc.droneParams
            vc.theDroneImage!.settings = app.settings
            
            // imageView is stored within the DroneImage object
            // caller has to pluck it out and display it if desired
            // imageView.image = image
            vc.theDroneImage!.updateMetaData()
            
            print("createDroneImage: returning drone image")
            
            return vc.theDroneImage
        }
        catch {
            // error!
            print("Loading image resulted in error \(error)")
            //htmlString += "Loading image resulted in error \(error)<br>"
        }
        
        return nil
        
    } // createDroneImage
    
    // create an image from data object not glued into view controllers or app
    // use with unit tests
    
    public static func createDroneImage(data: Data) -> DroneImage?
    {
        var droneImage: DroneImage?
        var image = UIImage(data: data)
        let src = CGImageSourceCreateWithData(data as CFData,nil)
        let md = CGImageSourceCopyPropertiesAtIndex(src!,0,nil)! as NSDictionary
        let md2 = CGImageSourceCopyMetadataAtIndex(src!,0,nil)
        let exifDict = md[kCGImagePropertyExifDictionary as String] as? [String: Any]
        
        let metaData = md.mutableCopy() as! NSMutableDictionary
        var makeStr = "unknown"
        if metaData["tiff:Make"] != nil {
            makeStr = metaData["tiff:Make"] as! String
        }
        else {
            if metaData["{TIFF}"] != nil {
                var dict = metaData["{TIFF}"] as! NSDictionary
                if dict["Make"] != nil {
                    makeStr = dict["Make"] as! String
                }
            }
        }
        print("createDroneImage(data): make is \(makeStr)")
        
        switch makeStr.lowercased() {
        case let str where str.contains("dji"):
            droneImage = DroneImageDJI()
        case let str where str.contains("skydio"):
            droneImage = DroneImageSkydio()
        case let str where str.contains("parrot"):
            droneImage = DroneImageParrot()
        case let str where str.contains("autel"):
            droneImage = DroneImageAutel()
        case let str where str.contains("teledyne flir"):
            droneImage = DroneImageTeal()
        default: // all else including unknown
            droneImage = DroneImage()
        }
        
        droneImage!.theImage = image
        droneImage!.rawData = data
        droneImage!.updateMetaData()
        
        return droneImage
    }
    
} // DroneImageFactory
