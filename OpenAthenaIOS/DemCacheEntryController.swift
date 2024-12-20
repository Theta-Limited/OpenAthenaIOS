// DemCacheEntryController.swift
// OpenAthenaIOS
// Created by Bobby Krupczak on 10/12/23.
// Copyright 2024, Theta Informatics LLC
// AGPLv3
// https://www.gnu.org/licenses/agpl-3.0.txt

// Display elevation model details in a textView
// window and allow user to click on center point
// in google maps

import Foundation
import UIKit
import UniformTypeIdentifiers
import CoreServices
import CoreLocation
import UTMConversion

class DemCacheEntryController: UIViewController, UIDocumentPickerDelegate
{
    var cacheEntry: DEM_cache_entry!
    var app: AppDelegate = UIApplication.shared.delegate as! AppDelegate
    @IBOutlet var textField: UITextView!
    var documentPicker: UIDocumentPickerViewController?
    var htmlString: String = ""
    var vc: ViewController!
    var style: String = ""
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        title = "Elevation Map Details"
        view.backgroundColor = .secondarySystemBackground
        //view.overrideUserInterfaceStyle = .light
        
        style =  "<style>body {font-size: \(app.settings.fontSize); } h1, h2 { display: inline; } </style>"
        
        // add an export button
        navigationItem.rightBarButtonItem = UIBarButtonItem(
                    image: UIImage(systemName: "square.and.arrow.up"),
                                                            style: .plain,
                                                            target: self,
                                                            action: #selector(didTapExport))
        
        //let size = cacheEntry.bytes / 1024
        
        // build display to view DEM cache properties
        // load the dem as well as sanity check
        let aDem = DigitalElevationModel(fromURL: cacheEntry.fileURL)
        var demLoaded = true
        if aDem == nil {
            demLoaded = false
        }
        
        textField.isEditable = false
        let latStr = "\(cacheEntry.cLat)"
        let lonStr = "\(cacheEntry.cLon)"
        let urlStr = LoadCalculateViewController.getMapsUrlStr(latStr: latStr, lonStr: lonStr)
        //let urlStr = "https://maps.google.com/maps/search/?api=1&t=k&query=\(cacheEntry.cLat),\(cacheEntry.cLon)"
        
        let coordStr = "\(truncateDouble(val: cacheEntry.cLat, precision: 6)),\(truncateDouble(val: cacheEntry.cLon, precision: 6))"
        
        htmlString = "\(style)\(cacheEntry.filename)<br>" +
        "Created: \(cacheEntry.createDate)<br>" +
        "Modified: \(cacheEntry.modDate)<br>"
        
        // re issue #42 display coordinates in measurement system according to settings
        
        if app.settings.outputMode == .WGS84 {
            htmlString += 
                "n: \(truncateDouble(val: cacheEntry.n, precision: 6)) <br>" +
                "s: \(truncateDouble(val: cacheEntry.s, precision: 6)) <br>" +
                "e: \(truncateDouble(val: cacheEntry.e, precision: 6)) <br>" +
                "w: \(truncateDouble(val: cacheEntry.w, precision: 6)) <br>" +
                "center: <a href='\(urlStr)'> \(coordStr) </a><br>"
        }
        if app.settings.outputMode == .UTM {
            // upper left
            var coord = CLLocationCoordinate2D(latitude: cacheEntry.n, longitude: cacheEntry.w)
            var aUTM = coord.utmCoordinate()
            htmlString += "nw: \(LoadCalculateViewController.utmToString(coord: aUTM))<br>"
            
            // upper right
            coord = CLLocationCoordinate2D(latitude: cacheEntry.n, longitude: cacheEntry.e)
            aUTM = coord.utmCoordinate()
            htmlString += "ne: \(LoadCalculateViewController.utmToString(coord: aUTM))<br>"
            
            // lower left
            coord = CLLocationCoordinate2D(latitude: cacheEntry.s, longitude: cacheEntry.w)
            aUTM = coord.utmCoordinate()
            htmlString += "sw: \(LoadCalculateViewController.utmToString(coord: aUTM))<br>"

            // lower right
            coord = CLLocationCoordinate2D(latitude: cacheEntry.s, longitude: cacheEntry.e)
            aUTM = coord.utmCoordinate()
            htmlString += "se: \(LoadCalculateViewController.utmToString(coord: aUTM))<br>"
        }
        if app.settings.outputMode == .MGRS {
            // upper left
            var mgrsStr = MGRSGeodetic.WGS84_MGRS1m(Lat: cacheEntry.n, Lon: cacheEntry.w, Alt: 0.0)
            var mgrsSplitStr = MGRSGeodetic.splitMGRS(mgrs: mgrsStr)
            htmlString += "nw: \(mgrsSplitStr)<br>"
            
            // upper right
            mgrsStr = MGRSGeodetic.WGS84_MGRS1m(Lat: cacheEntry.n, Lon: cacheEntry.e, Alt: 0.0)
            mgrsSplitStr = MGRSGeodetic.splitMGRS(mgrs: mgrsStr)
            htmlString += "ne: \(mgrsSplitStr)<br>"
            
            // lower left
            mgrsStr = MGRSGeodetic.WGS84_MGRS1m(Lat: cacheEntry.s, Lon: cacheEntry.w, Alt: 0.0)
            mgrsSplitStr = MGRSGeodetic.splitMGRS(mgrs: mgrsStr)
            htmlString += "sw: \(mgrsSplitStr)<br>"

            // lower right
            mgrsStr = MGRSGeodetic.WGS84_MGRS1m(Lat: cacheEntry.s, Lon: cacheEntry.e, Alt: 0.0)
            mgrsSplitStr = MGRSGeodetic.splitMGRS(mgrs: mgrsStr)
            htmlString += "se: \(mgrsSplitStr)<br>"
        }
        if app.settings.outputMode == .CK42Geodetic {
            var ck42lat, ck42lon, ck42alt: Double
            var ck42latStr, ck42lonStr: String
            
            // upper left
            (ck42lat,ck42lon,ck42alt) = CK42Geodetic.WGS84_CK42(Bd: cacheEntry.n, Ld: cacheEntry.w, H: 0.0)
            ck42latStr = LoadCalculateViewController.roundDigitsToString(val: ck42lat, precision: 6)
            ck42lonStr = LoadCalculateViewController.roundDigitsToString(val: ck42lon, precision: 6)
            htmlString += "nw: \(ck42latStr),\(ck42lonStr)<br>"
            // upper right
            (ck42lat,ck42lon,ck42alt) = CK42Geodetic.WGS84_CK42(Bd: cacheEntry.n, Ld: cacheEntry.e, H: 0.0)
            ck42latStr = LoadCalculateViewController.roundDigitsToString(val: ck42lat, precision: 6)
            ck42lonStr = LoadCalculateViewController.roundDigitsToString(val: ck42lon, precision: 6)
            htmlString += "ne: \(ck42latStr),\(ck42lonStr)<br>"
            // lower left
            (ck42lat,ck42lon,ck42alt) = CK42Geodetic.WGS84_CK42(Bd: cacheEntry.s, Ld: cacheEntry.w, H: 0.0)
            ck42latStr = LoadCalculateViewController.roundDigitsToString(val: ck42lat, precision: 6)
            ck42lonStr = LoadCalculateViewController.roundDigitsToString(val: ck42lon, precision: 6)
            htmlString += "sw: \(ck42latStr),\(ck42lonStr)<br>"
            // lower right
            (ck42lat,ck42lon,ck42alt) = CK42Geodetic.WGS84_CK42(Bd: cacheEntry.s, Ld: cacheEntry.e, H: 0.0)
            ck42latStr = LoadCalculateViewController.roundDigitsToString(val: ck42lat, precision: 6)
            ck42lonStr = LoadCalculateViewController.roundDigitsToString(val: ck42lon, precision: 6)
            htmlString += "se: \(ck42latStr),\(ck42lonStr)<br>"
        }
        if app.settings.outputMode == .CK42GaussKruger {
            var ck42lat, ck42lon, ck42alt: Double
            var ck42gklatStr, ck42gklonStr: String
            var ck42gklat, ck42gklon: Int64
            
            // upper left
            (ck42lat,ck42lon,ck42alt) = CK42Geodetic.WGS84_CK42(Bd: cacheEntry.n, Ld: cacheEntry.w, H: 0.0)
            (ck42gklat,ck42gklon) = CK42GaussKruger.CK42_to_GaussKruger(CK42_LatDegrees: ck42lat, CK42_LonDegrees: ck42lon)
            ck42gklatStr = "\(ck42gklat)"
            ck42gklonStr = "\(ck42gklon)"
            htmlString += "nw: \(ck42gklatStr),\(ck42gklonStr)<br>"
            // upper right
            (ck42lat,ck42lon,ck42alt) = CK42Geodetic.WGS84_CK42(Bd: cacheEntry.n, Ld: cacheEntry.e, H: 0.0)
            (ck42gklat,ck42gklon) = CK42GaussKruger.CK42_to_GaussKruger(CK42_LatDegrees: ck42lat, CK42_LonDegrees: ck42lon)
            ck42gklatStr = "\(ck42gklat)"
            ck42gklonStr = "\(ck42gklon)"
            htmlString += "ne: \(ck42gklatStr),\(ck42gklonStr)<br>"
            // lower left
            (ck42lat,ck42lon,ck42alt) = CK42Geodetic.WGS84_CK42(Bd: cacheEntry.s, Ld: cacheEntry.w, H: 0.0)
            (ck42gklat,ck42gklon) = CK42GaussKruger.CK42_to_GaussKruger(CK42_LatDegrees: ck42lat, CK42_LonDegrees: ck42lon)
            ck42gklatStr = "\(ck42gklat)"
            ck42gklonStr = "\(ck42gklon)"
            htmlString += "sw: \(ck42gklatStr),\(ck42gklonStr)<br>"
            // lower right
            (ck42lat,ck42lon,ck42alt) = CK42Geodetic.WGS84_CK42(Bd: cacheEntry.s, Ld: cacheEntry.e, H: 0.0)
            (ck42gklat,ck42gklon) = CK42GaussKruger.CK42_to_GaussKruger(CK42_LatDegrees: ck42lat, CK42_LonDegrees: ck42lon)
            ck42gklatStr = "\(ck42gklat)"
            ck42gklonStr = "\(ck42gklon)"
            htmlString += "se: \(ck42gklatStr),\(ck42gklonStr)<br>"
        }
        
        // meters or feet?
        if app.settings.unitsMode == .Metric {
            htmlString += "length: \(truncateDouble(val: cacheEntry.l, precision: 0)) meters <br>"
        }
        else {
            htmlString += "length: \(truncateDouble(val: app.metersToFeet(meters: cacheEntry.l), precision: 0)) ft<br>"
        }

        htmlString += "size: \(app.formatSize(bytes: cacheEntry.bytes))<br>"
        htmlString += "loaded ok: \(demLoaded)"
        
        setTextViewText(htmlStr: htmlString)
    }

