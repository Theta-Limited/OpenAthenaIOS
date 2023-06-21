//
//  DroneImage.swift
//  OpenAthenaIOS
//  https://github.com/rdkgit/OpenAthenaIOS
//  https://openathena.com
//  Created by Bobby Krupczak on 2/4/23.
//
//  Class to hold the various pieces parts of the
//  drone image we are examining

import Foundation
import UIKit

enum DroneImageError: String, Error {
    case MetaDataKeyNotFound = "Meta data key not found"
    case NoMetaData = "No meta data"
    case NoMetaGPSData = "No GPS data"
    case NoImage = "No image"
    case NoRawData = "No raw data"
    case NoXmpMetaData = "No XMP meta data"
    case MissingMetaDataKey = "Missing meta data key"
    case MissingCCDInfo = "Missing CCD info for this image"
}

extension Data {
    var bytes: [UInt8] {
        return [UInt8](self)
    }
}

// use measurement framework for converting between degrees and radians
// https://stackoverflow.com/questions/29179692/how-can-i-convert-from-degrees-to-radians

extension Double {
    var radians: Double { return Measurement(value: self, unit: UnitAngle.degrees).converted(to: UnitAngle.radians).value }
    var degrees: Double { return Measurement(value: self, unit: UnitAngle.radians).converted(to: UnitAngle.degrees).value }
}

public class DroneImage {
    var name: String?
    var url: URL?
    var theImage: UIImage?
    //var metaData: [AnyHashable:Any]
    var metaData: NSMutableDictionary?
    var rawMetaData: CGImageMetadata?
    var rawData: Data?
    var xmpDataRead: Bool = false
    var xmlString: String?
    var targetXprop: CGFloat = 0.5
    var targetYprop: CGFloat = 0.5
    var ccdInfo: DroneCCDInfo?
    var xmlStringCopy: String?
    
    //init(fromImage image: UIImage, withMetaData data: [AnyHashable:Any]) {
    init(suggestedName aName: String, fromImage image: UIImage,
         withMetaData md: NSMutableDictionary,
         withRawMetaData rmd: CGImageMetadata, withRawData rd: Data) {
        
        name = aName
        theImage = image
        metaData = md
        url = nil
        rawMetaData = rmd
        rawData = rd
        xmpDataRead = false
    }
    
    init () {
        name = nil
        url = nil
        theImage = nil
        metaData = nil
        rawMetaData = nil
        rawData = nil
        xmpDataRead = false
    }
    
    // update meta data
    public func updateMetaData()
    {
        let src = CGImageSourceCreateWithData(rawData! as CFData,nil)
        
        // first cast to NSDictionary then use mutableCopy to finish casting/converting
        // Line below worked on ios 16 but not on 14.  Fix for 14 and higher
        //let md = CGImageSourceCopyPropertiesAtIndex(src!,0,nil) as! NSMutableDictionary
        
        let md = CGImageSourceCopyPropertiesAtIndex(src!,0,nil)! as NSDictionary
        let md2 = CGImageSourceCopyMetadataAtIndex(src!,0,nil)
        
        metaData = md.mutableCopy() as! NSMutableDictionary
        rawMetaData = md2
        parseXmpMetaDataNoError()
    }
    
    // Skydio, DJI, Parrot, Autell
    // refer to OpenAthenaAndroid MainActivity
    // HandleXXX method where XXX is drone make
    
    // Key {TIFF}
    // Val . . . Make = DJI;   Model = XXXX; . . . .
    // Key {Exif}
    // Val DigitalZoomRatio
    // Key {GPS}
    //
    
    // get latitude (-90,90)
    // exif:GPSLatitude
    // 63,31.884N
    // or use pre-digested metadata that
    // parses for us
    
    // digital zoom, optical zoom, etc
    public func getZoom() -> Double {
        var zoom = 1.00
        var dict: NSDictionary
        
        //print("getZoom: starting")
        
        //print("getZoom: metadata is ")
        //print(metaData)
        
        //print("getZoom: rawMetaData")
        //print(rawMetaData)
        
        if metaData!["DigitalZoomRatio"] != nil {
            print("getZoom: found DigitalZoomRatio directly in metadata")
            zoom = (metaData!["DigitalZoomRatio"] as! NSString).doubleValue
        }
        
        if metaData!["Photo:DigitalZoomRatio"] != nil {
            print("getZoom: found Photo:DigitalZoomRatio")
            zoom = metaData!["Photo:DigitalZoomRatio"] as! Double
        }
        
        // this is where we would find Exif:DigitalZoomRatio
        // most likely; some drones put 0.0 if no digital
        // zoom; if 0, return 1.0
        if metaData!["{Exif}"] != nil {
            //print("getZoom: found Exif dictionary")
            dict = metaData!["{Exif}"] as! NSDictionary
            if dict["DigitalZoomRatio"] != nil {
                print("getZoom: found DigitalZoomRatio inside Exif dict")
                zoom = dict["DigitalZoomRatio"] as! Double
            }
        }
        
        // if zoom is 0.0, set it to 1.0
        if zoom == 0.0 {
            print("getZoom: Correcting zoom 0.0 to 1.0")
            zoom = 1.0
        }
        return zoom
    }
    
    public func getRoll() throws -> Double
    {
        // drone-skydio:CameraOrientationNED:Roll
        // dji-drone:GimballRollDegree
        // drone:GimbalRollDegree
        // Camera:Roll
        
        if metaData == nil {
            throw DroneImageError.NoMetaData
        }
        
        // check for drone specific latitude meta data
        if xmpDataRead == false {
            parseXmpMetaDataNoError()
        }
        
        if (metaData!["drone-skydio:CameraOrientationNED:Roll"] != nil)  {
            return (metaData!["drone-skydio:CameraOrientationNED:Roll"] as! NSString).doubleValue
        }
        if (metaData!["drone-dji:GimbalRollDegree"] != nil)  {
            return (metaData!["drone-dji:GimbalRollDegree"] as! NSString).doubleValue
        }
        if (metaData!["drone:GimbalRollDegree"] != nil)  {
            return (metaData!["drone:GimbalRollDegree"] as! NSString).doubleValue
        }
        if (metaData!["Camera:Roll"] != nil)  {
            return (metaData!["Camera:Roll"] as! NSString).doubleValue
        }
        
        print("getRoll: missing metadata key")
        throw DroneImageError.MissingMetaDataKey
    }
    
