// DemCache.swift
// OpenAthenaIOS
// Created by Bobby Krupczak on 10/12/23.
// Copyright 2024, Theta Informatics LLC
// AGPLv3
// https://www.gnu.org/licenses/agpl-3.0.txt

// Digital elevation model (DEM) cache class and methods

import Foundation
import CoreLocation

public struct DEM_cache_entry {
    let fileURL: URL
    let filename: String
    let n: Double   // n lat degrees
    let s: Double   // s lat degrees
    let e: Double   // e lon degrees
    let w: Double   // w lon degrees
    let l: Double   // length or width of box in meters
    let cLat: Double // center lat, lon
    let cLon: Double
    let createDate: Date
    let modDate: Date
    let bytes: Int
}

class DemCache
{
    public var cache: [DEM_cache_entry] = []
    public var totalBytes = 0
    
    // create initial cache by scanning private sandbox documents directory
    
    init()
    {
        // go through app document folder examining
        // DEM_LatLon files and build our meta cache
        // don't load anything just yet
        
        // open our Documents folder and scan for tiff files
        guard let docDirURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        
        do {
            
            //print("buildCache: examining \(docDirURL)")
            
            let dirContents = try FileManager.default.contentsOfDirectory(at: docDirURL, includingPropertiesForKeys: nil)
            
            for fileURL in dirContents {
                
                // if its a tiff file
                // if its DEM_LatLn XXX
                
                if fileURL.isFileURL && fileURL.pathExtension == "tiff" {
                    //print("Build cache: found \(fileURL)")
                    
                    // get the last compoent which is filename then
                    // break apart into n,s,e,w
                    // doesnt look like swift can give us a file's
                    // last access date unlike C and stat system call XXX
                    
                    // strip off ".tiff" from filename which is lastPathComponent
                    
                    let filename = fileURL.deletingPathExtension().lastPathComponent
                    
                    let attrs = try FileManager.default.attributesOfItem(atPath: fileURL.path) as [FileAttributeKey: Any]
                    //print("File: \(filename)")
                    //print("Create: \(attrs[FileAttributeKey.creationDate] as? Date)")
                    //print("Mod: \(attrs[FileAttributeKey.modificationDate] as? Date)")
                    
                    let pieces = filename.components(separatedBy: "_")
                    if pieces.count == 6 {
                        let s = (pieces[2] as NSString).doubleValue
                        let w = (pieces[3] as NSString).doubleValue
                        let n = (pieces[4] as NSString).doubleValue
                        let e = (pieces[5] as NSString).doubleValue
                        //print("Bounding box: \(s),\(w) \(n),\(e)")
                        
                        // figure out the diameter and center from the coordinates
                        let(clat,clon,l) = getCenterAndLength(s: s, w: w, n: n, e: e)
                        
                        // add all of this to the cache list
                        let aDem = DEM_cache_entry(fileURL: fileURL,
                                                   filename: filename,
                                                   n: n, s: s, e: e, w: w,
                                                   l: l, cLat: clat, cLon: clon,
                                                   createDate: (attrs[FileAttributeKey.creationDate] as? Date)!,
                                                   modDate: attrs[FileAttributeKey.modificationDate] as! Date,
                                                   bytes: attrs[FileAttributeKey.size] as! Int)
                        
                        cache.append(aDem)
                        totalBytes += aDem.bytes
                    }
                    
                }
            } // for each fileURL
            
        }
        catch {
            print("Build cache: error \(error)")
        }
        
        //print("Cached \(cache.count) entries")
        
    } // init
    
    func count() -> Int { return cache.count }
    
    func totalStorage() -> Int { return totalBytes }
    
    func removeCacheEntry(index: Int)
    {
        totalBytes -= cache[index].bytes
        cache.remove(at: index)
    }
    
    // search our cache of DEMs and find an entry that:
    // lat, lon is in the DEM and is closest to center
    // return nil if no cache entry found
    
