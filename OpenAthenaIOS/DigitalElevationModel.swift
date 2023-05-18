//
//  DigitalElevationModel.swift
//  OpenAthenaIOS
//  https://github.com/rdkgit/OpenAthenaIOS
//  https://openathena.com//
//  Created by Bobby Krupczak on 2/3/23.
//  Formerly GeoTIFFParser in OpenAthenaAndroid
//  parse and eat GeoTIFF digital elevation models
//  using https://github.com/ngageoint/tiff-ios
//  and data from OpenTopography.org
//  TODO: add support for online lookup via web api XXX
//  OpenTopography API key: 83423adced07b4c2236fe7e050d182e8
//  Use GPS coordinates to get DEM surrounding the area

import Foundation
import UniformTypeIdentifiers
import MobileCoreServices
import tiff_ios

enum ElevationModuleError: String, Error {
    case RequestedValueOOBError = "DEM: requested value out of bounds"
    case IllegalArgumentException = "DEM: illegal argument"
    case NullPointerException = "DEM: null pointer"
    case ElevationModuleException = "DEM: exception"
}

struct GeoDataAxisParams {
    var start: Double = 0
    var end: Double = 0
    var stepwiseIncrement: Double = 0
    var numberOfSteps: Int = 0
}

public class DigitalElevationModel {

    var tiffURL: URL!
    var tiffImage: TIFFImage!
    var directory: TIFFFileDirectory!
    var rasters: TIFFRasters!
    var xParams = GeoDataAxisParams()
    var yParams = GeoDataAxisParams()

    init?(fromURL url: URL)
    {
        tiffURL = url
        
        print("DigitalElevationModel: loading \(url.lastPathComponent)")
        
        let fileManager = FileManager.default
        if fileManager.isReadableFile(atPath: url.path) == false {
            guard url.startAccessingSecurityScopedResource() else {
                return nil
            }
        }
        do {
            var data = try Data(contentsOf: url)
            tiffImage = TIFFReader.readTiff(from: data)
        }
        catch {
            return nil
        }
        
        url.stopAccessingSecurityScopedResource()
        
        print("Read geotiff file into tiffimage; now going to look at pieces")
        
        // initialize some directories, etc.
        directory = tiffImage!.fileDirectories().first
        
        print("Read geotiff directory, num entries \(directory!.numEntries())")
        
        // cobb.tiff can't read rasters
        // 'Not Implemented', reason: 'Deflate decoder is not yet implemented'
        // XXX
        // challenge is that the exception occurs in objective-c library
        // which doesnt propagate back to swift caller
        // there are various hacks out there to bridge the exception
        // revist after iOS port is complete
        
        rasters = directory!.readRasters()
        
        print("Read the directory rasters!!")
        
        print("Read geotiff directory rasters")
        print("Rasters: w:\(rasters.width()) h:\(rasters.height()) pixels:\(rasters.numPixels()) samples/pixel:\(rasters.samplesPerPixel()) bps:\(rasters.samplesPerPixel())")
        
        let tiePoint = directory.modelTiepoint()
        let pixelAxisScale = directory.modelPixelScale()

        xParams.start = tiePoint![3].doubleValue
        xParams.stepwiseIncrement = pixelAxisScale![0].doubleValue
        xParams.numberOfSteps = getDemWidth()
        xParams.end = xParams.start + (xParams.stepwiseIncrement * Double(xParams.numberOfSteps-1))
        
        yParams.start = tiePoint![4].doubleValue
        yParams.stepwiseIncrement = -1.0 * pixelAxisScale![1].doubleValue
        yParams.numberOfSteps = getDemHeight()
        yParams.end = yParams.start + (yParams.stepwiseIncrement * Double(yParams.numberOfSteps-1))
        
        print("xParams.start is \(xParams.start)")
        print("xParams.end is \(xParams.end)")
        print("yParams.start is \(yParams.start)")
        print("yParams.end is \(yParams.end)")
    }
    
    public func getDemWidth() -> Int {
        return directory!.imageWidth().intValue
    }

    public func getDemHeight() -> Int {
        return directory!.imageHeight().intValue
    }
    
    public func getXResolution() -> Double {
        return xParams.stepwiseIncrement
    }
    
    public func getYResolution() -> Double {
        return yParams.stepwiseIncrement
    }
    
    public func getNumCols() -> Int {
        return xParams.numberOfSteps
    }
    
    public func getNumRows() -> Int {
        return yParams.numberOfSteps
    }
    
    public func getMinLongitude() -> Double {
        return min(xParams.end, xParams.start)
    }
    
    public func getMaxLongitude() -> Double {
        return max(xParams.end, xParams.start)
    }
    
    public func getMinLatitude() -> Double {
        return min(yParams.end, yParams.start)
    }
    
    public func getMaxLatitude() -> Double {
        return max(yParams.end, yParams.start)
    }
    
    // get the center of this DEM model
    // return lat/lon
    
    public func getCenter() -> (Double,Double) {
        // maxlatitude - minlatitude /2 + minlatitude
        var centerLat: Double
        var centerLon: Double
        
        centerLat = ((getMaxLatitude() - getMinLatitude())/2)  + getMinLatitude()
        centerLon = ((getMaxLongitude() - getMinLongitude())/2) + getMinLongitude()
        
        return (centerLat,centerLon)
    }
    