    public func getLatitude() throws -> Double {
        var lat = 0.0
        var direction = 1.0
        var gpsInfo: NSDictionary
        
        if metaData == nil {
            throw DroneImageError.NoMetaData
        }
        
        // check for drone specific latitude meta data
        if xmpDataRead == false {
            parseXmpMetaDataNoError()
        }
        
        if (metaData!["drone-dji:GpsLatitude"] != nil)  {
            lat = (metaData!["drone-dji:GpsLatitude"] as! NSString).doubleValue
            return lat
        }
        if metaData!["drone-skydio:Latitude"] != nil {
            lat = (metaData!["drone-skydio:Latitude"] as! NSString).doubleValue
            return lat
        }
        if (metaData!["drone:GpsLatitude"] != nil)  {
            lat = (metaData!["drone:GpsLatitude"] as! NSString).doubleValue
            return lat
        }
        
        // fallback to exif gps data and handle direction
        if metaData!["{GPS}"] == nil {
            throw DroneImageError.NoMetaGPSData
        }
        gpsInfo = metaData!["{GPS}"] as! NSDictionary
        if gpsInfo["Latitude"] == nil {
            throw DroneImageError.MissingMetaDataKey
        }
        
        lat = gpsInfo["Latitude"] as! Double
        
        if gpsInfo["LatitudeRef"] as! String == "N" {
            direction = 1.0
        }
        else {
            direction = -1.0
        }
        
        return direction * lat
    }
    
    // get longitude (-180,180)
    // exif:GPSLongitude
    // 19,30.672W
    // or use digested metadata which
    // handles the parsing for us
    public func getLongitude() throws -> Double {
        
        var lon = 0.0
        var direction = 1.0
        var gpsInfo: NSDictionary
        
        if metaData == nil {
            throw DroneImageError.NoMetaData
        }
        // check for drone specific longitude data
        if xmpDataRead == false {
            parseXmpMetaDataNoError()
        }
        if metaData!["drone-dji:GpsLongitude"] != nil {
            lon = (metaData!["drone-dji:GpsLongitude"] as! NSString).doubleValue
            return lon
        }
        if metaData!["drone-skydio:Longitude"] != nil {
            lon = (metaData!["drone-skydio:Longitude"] as! NSString).doubleValue
            return lon
        }
        if metaData!["drone:GpsLongitude"] != nil {
            lon = (metaData!["drone:GpsLongitude"] as! NSString).doubleValue
            return lon
        }
        // typo in autel drone gps metadata
        if metaData!["drone:GpsLongtitude"] != nil {
            lon = (metaData!["drone:GpsLongtitude"] as! NSString).doubleValue
            return lon
        }
        
        // fall back to exif gps data and check for direction
        if metaData!["{GPS}"] == nil {
            throw DroneImageError.NoMetaGPSData
        }
        gpsInfo = metaData!["{GPS}"] as! NSDictionary
        if gpsInfo["Longitude"] == nil {
            throw DroneImageError.MissingMetaDataKey
        }
        lon = gpsInfo["Longitude"] as! Double
        
        if gpsInfo["LongitudeRef"] as! String == "W" {
            direction = -1.0
        }
        
        return direction * lon
    }
    
    // get altitude meters
    // use GPS data from digested metadata
    // GPS->Altitude or drone specific AbsoluteAltitude
    // For older Autel drones, check if GPSAltitudeRef exists and is 1
    // If so, its below sea level and we should negate the value
    // return altitude in WGS84
    