    func searchCacheFilename(lat: Double, lon: Double) -> String
    {
        // var aDem: DEM_cache_entry? = searchCacheEntry(lat: lat, lon: lon)
        // re issue #43 find entry with max coverage
        var aDem: DEM_cache_entry? = searchCacheMaxCoverage(lat: lat, lon: lon)
        
        if aDem != nil {
            return aDem!.filename
        }
        else {
            return ""
        }
    }
    
    func searchCacheByFilename(filename: String) -> DEM_cache_entry?
    {
        for dem in cache {
            if dem.filename.elementsEqual(filename) {
                return dem
            }
        }
        return nil
    }
    
    // re issue #43 we want to find DEM with most local
    // coverage rather than one closest to center
    // because we could have maps of varying sizes all
    // covering the same area;
    
    func searchCacheMaxCoverage(lat: Double, lon: Double) -> DEM_cache_entry?
    {
        var maxCoverage:Double = -1
        var anEntry: DEM_cache_entry?
        var nCoverage, sCoverage, eCoverage, wCoverage, coverage: Double
        
        print("searchCacheMaxCoverage: \(lat),\(lon)")
        
        for dem in cache {
            if (lat < dem.n && lat > dem.s && lon > dem.w && lon < dem.e) {
                nCoverage = abs(dem.n - lat)
                sCoverage = abs(lat - dem.s)
                eCoverage = abs(dem.e - lon)
                wCoverage = abs(lon - dem.w)
            
                coverage = min(min(nCoverage,sCoverage),min(eCoverage,wCoverage))
                
                print("searchCacheMaxCoverage: \(dem.filename) covers drone \(coverage)")

                if coverage > maxCoverage {
                    print("searchCacheMaxCoverage: \(dem.filename) max coverage \(coverage)")
                    maxCoverage = coverage
                    anEntry = dem
                }
            }
        }
       
        if anEntry != nil {
            print("searchCacheMaxCoverage: returning \(anEntry!.filename)")
        }
        return anEntry
    }
    
    func searchCacheEntry(lat: Double, lon: Double) -> DEM_cache_entry?
    {
        var leastDistanceToCenter = Double.infinity
        var anEntry: DEM_cache_entry?
        
        //print("Searching cache for \(lat),\(lon)")
        
        for dem in cache {
            //print("Examing box: \(dem.s),\(dem.n)   \(dem.w),\(dem.e)")
            
            // is the lat,lon within the DEM?
            if lat < dem.n && lat > dem.s && lon > dem.w && lon < dem.e {
                
                // calculate distance to center
                let p1 = CLLocation(latitude: lat, longitude: lon)
                let p2 = CLLocation(latitude: dem.cLat, longitude: dem.cLon)
                let d = p1.distance(from: p2)
                
                print("Within \(dem.filename), distance \(d)")
                
                if d < leastDistanceToCenter {
                    anEntry = dem
                    leastDistanceToCenter = d
                    print("Closest to center: \(d)")
                }
            }
        } // for each
        
        if anEntry != nil {
            return anEntry!
        }
        else {
            return nil
        }
    }
    
    // given a lat, lon, load the elevation map
    // this function is called from various view controllers
    // issue #43 load dem from cache that has max coverage
    func loadDemFromCacheMaxCoverage(lat: Double, lon: Double) throws -> DigitalElevationModel
    {
        var anEntry: DEM_cache_entry?
        
        anEntry = searchCacheMaxCoverage(lat: lat, lon: lon)
        
        if anEntry == nil {
            throw ElevationModuleError.NoSuch
        }
        
        guard let dem = DigitalElevationModel(fromURL: anEntry!.fileURL) else {
            print("loadFromCacheMaxCoverage: failed to load DEM \(anEntry!.fileURL)")
            throw ElevationModuleError.NoSuch
        }
        
        return dem 
    }
    
