//
//  NewDemController.swift
//  OpenAthenaIOS
//
//  Created by Bobby Krupczak on 10/12/23.
//
//  Screen for creating a new elevation model via
//  download from internet or import from file

import UIKit
import Foundation
import UniformTypeIdentifiers

class NewDemController: UIViewController, UIDocumentPickerDelegate
{
    @IBOutlet var latLonField: UITextField!
    @IBOutlet var diameterField: UITextField!
    @IBOutlet var resultLabel: UILabel!
    var app: AppDelegate = UIApplication.shared.delegate as! AppDelegate
    var documentPicker: UIDocumentPickerViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "New Elevation Map"

        // Do any additional setup after loading the view.
    }
    
    @IBAction func didTapFetch()
    {
        var latLonStr = latLonField.text
        // google paste can add () around coordinates; strip them off
        latLonStr = latLonStr?.replacingOccurrences(of: "(", with: "")
        latLonStr = latLonStr?.replacingOccurrences(of: ")", with: "")
        let pieces = latLonStr!.components(separatedBy: ",")
        if pieces.count == 2 {
            
            let lat = (pieces[0] as! NSString).doubleValue
            let lon = (pieces[1] as! NSString).doubleValue
            // remove meters if present
            var lStr = diameterField.text
            lStr = lStr?.replacingOccurrences(of: "meters", with: "")
            let l = (lStr as! NSString).doubleValue
            
            resultLabel.text = "Going to fetch elevation map . . ."
            //resultLabel.text = "\(lat),\(lon) x \(l)"
            
            let aDownloader = DemDownloader(lat: lat, lon: lon, length: l)
            aDownloader.download(completionHandler: downloadComplete)
        }
        
    } // didTapFetch
    
    // import a DEM from local storage perhaps in "Files" or elsewhere
    // then save it in our local sandbox storage using our naming
    // convention XXX
    
    @IBAction func didTapImport()
    {
        // add once integrated into OAiOS
        print("Import a DEM from local device files")
        
        resultLabel.text = "Importing an elevation model"
        
        if documentPicker == nil {
            
            let dTypes = [ UTType.tiff ]
            documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: dTypes)
            documentPicker!.delegate = self
            documentPicker!.modalPresentationStyle = .formSheet
        }
        
        self.present(documentPicker!, animated: true, completion: nil)
    }
    
    public func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let importFileURL = urls.first else {
            print("Failed to pick file to import")
            self.resultLabel.text = "Failed to pick file to import"
            return
        }
        
        if FileManager.default.isReadableFile(atPath: importFileURL.path) == false {
            guard importFileURL.startAccessingSecurityScopedResource() else {
                print("Dont have file permission to import")
                self.resultLabel.text = "Don't have permission to access file"
                return
            }
        }
        
        do {
            // load the DEM first to get its parameters
            // calculate bounding box, height/width; not guaranteed to be
            // a square though
            
            print("Importing elevation model from \(importFileURL)")
            
            // save into our local storage using our filenaming convention
            // for easy manipulation
            
            let aDem = DigitalElevationModel(fromURL: importFileURL)
            if aDem  == nil {
                // failed to load
                resultLabel.text = "Failed to load elevation model to import"
                return
            }
            print("Loaded DEM \(aDem!.getCenter() )\(aDem!.getDemHeight()), (aDem!.getDemWidth()")
            
            var n = aDem!.getMaxLatitude()
            n = DemDownloader.truncateDouble(val: n, precision: 6)
            var s = aDem!.getMinLatitude()
            s = DemDownloader.truncateDouble(val: s, precision: 6)
            var w = aDem!.getMinLongitude()
            w = DemDownloader.truncateDouble(val: w, precision: 6)
            var e = aDem!.getMaxLongitude()
            e = DemDownloader.truncateDouble(val: e, precision: 6)
            let filenameStr = "DEM_LatLon_" + "\(s)_\(w)" + "_" +
                "\(n)_\(e)" +
                ".tiff"
            print("Going to import to \(filenameStr)")
            
            if let destFileURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent(filenameStr) {
                do {
                    try? FileManager.default.removeItem(at: destFileURL)
                    try FileManager.default.copyItem(at: importFileURL, to: destFileURL)
                    
                    print("Elevation data written to \(filenameStr)")
                    resultLabel.text = "Elevation model successfully imported"
                }
                catch {
                    print("Error writing data to file \(error)")
                    self.resultLabel.text = "Error writing elevation data to file \(error)"
                }
                
            }
            
        }
        catch {
            print("Error importing elevation model")
            self.resultLabel.text = "Error importing file \(error)"
        }
        
    } // documentPicker import
    
    public func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        dismiss(animated: true, completion: nil)
    }
    
    public func downloadComplete(resultCode: Int, bytes: Int, filename: String)
    {
        // send notification when complete because download happened
        // in background
        print("Download complete \(resultCode) \(bytes)")
        DispatchQueue.main.async {
            self.resultLabel.text = "Download result \(resultCode), bytes \(bytes)"
            self.app.sendNotification(title: "Download Result",
                                     text: "Download result \(resultCode), \(bytes) bytes, \(filename)")
        }
    }

} // NewDemController