    public func getAltitude() throws -> Double {
        
        var alt = 0.0
        var gpsInfo: NSDictionary
        
        if metaData == nil {
            throw DroneImageError.NoMetaData
        }
        
        // check for drone specific altitude data XXX
        // which altitude?  absolute or relative
        if xmpDataRead == false {
            parseXmpMetaDataNoError()
        }
        if metaData!["drone-dji:AbsoluteAltitude"] != nil {
            alt = (metaData!["drone-dji:AbsoluteAltitude"] as! NSString).doubleValue
            //return alt
        }
        if metaData!["drone:AbsoluteAltitude"] != nil {
            alt = (metaData!["drone:AbsoluteAltitude"] as! NSString).doubleValue
            //return alt
        }
        if metaData!["drone-skydio:AbsoluteAltitude"] != nil {
            alt = (metaData!["drone-skydio:AbsoluteAltitude"] as! NSString).doubleValue
            //return alt
        }
        
        // fallback to regular exif gps altitude data
        
        
        // metadata that is parsed by CGImage functions is
        // already in NSCFNumber so it can be typecast to Double
        // directly
        
        // if alt is still 0.0, grab here
        var altFromExif = false
        if alt == 0.0 {
            if metaData!["{GPS}"] == nil {
               throw DroneImageError.NoMetaGPSData
            }
            gpsInfo = metaData!["{GPS}"] as! NSDictionary
            if gpsInfo["Altitude"] == nil {
                throw DroneImageError.MissingMetaDataKey
            }
            alt = gpsInfo["Altitude"] as! Double
            altFromExif = true
            
            // re autel drones, check altitude ref for 1 meaning below sea level XXX
            if gpsInfo["GPSAltitudeRef"] != nil {
                let ref = gpsInfo["GPSAltitudeRef"] as! Int
                //print("GPSAltitude ref is \(ref)")
                if ref == 1 {
                    alt = -1.0 * alt
                }
            }
            if metaData!["exif:GPSAltitudeRef"] != nil {
                let ref = (metaData!["exif:GPSAltitudeRef"] as! NSString).intValue
                //print("GPS exif:GPSAltitudeRef is \(ref)")
                if ref == 1 {
                    alt = -1.0 * alt
                }
            }
        }
        
        if alt == 0.0 {
            throw DroneImageError.NoMetaGPSData
        }
        
        // look for metadata drone:RtkFlag
        var rtkFlag: Bool = false
        if metaData!["drone:RtkFlag"] != nil {
            rtkFlag = true
        }
        if metaData!["drone-dji:RtkFlag"] != nil {
            rtkFlag = true
        }
        if xmlStringCopy?.lowercased().contains("rtkflag") == true {
            rtkFlag = true
        }
        
        // now, depending on drone type/make, convert from EGM96 to WGS84 if necessary
        var offset:Double = 0.0
        do {
            
            // make, model, tag
            let make = try getCameraMake()
            let model = try getCameraModel()
            // DJI, skydio are EGM96
            // autel assuming EGM96 unless old autel firm
            // DJI, autel if tag rtkflag then its already in WGS84
            
            if rtkFlag == true {
                return alt // already in WGS84
            }
            
            if altFromExif == true {
                return alt // already in WGS84
            }
            
            // if parrot anafiai is in WGS84
            if model.lowercased().contains("anafiai") == true {
                
                // Location altitude of where the photo was taken in meters expressed
                // as a fraction (e.g. “4971569/65536”) On ANAFI 4K/Thermal/USA, this
                // is the drone location with reference to the EGM96 geoid (AMSL); on
                // ANAFI Ai with firmware < 7.4, this is the drone location with with
                // reference to the WGS84 ellipsoid; on ANAFI Ai with firmware >= 7.4,
                // this is the front camera location with reference to the WGS84
                // ellipsoid https://developer.parrot.com/docs/groundsdk-tools/photo-metadata.html
                
                return alt // already in WGS84
            }
            
            // all autel drones return altitude in WGS84
            if make.lowercased().contains("autel") == true {
                return alt // already in WGS84
            }
            
            // determine EGM96 offset now that we've eliminated any WGS84 altitudes
            
            offset = try EGM96Geoid.getOffset(lat: getLatitude(), lng: getLongitude())
        }
        catch {
            throw error
        }
        
        // if we get here, its EGM96; convert to WGS84
        
        alt = alt - offset
        return alt
    }
    
    // camera/gimbal pitch degree or theta
    // GimbalPitchDegree is the Taylor Brian absolute pitch angle of the camera,
    // but measured increasing upward. OpenAthena is the opposite,
    // increasing downwards; so, take abs/fabs of meta data value
    
    public func getGimbalPitchDegree() throws -> Double {
        var theta: Double
        
        if metaData == nil {
            throw DroneImageError.NoMetaData
        }
        
        if xmpDataRead == false {
            parseXmpMetaDataNoError()
        }
        
        if metaData!["drone-dji:GimbalPitchDegree"] != nil {
            theta = (metaData!["drone-dji:GimbalPitchDegree"] as! NSString).doubleValue
            return fabs(theta)
        }
        if metaData!["drone-skydio:CameraOrientationNED:Pitch"] != nil {
            theta = (metaData!["drone-skydio:CameraOrientationNED:Pitch"] as! NSString).doubleValue
            return fabs(theta)
        }
        if metaData!["drone:GimbalPitchDegree"] != nil {
            theta = (metaData!["drone:GimbalPitchDegree"] as! NSString).doubleValue
            return fabs(theta)
        }
        if metaData!["Camera:Pitch"] != nil {
            theta = (metaData!["Camera:Pitch"] as! NSString).doubleValue
            return fabs(theta)
        }
        if metaData!["drone-parrot:CameraPitchDegree"] != nil {
            theta = (metaData!["drone-parrot:CameraPitchDegree"] as! NSString).doubleValue
            return fabs(theta)
        }
        throw DroneImageError.MissingMetaDataKey
    }
    
    // camera/gimbal yaw degree or azimuth
    public func getGimbalYawDegree() throws -> Double {
        
        var az: Double
        
        if metaData == nil {
            throw DroneImageError.NoMetaData
        }
        
        // check for drone specific azimuth data
        if xmpDataRead == false {
            parseXmpMetaDataNoError()
        }
        
        if metaData!["drone-dji:GimbalYawDegree"] != nil {
            az = (metaData!["drone-dji:GimbalYawDegree"] as! NSString).doubleValue
            return az.truncatingRemainder(dividingBy: 360.0)
        }
        if metaData!["drone:GimbalYawDegree"] != nil {
            az = (metaData!["drone:GimbalYawDegree"] as! NSString).doubleValue
            return az.truncatingRemainder(dividingBy: 360.0)
        }
        if metaData!["Camera:Yaw"] != nil {
            az = (metaData!["Camera:Yaw"] as! NSString).doubleValue
            return az.truncatingRemainder(dividingBy: 360.0)
        }
        if metaData!["drone-parrot:CameraYawDegree"] != nil {
            az = (metaData!["drone-parrot:CameraYawDegree"] as! NSString).doubleValue
            return az.truncatingRemainder(dividingBy: 360.0)
        }
        if metaData!["drone-skydio:CameraOrientationNED:Yaw"] != nil {
            az = (metaData!["drone-skydio:CameraOrientationNED:Yaw"] as! NSString).doubleValue
            return az.truncatingRemainder(dividingBy: 360.0)
        }
        
        throw DroneImageError.MissingMetaDataKey
    }
    