    func loadDemFromCache(lat: Double, lon: Double) throws -> DigitalElevationModel
    {
        var leastDistanceToCenter = Double.infinity
        var theURL: URL?
        
        print("Searching cache for \(lat),\(lon)")
        
        for dem in cache {
            //print("Examing box: \(dem.s),\(dem.n)   \(dem.w),\(dem.e)")
            
            // is the lat,lon within the DEM?
            if lat < dem.n && lat > dem.s && lon > dem.w && lon < dem.e {
                
                // calculate distance to center
                let p1 = CLLocation(latitude: lat, longitude: lon)
                let p2 = CLLocation(latitude: dem.cLat, longitude: dem.cLon)
                let d = p1.distance(from: p2)
                
                print("Within \(dem.filename), distance \(d)")
                
                if d < leastDistanceToCenter {
                    theURL = dem.fileURL
                    leastDistanceToCenter = d
                    print("Closest to center: \(d)")
                }
            }
        }
        
        if theURL == nil {
            throw ElevationModuleError.NoSuch
        }
        
        guard let dem = DigitalElevationModel(fromURL: theURL!) else {
            print("Failed to load DEM \(theURL!)")
            throw ElevationModuleError.NoSuch
        }
        
        return dem
        
    } // loadDemFromCache and return the DEM
    
    func dumpCache()
    {
        for dem in cache {
            
            print("DEM: \(dem.filename)")
            print("\t center: \(dem.cLat),\(dem.cLat)")
            print("\t l/w: \(dem.l)")
            print("\t s:\(dem.s) w:\(dem.w) n:\(dem.n) e:\(dem.e)")
            print("\t create: \(dem.createDate)")
            print("\t mod: \(dem.modDate)")
        }
    }
    
    // get center and diameter from bounding box
    private func getCenterAndLength(s: Double, w: Double, n: Double, e: Double) -> (Double,Double,Double)
    {
        let p1 = CLLocation(latitude: s, longitude: w)
        let p2 = CLLocation(latitude: n, longitude: w)
        let p3 = CLLocation(latitude: n, longitude: e)
        let p4 = CLLocation(latitude: s, longitude: e)
        
        let d12 = p1.distance(from: p2)
        let d14 = p1.distance(from: p4)
        let d23 = p2.distance(from: p3)
        let d34 = p3.distance(from: p4)
        
        // average the 4 distances
        let l = (d12 + d14 + d23 + d34) / 4
        // print("Distance \(l)")
        // calculate arlen
        let h = sqrt( 2.0 * pow((l/2.0),2.0)) / (6371 * 1000)
        
        // calculate center based on s,w -> width/length / 2
        let (clat,clon) = DemCache.translateCoordinate(lat: s, lon: w, bearing: 45.0, arcLen: h)
        //print("Center: \(clat),\(clon)")
        
        let p0 = CLLocation(latitude: clat, longitude: clon)
        //print("Distance to center is \(p0.distance(from: p1)) \(p0.distance(from: p2)) \(p0.distance(from: p3)) \(p0.distance(from: p4)) ")
        
        return (clat, clon, l)
        
    } // getCenterAndDiameter
    
    
    // given location lat,lon, bearing all in degrees, and arcLen in meters,
    // calculate new lat,lon in degrees and return
    
    public static func translateCoordinate(lat: Double, lon: Double, bearing: Double, arcLen: Double) -> (Double, Double) {
        
        //print("translateCoordinate: \(lat),\(lon) \(arcLen)")
        
        let latR = lat * (Double.pi / 180.0)
        let lonR = lon * (Double.pi / 180.0)
        let bearingR = bearing * (Double.pi / 180.0)
        
        var newLatR = asin(sin(latR) * cos(arcLen) + cos(latR) * sin(arcLen) * cos(bearingR) )
        var newLonR = lonR + atan2(sin(bearingR) * sin(arcLen) * cos(latR), cos(arcLen) - sin(latR) * sin(newLatR))
        
        let newLat = newLatR * (180.0 / Double.pi)
        let newLon = newLonR * (180.0 / Double.pi)
        
        return (newLat, newLon)
    }
    
} // DemCache
