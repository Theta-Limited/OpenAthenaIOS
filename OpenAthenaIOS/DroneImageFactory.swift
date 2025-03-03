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
            
            var modelStr = "unknown"
            if metaData["tiff:Model"] != nil {
                modelStr = metaData["tiff:Model"] as! String
            }
            else {
                if metaData["{TIFF}"] != nil {
                    var dict = metaData["{TIFF}"] as! NSDictionary
                    if dict["Model"] != nil {
                        modelStr = dict["Model"] as! String
                    }
                }
            }

            // re issue #62 clean up camera make parsing for some Autel quirks
            if makeStr.caseInsensitiveCompare("Camera") == .orderedSame && modelStr.starts(with: "XL") {
                makeStr = "Autel Robotics"
            }
            print("createDroneImage: make is \(makeStr)")
            
            switch makeStr.lowercased() {
            case let str where str.contains("dji"), let str where str.contains("hasselblad"):
                // re issue #59, hasselblad is DJI
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
            
            // try to find drone ccd info from drone database
            // re issue #60 do it here and display warning
            do {
                var ccdInfo: DroneCCDInfo?
                
                print("DromeImageFactory: looking up drone info for width \(vc.theDroneImage!.theImage!.size.width)")
                print("DroneImageFactory: image scale is \(vc.theDroneImage!.theImage!.scale)")
                var width = vc.theDroneImage!.theImage!.size.width * vc.theDroneImage!.theImage!.scale
                print("DroneImageFactory: calculated width is \(width)")
                print("DroneImageFactory: cg image width is \(md[kCGImagePropertyPixelWidth] as? Int)")
                print("DroneImageFactory exif width \(exifDict?[kCGImagePropertyExifPixelXDimension as String] as? Int)")

                let tiffProperties = md[kCGImagePropertyTIFFDictionary] as? [CFString: Any]
                print("DroneImageFactory: tiff width is \(tiffProperties?[kCGImagePropertyPixelWidth])")
                
                print("DroneImageFactory: cg width is \(image?.cgImage?.width)")
                
                ccdInfo = try vc.droneParams?.lookupDrone(make: vc.theDroneImage!.getCameraMake(),
                                                                            model: vc.theDroneImage!.getCameraModel(),
                                                                            targetWidth: vc.theDroneImage!.theImage!.size.width)
                vc.theDroneImage!.ccdInfo = ccdInfo
            }
            catch {
                vc.theDroneImage!.ccdInfo = nil
            }
            
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
        case let str where str.contains("dji"), let str where str.contains("hasselblad"):
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