    // look at exif/metadata to see who maker is
    // or XMP data
    // Exif.Image.Make == DJI
    // tiff:Make == DJI
    public func isDroneImage() -> Bool {
        
        var make: String
        
        do {
            try make = getCameraMake()
        }
        catch {
            return false
        }
        
        switch make.lowercased() {
        case "dji":
            return true
        case "parrot":
            return true
        case "autel robotics":
            return true
        case "skydio":
            return true
        default:
            return false
        }
    }
    
    public func getFocalLength() throws -> Double
    {
        if metaData == nil {
            throw DroneImageError.NoMetaData
        }
        if xmpDataRead == false {
            parseXmpMetaDataNoError()
        }
        if metaData!["Exif:FocalLength"] != nil {
            return metaData!["Exif:FocalLength"] as! Double
        }
        
        if metaData!["{Exif}"] != nil {
            var dict = metaData!["{Exif}"] as! NSDictionary
            if dict["FocalLength"] != nil {
                return dict["FocalLength"] as! Double
            }
        }

        print("getFocalLength: metadata key not found")
        throw DroneImageError.MetaDataKeyNotFound
    }
    
    public func getFocalLengthIn35mm() throws -> Double
    {
        if metaData == nil {
            throw DroneImageError.NoMetaData
        }
        if xmpDataRead == false {
            parseXmpMetaDataNoError()
        }
        if metaData!["Exif:FocalLenIn35mmFilm"] != nil {
            return metaData!["Exif:FocalLenUb35mmFilm"] as! Double
        }
        if metaData!["{Exif}"] != nil {
            var dict = metaData!["{Exif}"] as! NSDictionary
            if dict["FocalLenIn35mmFilm"] != nil {
                return dict["FocalLenIn35mmFilm"] as! Double
            }
        }
        if metaData!["Exif:FocalLengthIn35mmFilm"] != nil {
            return metaData!["Exif:FocalLenUb35mmFilm"] as! Double
        }
        if metaData!["{Exif}"] != nil {
            var dict = metaData!["{Exif}"] as! NSDictionary
            if dict["FocalLengthIn35mmFilm"] != nil {
                return dict["FocalLengthIn35mmFilm"] as! Double
            }
        }
        if metaData!["Exif:FocalLengthIn35mmFormat"] != nil {
            return metaData!["Exif:FocalLenUb35mmFormat"] as! Double
        }
        if metaData!["{Exif}"] != nil {
            var dict = metaData!["{Exif}"] as! NSDictionary
            if dict["FocalLengthIn35mmFormat"] != nil {
                return dict["FocalLengthIn35mmFormat"] as! Double
            }
        }
        
        print("getFocalLengthIn354mm metadata key not found")
        
        throw DroneImageError.MetaDataKeyNotFound
    }
    
    // camera model
    public func getCameraModel() throws -> String
    {
        var dict: NSDictionary
        
        if metaData == nil {
            throw DroneImageError.NoMetaData
        }
        
        if xmpDataRead == false {
            parseXmpMetaDataNoError()
        }
        
        // first look for {TIFF}
        dict = metaData!["{TIFF}"] as! NSDictionary
        if dict["Model"] != nil {
            return dict["Model"] as! String
        }
        
        if metaData!["tiff:Model"] != nil {
            return metaData!["tiff:Model"] as! String
        }
        if metaData!["drone-parrot:ModelID"] != nil {
            return metaData!["drone-parrot:ModelID"] as! String
        }
        if metaData!["Camera:ModelType"] != nil {
            return metaData!["Camera:ModelType"] as! String
        }
        
        return "unknown"
    }
    
    // lookup tiff:Make
    public func getCameraMake() throws -> String {
        
        var dict: NSDictionary
        
        if metaData == nil {
            throw DroneImageError.NoMetaData
        }
        
        if xmpDataRead == false {
            parseXmpMetaDataNoError()
        }
        if metaData!["tiff:Make"] != nil {
            return metaData!["tiff:Make"] as! String
        }
        
        if metaData!["{TIFF}"] == nil {
            throw DroneImageError.NoMetaData
        }
        
        dict = metaData!["{TIFF}"] as! NSDictionary
        
        if dict["Make"] == nil {
            throw DroneImageError.NoMetaData
        }
        
        return dict["Make"] as! String
    }
    
    // if we have drone CCD info and user has touched somewhere inside image
    // for new target, calculate new angles
    // first get the intrinsic matrix
    
    private func getIntrinsicMatrix() throws -> [Double] {
        
        // if ccd info not known
        if ccdInfo != nil {
            print("getIntrinsicMatrix: known CCD")
            return try getIntrinsicMatrixFromKnownCCD()
        }
        return try getIntrinsicMatrixFromExif35mm()
    }
    
    // get instrinsic matrix estimate from exif data
    private func getIntrinsicMatrixFromExif35mm() throws -> [Double]
    {
        var matrix = [Double](repeating: 0.0, count: 9)
        
        var focalLength35mmEquiv = try getFocalLengthIn35mm()
        var zoomRatio = getZoom()
        var imageWidth = theImage!.size.width
        var imageHeight = theImage!.size.height
        
        // aspect ratio of CCD, not the image; assuming 4:3 here
        // this will be wrong if sensor is not 4:3
        var ccdAspectRatio: Double = 4.0/3.0
        
        // focal length in pixels
        var alphaX = (imageWidth * zoomRatio) * focalLength35mmEquiv / 36.0
        var alphaY = alphaX / ccdAspectRatio
        matrix[0] = alphaX // focal length in X direction in pixels
        matrix[1] = 0.0 // gamma, the skew coefficient between x, y axis; often 0
        matrix[4] = alphaY // focal length in Y direction in pixels

        matrix[2] = imageWidth / 2.0  // cx
        matrix[3] = 0.0
        matrix[5] = imageHeight / 2.0 // cy
        matrix[6] = 0.0
        matrix[7] = 0.0
        matrix[8] = 1.0
        
        print("getIntrinsicMatrixFromExif35mm: returning")
        
        return matrix
    }
    
