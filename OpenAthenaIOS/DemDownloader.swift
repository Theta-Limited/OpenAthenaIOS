//
//  DemDownloader.swift
//  OpenAthenaIOS
//
//  Created by Bobby Krupczak on 10/12/23.
//
//  Handle downloading DEMs from OpenTopography

import Foundation
import UIKit

class DemDownloader
{
    var apiKeyStr: String? {
        if let path = Bundle.main.path(forResource: "Secrets", ofType: "plist"),
           let dict = NSDictionary(contentsOfFile: path) as? [String: AnyObject] {
            return dict["OpenTopographyApiKey"] as? String
        }
        return "NoApiKeyFound"
    }
    static let urlStr = "https://portal.opentopography.org/API/globaldem?"
    static let demTypeStr = "SRTMGL1"
    var responseCode: Int = 0
    var responseBytes: Int = 0
    var s,w,n,e: Double
    var app: AppDelegate = UIApplication.shared.delegate as! AppDelegate

    // create a downloader and download a DEM
    // centered at lat,lon, with square dimension lengthxlength
    init(lat: Double, lon: Double, length: Double)
    {
        (s,w,n,e) = DemDownloader.getBoundingBox(centerLat: lat, centerLon: lon, l: length)
        
        print("Center is: Lat:\(lat) Lon:\(lon), Len/Width is: \(length)")
        print("Going to fetch DEM: \(s),\(w) \(n),\(e)")
        print("Using API key \(apiKeyStr!)")
    
    }
    
    func download(completionHandler: @escaping (Int, Int, String) -> Void )
    {
        // build the URL
        var requestURLStr = DemDownloader.urlStr +
            "demtype=\(DemDownloader.demTypeStr)" +
            "&south=\(s)" +
            "&north=\(n)" +
            "&west=\(w)" +
            "&east=\(e)" +
            "&outputFormat=GTiff" +
            "&API_Key=\(apiKeyStr!)"
        
        print("Request URL is \(requestURLStr)")
        
        let task = URLSession.shared.dataTask(with: URL(string: requestURLStr)!, completionHandler: {
            data, response, error in
            
            guard let data = data, error == nil else {
                self.responseCode = -2
                completionHandler(-2,0,"no file written")
                return
            }
                        
            // look at http response code
            guard let httpResponse = response as? HTTPURLResponse else {
                self.responseCode = -1
                completionHandler(-1,0,"no file written")
                return
            }
            
            if httpResponse.statusCode != 200 {
                self.responseCode = httpResponse.statusCode
                completionHandler(self.responseCode,0,"no file written")
                return
            }
            
            // have data; need to check status code because
            // success means we got a reply, not necessarily a DEM
            
            self.responseBytes = data.count
            self.responseCode = httpResponse.statusCode
            
            print("Response: \(httpResponse.value(forHTTPHeaderField: "Content-Disposition"))")
            print("Data: \(data.count) bytes")
            
            // save to file using our naming convention
            // DEM_LatLon_lowerleft_upperright.tiff

            let filenameStr = "DEM_LatLon_" +
                "\(self.s)_\(self.w)" +
                "_" +
                "\(self.n)_\(self.e)" +
                ".tiff"
            
            if let fileURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent(filenameStr) {
                do {
                    try data.write(to: fileURL)
                    print("Data successfully written to \(fileURL)")
                    completionHandler(self.responseCode,self.responseBytes,filenameStr)
                } catch {
                    print("Error writing data to file \(error)")
                    self.responseCode = -3
                    completionHandler(-3,self.responseBytes,"no file written")
                }
            } else {
                self.responseCode = -4
                print("Error getting file URL")
                completionHandler(-4,self.responseBytes,"no file written")
            }
            
        }) // task = URLSession
        
        // now that its created, run it via resume
        
        task.resume()
        
    } // download

   
    // given a lat, lon in degrees, of a center point, return
    // the bounding box of lowerLeft, upperRight coordinates in degrees
    // width/length is l
    // divide width/length by 2 so we can calculate half the diagonal
    
    public static func getBoundingBox(centerLat: Double, centerLon: Double, l: Double) -> (Double, Double, Double, Double)
    {
        var llLat, llLon: Double
        var urLat, urLon: Double
        var bearing, arcLen: Double
        var d = sqrt( 2.0 * pow((l/2.0),2.0))
        
        print("Calculating bounding box for \(centerLat),\(centerLon), \(d) ")
        
        let clat = centerLat * (Double.pi / 180.0)
        let clon = centerLon * (Double.pi / 180.0)
        
        print("Hypotenus is \(d)")
        
        // go southwest X meters
        // SW = 225 degrees
        bearing = 225.0 * (Double.pi / 180.0)
        arcLen = d / (6371 * 1000)
        
        var newLat = asin(sin(clat) * cos(arcLen) + cos(clat) * sin(arcLen) * cos(bearing) )
        var newLon = clon + atan2(sin(bearing) * sin(arcLen) * cos(clat), cos(arcLen) - sin(clat) * sin(newLat))
        llLat = newLat * (180.0 / Double.pi)
        llLon = newLon * (180.0 / Double.pi)
        
        // go northeast X meters
        // NE = 45
        bearing = 45.0 * (Double.pi / 180.0)
        newLat = asin(sin(clat) * cos(arcLen) + cos(clat) * sin(arcLen) * cos(bearing) )
        newLon = clon + atan2(sin(bearing) * sin(arcLen) * cos(clat), cos(arcLen) - sin(clat) * sin(newLat))
        urLat = newLat * (180.0 / Double.pi)
        urLon = newLon * (180.0 / Double.pi)

        // truncate to 6 decimal places
        llLat = truncateDouble(val: llLat, precision: 6)
        llLon = truncateDouble(val: llLon, precision: 6)
        urLat = truncateDouble(val: urLat, precision: 6)
        urLon = truncateDouble(val: urLon, precision: 6)
        
        print("Bounding box: (\(llLat),\(llLon)) : (\(urLat),\(urLon))")
        
        return (llLat, llLon, urLat, urLon)
    }
    
    public static func truncateDouble(val: Double, precision: Double) -> Double {
        let num = (val * pow(10,precision)).rounded(.toNearestOrAwayFromZero) / pow(10,precision)
        return num
    }
    
} // DemDownloader