    // export this file to somewhere else
    @objc private func didTapExport()
    {
        // pick destination directory
        // then use filemanager
        if documentPicker == nil {
            
            //let dTypes = [ UTType.folder, UTType.volume, UTType.mountPoint]
            // if we just choose folder, we can save to folder but
            // it won't let us choose folders on network storage like iCloud, owncloud
            // if we add volume and mountpoint types, we can browse them but can't
            // chose folders to open/save to.  Ugh. XXX
            
            let dTypes = [ UTType.folder]
            documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: dTypes )
            documentPicker!.delegate = self
            documentPicker!.modalPresentationStyle = .formSheet
        }
        
        self.present(documentPicker!, animated: true, completion: nil)
    }
    
    public func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        
        guard let destFolderURL = urls.first else {
            print("Failed to pick folder to export to")
            return
        }
        
        print("Document picker selected folder \(destFolderURL)")
        let destinationURL = destFolderURL.appendingPathComponent(cacheEntry.filename+".tiff")
        
        if FileManager.default.isReadableFile(atPath: destFolderURL.path) == false {
            guard destFolderURL.startAccessingSecurityScopedResource() else {
                // raise error
                print("Don't have permission to access ")
                var alert = UIAlertController(title: "Elevation model export", message: "Insufficent permissions to export here", preferredStyle: .alert)
                var ok = UIAlertAction(title: "OK", style: .default, handler: nil)
                alert.addAction(ok)
                self.present(alert, animated: true)
                return
            }
        }
        
        do {
            // copy will fail if file already exists; try to remove the file from
            // destination and ignore if remove fails because it doesnt exist; then
            // copy
            try? FileManager.default.removeItem(at: destinationURL)
            try FileManager.default.copyItem(at: cacheEntry.fileURL, to: destinationURL)
            print("File copied/exported!")
            //self.app.sendNotification(title: "Elevation model export",
            //                          text: "\(cacheEntry.filename)")
            var alert = UIAlertController(title: "Elevation model exported successfully",
                                          message: "\(cacheEntry.filename)",
                                          preferredStyle: .alert)
            var ok = UIAlertAction(title: "OK", style: .default, handler: nil)
            alert.addAction(ok)
            self.present(alert, animated: true)
            
        }
        catch {
            print("Error copying file \(error)")
            //self.app.sendNotification(title: "Elevation model export",
             //                         text: "Export failed \(error)")
            var alert = UIAlertController(title: "Elevation model export",
                                          message: "Export failed \(error)",
                                          preferredStyle: .alert)
            var ok = UIAlertAction(title: "OK", style: .default, handler: nil)
            alert.addAction(ok)
            self.present(alert, animated: true)
            
        }
        
    }
    
    public func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        dismiss(animated: true, completion: nil)
    }
    
    private func truncateDouble(val: Double, precision: Double) -> Double {
        let num = (val * pow(10,precision)).rounded(.toNearestOrAwayFromZero) / pow(10,precision)
        return num
    }

    // take htmlString and encode it and set
    // it to our textView
    private func setTextViewText(htmlStr hString: String)
    {
        // to avoid crashing due to NSInternalConsistencyException, don't set
        // on calling thread; dispatch to main async
        // re issue #37
        DispatchQueue.main.async {
            if let attribString = self.vc.htmlToAttributedString(fromHTML: hString) {
                self.textField.attributedText = attribString
            }
        }
        
    } // setTextViewText
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?)
    {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if self.traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
           setTextViewText(htmlStr: htmlString)
        }
    }
}