    private func getIntrinsicMatrixFromKnownCCD() throws -> [Double]
    {
        var matrix = [Double](repeating: 0.0, count: 9)
        var f: Double
        
        if ccdInfo == nil {
            throw DroneImageError.MissingCCDInfo
        }
        
        do {
            f = try getFocalLength()
        }
        catch {
            // need to test this
            return try getIntrinsicMatrixFromExif35mm()
        }
        
        var zoomRatio = getZoom()
        var imageWidth = theImage!.size.width
        var imageHeight = theImage!.size.height
        var pixelAspectRatio = ccdInfo!.ccdWidthMMPerPixel / ccdInfo!.ccdHeightMMPerPixel
        
        var scaleRatio = imageWidth * zoomRatio / ccdInfo!.widthPixels // ratio current size : original size on x axis
        var alphaX = f / ccdInfo!.ccdWidthMMPerPixel // focal length in x direction in pixels
        alphaX = alphaX * scaleRatio
        var alphaY = alphaX / pixelAspectRatio // focal length in y direction in pixels
        alphaY = alphaY * scaleRatio
        
        matrix[0] = alphaX
        matrix[1] = 0.0 // gamma, skew coefficient between x and y axis, often 0
        matrix[2] = imageWidth / 2.0 // cx
        matrix[3] = 0.0
        matrix[4] = alphaY
        matrix[5] = imageHeight / 2.0 // cy
        matrix[6] = 0.0
        matrix[7] = 0.0
        matrix[8] = 1.0
        
        return matrix
    }
    
    // get ray angles in degrees offset from principal point (0.5,0.5)
    private func getRayAnglesFromImagePixel(x: Double, y: Double) throws -> (Double,Double)
    {
        print("getRayAnglesFromImagePixel: starting")
        
        var matrix = try getIntrinsicMatrix()
        
        print("getRayAnglesFromImagePixel: got intrinsic matrix")
        
        let fx = matrix[0]
        let fy = matrix[4]
        let cx = matrix[2]
        let cy = matrix[5]
        
        let pixelX = x - cx
        let pixelY = y - cy
                
        var azimuth: Double = atan2(pixelX,fx)
        var elevation: Double = atan2(pixelY, fy)
        azimuth = azimuth.degrees
        elevation = elevation.degrees
        
        let roll = try getRoll()
        
        print("getRayAnglesFromImagePixel: roll is \(roll)")
        
        (azimuth,elevation) = correctRayAnglesForRoll(psi: azimuth, theta: elevation, roll: roll)
        
        print("getRayAnglesFromImagePixel: returning corrected az and elevation")
        
        return (azimuth,elevation)
    }
    
    // for an image taken where camera lateral axis is not parallel to ground (e.g. roll), express ray angle
    // in terms of a frame of reference which is parallel to ground
    // while most drones try to keep the camera gimball lateral axis parallel to ground, this cannot be assumed.
    // therefore, this function rotates the 3d angle by the same amount and direction as the roll of the camera
    
    private func correctRayAnglesForRoll(psi: Double, theta: Double, roll: Double) -> (Double,Double)
    {
        var thetaRad  = -1.0 * theta // convert from OA notation to Tait-Bryan aircraft notation down is negative
        thetaRad = thetaRad.radians
        var psiRad = psi.radians
        var rollRad = roll.radians
        
        // convert tait-bryan angles to unit vector
        // +x is forward
        // +y is rightward
        // +z is downward
        
        let x = cos(thetaRad) * cos(psiRad)
        let y = cos(thetaRad) * sin(psiRad)
        let z = sin(thetaRad)
        
        let rotationMatrix = [
            [ 1.0, 0.0, 0.0 ],
            [ 0.0, cos(rollRad), -1.0*sin(rollRad)],
            [ 0.0, sin(rollRad), cos(rollRad)]
        ]
        
        // rotate the unix vector back to correct for observer's roll
        let rotatedVector = [
            rotationMatrix[0][0] * x + rotationMatrix[0][1] * y + rotationMatrix[0][2] * z,
            rotationMatrix[1][0] * x + rotationMatrix[1][1] * y + rotationMatrix[1][2] * z,
            rotationMatrix[2][0] * x + rotationMatrix[2][1] * y + rotationMatrix[2][2] * z
        ]
        
        var correctedPsiRad = atan2(rotatedVector[1], rotatedVector[0])
        var correctedThetaRad = atan2(rotatedVector[2], sqrt(rotatedVector[0]*rotatedVector[0] + rotatedVector[1]*rotatedVector[1] ))
        
        var correctedPsi = correctedPsiRad.degrees
        var correctedTheta = correctedThetaRad.degrees
        
        // convert from tait-bryan notation back to OA notation (down is positive)
        correctedTheta = -1.0 * correctedTheta
        
        return (correctedPsi,correctedTheta)
    }
    
    // return meta data value, if present, as string
    public func getMetaDataValue(key: String) throws -> String
    {
        if xmpDataRead == false {
            parseXmpMetaDataNoError()
        }
        if metaData == nil {
            throw DroneImageError.NoMetaData
        }
        if metaData![key] != nil {
            return metaData![key] as! String
        }
        throw DroneImageError.MetaDataKeyNotFound
    }
    
    // Given an angle in radians, return angle 0 <= angle < 2*pi
    public static func normalizeRadians(inAngle: Double ) -> Double
    {
        var outAngle = inAngle
        
        while outAngle < 0.0 {
            outAngle +=  2*Double.pi
        }
        while outAngle >= (2.0*Double.pi) {
            outAngle -= 2.0*Double.pi
        }
        return outAngle
    }
    
