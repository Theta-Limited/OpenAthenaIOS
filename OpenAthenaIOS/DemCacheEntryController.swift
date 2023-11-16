//
//  DemCacheEntryController.swift
//  OpenAthenaIOS
//
//  Created by Bobby Krupczak on 10/12/23.
//
//  Display elevation model details in a textView
//  window and allow user to click on center point
//  in google maps

import Foundation
import UIKit
import UniformTypeIdentifiers
import CoreServices

class DemCacheEntryController: UIViewController, UIDocumentPickerDelegate
{
    var cacheEntry: DEM_cache_entry!
    var app: AppDelegate = UIApplication.shared.delegate as! AppDelegate
    @IBOutlet var textField: UITextView!
    var documentPicker: UIDocumentPickerViewController?
    
    override func viewDidLoad()
    {
        var htmlString: String
        
        super.viewDidLoad()
        title = "Elevation Map Details"
        view.backgroundColor = .secondarySystemBackground
        //view.overrideUserInterfaceStyle = .light
        
        // add an export button
        navigationItem.rightBarButtonItem = UIBarButtonItem(
                    image: UIImage(systemName: "square.and.arrow.up"),
                                                            style: .plain,
                                                            target: self,
                                                            action: #selector(didTapExport))
        
        let size = cacheEntry.bytes / 1024
        
        // build display to view DEM cache properties
        // load the dem as well as sanity check
        let aDem = DigitalElevationModel(fromURL: cacheEntry.fileURL)
        var demLoaded = true
        if aDem == nil {
            demLoaded = false
        }
        
        textField.isEditable = false
        
        let urlStr = "https://maps.google.com/maps/search/?api=1&t=k&query=\(cacheEntry.cLat),\(cacheEntry.cLon)"
        let coordStr = "\(truncateDouble(val: cacheEntry.cLat, precision: 6)),\(truncateDouble(val: cacheEntry.cLon, precision: 6))"
        
        htmlString = "\(cacheEntry.filename)<br>" +
        "Created: \(cacheEntry.createDate)<br>" +
        "Modified: \(cacheEntry.modDate)<br>" +
        "n: \(truncateDouble(val: cacheEntry.n, precision: 6)) <br>" +
        "s: \(truncateDouble(val: cacheEntry.s, precision: 6)) <br>" +
        "e: \(truncateDouble(val: cacheEntry.e, precision: 6)) <br>" +
        "w: \(truncateDouble(val: cacheEntry.w, precision: 6)) <br>" +
        "length: \(truncateDouble(val: cacheEntry.l, precision: 0)) meters <br>" +
        "center: <a href='\(urlStr)'> \(coordStr) </a><br>" +
        "size: \(size) KBytes <br>" +
        "loaded ok: \(demLoaded)"
        
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
        let data = Data(hString.utf8)
        let font = UIFont.systemFont(ofSize: 14)
        
        if let attribString = try? NSMutableAttributedString(data: data,
                                                           options: [.documentType: NSAttributedString.DocumentType.html],
                                                           documentAttributes: nil) {
            attribString.addAttribute(NSAttributedString.Key.font, value: font, range:                              NSRange(location: 0, length: attribString.length))
            self.textField.attributedText = attribString
        }
    } // setTextViewText
    
}