    // calculate altitude from lat/long using this digital elevation model
    // lat [-90, 90]
    // lon [-180, 180]
    // return altitude of terrain near lat/lon in meters above
    // WGS84 reference ellipsoid
    // right now, we are assuming offline model
    // add support for web api online lookup XXX
    
    public func getAltitudeFromLatLong(targetLat lat: Double,
                                       targetLong lon: Double) throws -> Double {
        if xParams.numberOfSteps == 0 && yParams.numberOfSteps == 0 {
            print("No digital elevation mode; returning 0.0")
            throw ElevationModuleError.IllegalArgumentException
        }
        
        let x0 = xParams.start
        let x1 = xParams.end
        let dx = xParams.stepwiseIncrement
        let ncols = xParams.numberOfSteps
        
        let y0 = yParams.start
        let y1 = yParams.end
        let dy = yParams.stepwiseIncrement
        let nrows = yParams.numberOfSteps
        
        // check if location is inside our bounding box
        if lat > getMaxLatitude() || lat < getMinLatitude() {
            print("Latitude \(lat) out of range \(getMinLatitude()) .. \(getMaxLatitude())")
            throw ElevationModuleError.RequestedValueOOBError
        }
        if lon > getMaxLongitude() || lon < getMinLongitude() {
            print("Longitude \(lon) out of range \(getMinLongitude()) .. \(getMaxLongitude())")
            throw ElevationModuleError.RequestedValueOOBError
        }
        
        // find neighbors in x axis
        var xL, xR: Int
        var xIndex: Int = 0
        
        do {
            (xL, xR) = try binarySearchNearest(startVal: x0, number: ncols,
                                               value: lon, delta: dx)

            if abs(lon - (x0 + Double(xL) * dx)) < abs(lon - (x0 + Double(xR) * dx)) {
                xIndex = xL
            }
            else {
                xIndex = xR
            }
        } catch {
            print("Error in binarySearchNearest \(error)")
            throw error
        }
        
        // find neighbors in y axis
        var yT, yB: Int
        var yIndex: Int = 0
        
        do {
            (yT, yB) = try binarySearchNearest(startVal: y0, number: nrows,
                                               value: lat, delta: dy)
            
            if abs(lat - (y0 + Double(yT) * dy)) < abs(lat - (y0 + Double(yB) * dy)) {
                yIndex = yT
            }
            else {
                yIndex = yB
            }
        } catch {
            print("Error in binarySearchNearest \(error)")
            throw error
        }
        
        // calculate result given rasters
        // see OpenAthenaAndroid for comparision
        // https://gdal.org/java/org/gdal/gdal/Dataset.html#ReadRaster
        // https://gis.stackexchange.com/questions/349760
        
        var result: Double
        
        result = rasters.pixelAt(x: Int32(xIndex), andY: Int32(yIndex))[0].doubleValue
 
        return result
        
    } // getAltitudeFromLatLong
    
    // Perform a binary search through the values return two closest values to the
    // input
    // start value in degrees, of an axis of geofile
    // n the number of items in an axis of geofile
    // val an input value for which to find to closest indicies
    // dN the change in value for each increment of the index along axis of geofile
    // ported from OpenAthenaAndroid
    
    private func binarySearchNearest(startVal start: Double,
                                     number n: Int,
                                     value val: Double,
                                     delta dN: Double) throws -> (Int, Int) {
        
        // empty dataset?
        if n <= 0 {
            throw ElevationModuleError.ElevationModuleException
        }
            
        // if only one elevation data point, exceedingly rare
        if n == 1 {
            if abs(start - val) <= 0.00000001 {
                return (0,0)
            }
            else {
                throw ElevationModuleError.ElevationModuleException
            }
        }
        
        if dN == 0.0 {
            throw ElevationModuleError.ElevationModuleException
        }
        
        let isDecreasing: Bool = (dN < 0.0)
        
        if isDecreasing {
            
            var a1, a2: Int
            
            // if its decreasing order, uh, don't do that; make it increasing instead
            let reversedStart: Double = start + Double(n) * dN
            let reversedDN: Double = -1.0 * dN
            
            do {
                (a1,a2) = try binarySearchNearest(startVal: reversedStart,number: n,
                                                      value: val, delta: reversedDN)
            }
            catch {
                print("recursive binarySearchNearest threw error \(error)")
                throw error
            }
            
            // kinda weird but we reverse index result since we reversed list
            a1 = n - a1 - 1
            a2 = n - a2 - 1
            return (a1,a2)
        }
        
        var L: Int = 0
        var lastIndex: Int = n - 1
        var R: Int = lastIndex
        var m: Int
        
        while  L <= R {
            let f: Double = floor( Double(L + R) / 2.0)
            m = Int(f)
            if start + Double(m) * dN < val {
                L = m + 1
            }
            else if start + Double(m) * dN > val {
                R = m - 1
            }
            else {
                // exact match
                return (m,m)
            }
        } // while
        
        // we've broken out of loop which means L > R
        // which means markers have flipped
        // therefore eitther list[L] or list[R] must be closest to val
        
        return (R,L)
        
    } // binarySearchNearest
    
    
} // DigitalElevationModel