    // given angle in degrees, return angle 0 <= angle < 360
    public static func normalizeDegrees(inAngle: Double) -> Double {
        var inAngle = inAngle
        while inAngle >= 360.0 {
            inAngle -= 360.0
        }
        while inAngle < 0.0 {
            inAngle += 360.0
        }
        return inAngle
    }
    
    // given an azmith measured starting at north, increasing clockwise,
    // return same angle on mathematical unit circle starting at East
    // and increasing counter-clockwise
    
    public static func azimuthToUnitCircleRad(inAngle: Double) -> Double
    {
        var radDirection: Double = -1.0 * inAngle
        radDirection += 0.5 * Double.pi
        radDirection = normalizeRadians(inAngle: radDirection)
        return radDirection
    }
    
    // given lat, determine distance from center of the WGS84 reference ellipsoid
    // to the surface; lon not used for this calculation
    // return radius of the WGS84 reference ellipsoid at given latitude in meters
    
    public static func radius_at_lat_lon(inLat: Double, inLon: Double) -> Double
    {
        var lat = inLat
        lat = lat.radians

        let A: Double = 6378137.0 // equatorial radius
        let B: Double = 6356752.0 // polar radius
        
        var r: Double = pow(A*A*cos(lat),2) + pow(B*B*sin(lat),2)
        r /= (pow(A*cos(lat),2) + pow(B*sin(lat),2))
        r = sqrt(r)
        return r
    }
    
    // given point, distance, and heading (azimuth format), return new point
    // the specified distance along the defined circle
    // lat1,lon1 starting point
    // d distance to travel along the great circle in meteres
    // radAzimuth heading of direction of travel for great circle,
    //   in radians, starting North at 0 and increasing clockwise
    // alt altitude above surface of WGS84 reference ellipsoid in meters
    // return double lat/lon pair representing point at end of great circle in d meters away
    
    public static func inverse_haversine(lat1: Double, lon1: Double, d: Double, radAzimuth: Double, alt: Double) -> (Double,Double)
    {
        var lat1 = lat1
        var lon1 = lon1
        
        if d < 0.0 {
            return inverse_haversine(lat1: lat1, lon1: lon1, d: -1.0*d, radAzimuth: normalizeRadians(inAngle: radAzimuth+Double.pi), alt: alt)
        }
        // calcualte WGS84 radius at lat/lon based on gis.stackexchange.com/a/20250
        
        var r: Double = radius_at_lat_lon(inLat: lat1, inLon: lon1)
        r += alt
        lat1 = lat1.radians
        lon1 = lon1.radians
        
        var lat2: Double = asin(sin(lat1) * cos(d/r) + cos(lat1)*sin(d/r)*cos(radAzimuth))
        var lon2: Double = lon1 + atan2( (sin(radAzimuth)*sin(d/r)*cos(lat1)),(cos(d/r)-sin(lat1)*sin(lat2)))
    
        return (lat2.degrees,lon2.degrees)
    }
    
    // determine great circle distance between two lat/lon pairs
    // lat/lon in degrees, not radians
    // alt above surface of WGS84 ellipsoid in meters
    // used to determine radius of great circle
    // return distance in meters along great circle path between two points
    
    public static func haversine(lat1: Double, lon1: Double, lat2: Double, lon2: Double, alt: Double) -> Double
    {
        var lat1 = lat1
        var lat2 = lat2
        var lon1 = lon1
        var lon2 = lon2
    
        lon1 = lon1.radians
        lon2 = lon2.radians
        lat1 = lat1.radians
        lat2 = lat2.radians
        
        var dlon:Double = lon2 - lon1
        var dlat:Double = lat2 - lat1
        
        var a: Double = pow(sin(dlat/2.0),2) + cos(lat1) * cos(lat2) * pow(sin(dlon/2),2)
        var c: Double = 2.0 * asin(sqrt(a))
        var r: Double = radius_at_lat_lon(inLat: (lat1+lat2)/2.0, inLon: (lon1+lon2)/2.0)
        r = r + alt
        return c * r
    }
    
    // resolve location of "target" which is center of this drone image
    // given the DEM and the lat/long/alt
    // See OpenAthenaAndroid:TargetGetter.java:resolveTarget()
    // 
    // 0 distance to target
    // 1 last latitude value along raycast
    // 2 last longitude value along raycast
    // 3 last altitude along raycast
    // 4 terrain altitude of datapoint nearest last raycast position
    
    // add drone ccd info, if available, so we can locate target not at center XXX
    
    public func resolveTarget(dem: DigitalElevationModel) throws -> [Double]
    {
        var finalDist, tarLat, tarLon, tarAlt, terrainAlt: Double
        var radAzimuth: Double
        var radTheta: Double
        var lat,lon, alt: Double
        let INCREMENT: Double = 1.0
        var degAzimuth, degTheta: Double
        var azimuthOffset, thetaOffset: Double
        
        // azimuth is direction of aircraft's camera 0 is north, increase clockwise
        // which is reported as Yaw degree
        // theta is angle of depression (pitch) of aircraft's camera; positive value
        // representing degrees downward from horizon; reported as pitch degree
        // targetXprop,targetYprop are where in image we're examining

        do {
            try degAzimuth = getGimbalYawDegree()
            try degTheta = getGimbalPitchDegree()
                        
            (azimuthOffset,thetaOffset) = try getRayAnglesFromImagePixel(x: theImage!.size.width * targetXprop,
                                                                         y: theImage!.size.height * targetYprop)
            degAzimuth += azimuthOffset
            degTheta += thetaOffset
            
            // convert to radians
            radAzimuth = degAzimuth.radians
            radAzimuth = DroneImage.normalizeRadians(inAngle: radAzimuth)
            radTheta = degTheta.radians
            try lat = getLatitude()
            try lon = getLongitude()
            try alt = getAltitude()
        }
        catch {
            print("resolveTarget: missing metadata at the start")
            throw error
        }
        
        
        
        // check if target is directly below us; special case
        // 0.005 is ~0.29 degrees
        // use DEM to get altitude of ground
        // fix bug 4/14/2023
        do {
            if fabs(radTheta - Double.pi/2.0)  <= 0.005 {
                try terrainAlt = dem.getAltitudeFromLatLong(targetLat: lat,targetLong: lon)
                tarLat = lat
                tarLon = lon
                tarAlt = terrainAlt
                finalDist = fabs(alt - terrainAlt)
                return [ finalDist, tarLat, tarLon, tarAlt, terrainAlt ]
            }
        }
        catch {
            throw error
        }
        
        // safety check; if theta > 90 degrees then camera is facing backwards
        // to avoid undefined behavior, reverse radAzimuth and subject theta
        // from 180 deg to determine new appropriate theta for reverse direction
        // during manual data entry, please avoid abs values > 90 deg
        // fix for radTheta comparison 4/14/2023
        if radTheta > (Double.pi / 2.0) {
            radAzimuth = DroneImage.normalizeRadians(inAngle: (radAzimuth + Double.pi))
            radTheta = Double.pi - radTheta
        }
        
        // convert azimuth to unit circle (just like math class)
        var radDirection: Double = DroneImage.azimuthToUnitCircleRad(inAngle: radAzimuth)
        
        // from direction, determine rate of x and y change per unit travel
        // level with horizon for now
        var deltaX: Double = cos(radDirection)
        var deltaY: Double = sin(radDirection)
        var deltaZ: Double = -1.0 * sin(radTheta)
        
        // determine by how much of travel per unit is actually horizon
        // using pythagorean theorm: deltaz^2 + deltax^2 + deltay^2 = 1
        // because unit circle r = 1
        var horizScalar: Double = cos(radTheta)
        deltaX *= horizScalar
        deltaY *= horizScalar
        
        // meters of acceptable distance between constructed line and datapoint
        // somewhat arbitrary; SRTM has horizontal resolution of 30m
        // but vertical accuracy is more precise
        
        var post_spacing_meters: Double = DroneImage.haversine(lat1: lat, lon1: 0, lat2: lat, lon2: dem.getXResolution(), alt: alt)
        
        // meters of acceptable distance between constructed line and datapoint.  somewhat arbitrary
        var THRESHOLD: Double = post_spacing_meters / 16.0
        
        var curLat = lat
        var curLon = lon
        var curAlt = alt
        var groundAlt: Double
        do {
            try groundAlt = dem.getAltitudeFromLatLong(targetLat: curLat, targetLong: curLon)
        }
        catch {
            throw error
        }

        if (curAlt < groundAlt) {
            print("curAlt < groundAlt while resolving target")
            throw ElevationModuleError.RequestedValueOOBError
        }
        
        var altDiff = curAlt - groundAlt
        while altDiff > THRESHOLD {
            do {
                try groundAlt = dem.getAltitudeFromLatLong(targetLat: curLat, targetLong: curLon)
            }
            catch {
                throw error
            }
            altDiff = curAlt - groundAlt
            
            var avgAlt: Double = curAlt
            
            // deltaZ should always be negative
            curAlt += deltaZ
            avgAlt = (avgAlt + curAlt) / 2.0
            
            (curLat,curLon) = DroneImage.inverse_haversine(lat1: curLat, lon1: curLon, d: horizScalar*INCREMENT, radAzimuth: radAzimuth, alt: avgAlt)
            
        } // while altDiff > threshold
        
        // when loop ends, curY, curX, curZ are closeish to target
        // may be bit biased ever so slightly long beyond the target
        // this algorithm is crude and does not take into account the
        // curvature of the earth over long distances
        // could use refinement XXX
        
        var finalHorizDist: Double = fabs(DroneImage.haversine(lat1: lat, lon1: lon, lat2: curLat, lon2: curLon, alt: alt))
        var finalVertDist: Double = fabs(alt-curAlt)
        // simple pythagorean thereom
        // may be inaccurate for very long horizontal distances
        finalDist = sqrt(finalHorizDist*finalHorizDist + finalVertDist*finalVertDist)
        terrainAlt = groundAlt
        
        return [finalDist, curLat, curLon, curAlt, terrainAlt ]
        
    } // resolveTarget()
    
    // get a tag out of the meta data and return value as string
    private func getMetaDataTagValue(_ tagStr: String) -> String {
        if rawMetaData == nil {
            return ""
        }
        
        let tag = CGImageMetadataCopyTagWithPath(rawMetaData!,
                                                 nil,
                                                 tagStr as NSString)!
        let val = CGImageMetadataTagCopyValue(tag)
        let str = val as! NSString
        return str as String
    }
    
    // read through the raw image data and grab out Xmp XML
    // data and put tag/values in the metaData dictionary
    
    // don't throw errors via this method
    public func parseXmpMetaDataNoError() {
        
        do {
            try parseXmpMetaData()
        }
        catch {
            // do nothing
        }
    }
    
    // parse XMP/XML data out of image throwing errors
    // if encountered
    public func parseXmpMetaData() throws {
        
        if rawData == nil {
            xmpDataRead = false
            print("parseXmpMetaData: no raw data\n")
            throw DroneImageError.NoRawData
        }
        
        // open file and parse through it looking for XML document ?
        // parse looking for <?xpacket begin=
        let fileData: [UInt8]
        
        fileData = rawData!.bytes
        var dataString = String(decoding: fileData, as: UTF8.self)
        let beginRange = dataString.range(of: "<?xpacket begin")
        let endRange = dataString.range(of: "<?xpacket end.*?>", options: .regularExpression)
        if beginRange == nil || endRange == nil {
            //print("parseXmpMetaData: did not find tags\n")
            throw DroneImageError.NoXmpMetaData
        }
        let startIndex = beginRange!.lowerBound
        let endIndex = endRange!.upperBound
        xmlString = String(dataString[startIndex..<endIndex])
        print("XML doc length is \(xmlString!.count)")
        //print("XML String to parse is \(xmlString!)")
        
        // xmlString gets consumed by parser; we should parse a copy of it
        xmlStringCopy = xmlString
        
        let xmlParser = XMLParser(data: Data(xmlString!.utf8))
        let mpd = MyParserDelegate()
        mpd.metaData = self.metaData
        xmlParser.delegate = mpd
        xmpDataRead = xmlParser.parse()
        //print("After parse, here is metadata")
        //print(self.metaData)
        
    } // readXmpMetaData
    
    // parser delegate class for use with parsing XMP/XML document
    // numeric data that comes out of XML/XMP parsing is all strings
    // so it can't be typecast directly
    // have to typecast to NSString then take doubleValue method
    // numeric data that comes out of CGImage routines can be
    // typecast directly to numbers without ingtermediate step
    
    class MyParserDelegate: NSObject, XMLParserDelegate {

        var currentValue: String?
        var metaData: NSMutableDictionary?
        var skydioCameraOrientationNED = false
        
        func parserDidStartDocument(_ parser: XMLParser) {
            //print("Start of document")
            //print("Line number: \(parser.lineNumber)")
        }

        func parserDidEndDocument(_ parser: XMLParser) {
            //print("End of document")
            //print("Line number: \(parser.lineNumber)")
        }

        func parser(_ parser: XMLParser, didEndElement elementName: String,
                    namespaceURI: String?, qualifiedName qName: String?) {
            
            if elementName.contains("tiff:") {
                metaData![elementName] = currentValue
                currentValue = nil
            }
                
            // parrot puts metadata in element
            // rather than attribute
            if elementName.contains("drone-parrot:") {
                metaData![elementName] = currentValue
                currentValue = nil
            }
            // sometimes autell puts meta data in element
            // rather than attribute
            if elementName.contains("Camera:") {
                metaData![elementName] = currentValue
                currentValue = nil
            }
            // autell exif:GPSAltitudeRef
            if elementName.contains("exif:") {
                metaData![elementName] = currentValue
                //print("exif Element name \(elementName) value \(currentValue)")
                currentValue = nil
            }
            
            // skydio reuses attribute names for multiple
            // elements; our attribute parser handles this
            
            // skydio sometimes put elements under elements
            // handle that by looking for NED and seeting flag
            if elementName.contains("drone-skydio:CameraOrientationNED") {
                skydioCameraOrientationNED = false
            }
            if elementName.contains("drone-skydio:Pitch") && skydioCameraOrientationNED {
                metaData!["drone-skydio:CameraOrientationNED:Pitch"] = currentValue
                currentValue = nil
            }
            if elementName.contains("drone-skydio:Yaw") && skydioCameraOrientationNED {
                metaData!["drone-skydio:CameraOrientationNED:Yaw"] = currentValue
                currentValue = nil
            }
            if elementName.contains("drone-skydio:Roll") && skydioCameraOrientationNED {
                metaData!["drone-skydio:CameraOrientationNED:Roll"] = currentValue
                currentValue = nil
            }
            
        } // didEndElement

        func parser(_ parser: XMLParser, foundCharacters string: String) {
             currentValue? += string
        }

        func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?,
                    qualifiedName qName: String?, attributes attributeDict: [String: String]) {
            
            print("Element name \(elementName)")
            
            // look for tiff: elements
            if elementName.contains("tiff:") {
                currentValue = String()
            }
            // parrot drone data is in element value
            if elementName.contains("drone-parrot:") {
                currentValue = String()
            }
            // sometimes Autell does this too
            if elementName.contains("Camera:") {
                currentValue = String()
            }
            // sometimes Autell puts some exif stuff in XMP elements
            if elementName.contains("exif:") {
                currentValue = String()
            }
            // some drone-skydio attributes appear in multiple elements
            // our attribute/tag parser handles

            // dji, skydio data is in attributes
            // skydio often uses duplicate attributes
            // for diff elements
            
            // skydio is also including elements under elements
            // e.g. skydio_S1001975.JPG
            if elementName.contains("drone-skydio:CameraOrientationNED") {
                skydioCameraOrientationNED = true
            }
            if elementName.contains("drone-skydio:Pitch") && skydioCameraOrientationNED {
                currentValue = String()
            }
            if elementName.contains("drone-skydio:Yaw") && skydioCameraOrientationNED {
                currentValue = String()
            }
            
            for (t,v) in attributeDict {
                print("Tag: \(t)  Value: \(v)")
                if t.contains("aux:") {
                    metaData![t] = v
                }
                if t.contains("photoshop:") {
                    metaData![t] = v
                }
                if t.contains("drone-dji:") {
                    metaData![t] = v
                }
                if t.contains("tiff:") {
                    metaData![t] = v
                }
                if t.contains("exif:") {
                    //print("Adding exif element \(t) and value \(v)")
                    metaData![t] = v
                }
                if t.contains("drone-skydio:") {
                    if elementName.contains("drone-skydio") {
                        var newTag: String
                        let tArray = t.components(separatedBy: ":")
                        newTag = elementName + ":" + tArray[1]
                        metaData![newTag] = v
                    }
                    else {
                        metaData![t] = v
                    }
                }
                if t.contains("drone-parrot:") {
                    metaData![t] = v
                }
                // autell old
                if t.contains("Camera:") {
                    metaData![t] = v
                }
                // autell new
                if t.contains("drone:") {
                    metaData![t] = v
                }
                
            } // foreach tag,value
            
        } // didStartElement
     
    } // MyParserDelegate

    
} // DroneImage
    
