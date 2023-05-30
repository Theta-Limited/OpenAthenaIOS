//
//  DebugViewController.swift
//  OpenAthenaIOS
//  https://github.com/rdkgit/OpenAthenaIOS
//  https://openathena.com
//  Created by Bobby Krupczak on 2/3/23.
//

import Foundation
import UIKit

class DebugViewController: UIViewController, UIScrollViewDelegate {
    
    var app: AppDelegate = UIApplication.shared.delegate as! AppDelegate
    var textView: UITextView = UITextView()
    var stackView: UIStackView = UIStackView()
    var scrollView: UIScrollView = UIScrollView()
    var contentView: UIView = UIView()
    var vc: ViewController!
    var htmlString: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "OpenAthena Debug"
        view.backgroundColor = .white
        
        // build the view
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        textView.isEditable = false
        textView.isSelectable = true
        textView.isScrollEnabled = false
        textView.font = .systemFont(ofSize: 16)
        
        scrollView.frame = view.bounds
        scrollView.zoomScale = 1.0
        scrollView.maximumZoomScale = 5.0
        scrollView.minimumZoomScale = 0.5
        scrollView.delegate = self
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.isUserInteractionEnabled = true
        
        htmlString = "Debug information<br>"
        setTextViewText(htmlStr: htmlString)
        
        stackView.frame = scrollView.bounds
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.distribution = .fillProportionally
        stackView.spacing = 5
        
        stackView.addArrangedSubview(textView)
        contentView.addSubview(stackView)
        scrollView.addSubview(contentView)
        view.addSubview(scrollView)
        
        // set constraints
        
        textView.heightAnchor.constraint(equalToConstant: 1.0*view.frame.size.height).isActive = true
        
        scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor).isActive = true
        scrollView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor).isActive = true
        scrollView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor).isActive = true
        
        contentView.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor).isActive = true
        
        contentView.topAnchor.constraint(equalTo: scrollView.topAnchor).isActive = true
        contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor).isActive = true
        contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor).isActive = true
        contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor).isActive = true
        
        stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
        stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor).isActive = true
        stackView.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
        
        debug()
        
    } //viewDidLoad
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return contentView
    }
    
    private func debug()
    {
        self.htmlString = "<b>OpenAthena Debug Info \(vc.getAppVersion())</b><br>"
        self.htmlString += "Coordinate system \(app.settings.outputMode)<br>"
        self.htmlString += "Drone params date: \(vc.droneParams!.droneParamsDate)<br>"
        self.htmlString += "CCD data for \(vc.droneParams!.droneCCDParams.count) drones<br>"
        
        if vc.dem != nil {
            self.htmlString += "<br><b>DEM:</b> \((vc.dem!.tiffURL!.lastPathComponent))<br>"
            self.htmlString += "Width:\(vc.dem!.getDemWidth()) Height:\(vc.dem!.getDemHeight())<br>"
            self.htmlString += "Rasters: W:\(vc.dem!.rasters!.width()) H:\(vc.dem!.rasters!.height())<br>"
            self.htmlString += "Rasters: Pixels:\(vc.dem!.rasters!.numPixels()) S/P:\(vc.dem!.rasters!.samplesPerPixel())<br>"
            self.htmlString += "Rasters: SizePixel:\(vc.dem!.rasters!.sizePixel()) bytes<br>"
            self.htmlString += "TiePoint: \(vc.dem!.directory!.modelTiepoint()!))<br>"
            self.htmlString += "Bounding box:<br>"
            self.htmlString += "Upper left ( \(vc.dem!.getMaxLatitude()),\(vc.dem!.getMinLongitude()) )<br>"
            self.htmlString += "Lower left ( \(vc.dem!.getMinLatitude()),\(vc.dem!.getMinLongitude()) )<br>"
            self.htmlString += "Upper right ( \(vc.dem!.getMaxLatitude()),\(vc.dem!.getMaxLongitude()) )<br>"
            self.htmlString += "Lower right ( \(vc.dem!.getMinLatitude()),\(vc.dem!.getMaxLongitude()) )<br>"
            
            var centerLat,centerLon : Double
            (centerLat,centerLon) = vc.dem!.getCenter()
            
            let urlStr = "https://maps.google.com/maps/search/?api=1&t=k&query=\(centerLat),\(centerLon)"
            self.htmlString += "<a href='\(urlStr)'>\(urlStr)</a><br>"
        }
        
        if vc.theDroneImage != nil {
            self.htmlString += "<br><b>Drone Image:</b> \(vc.theDroneImage!.name)<br>"
            do {
                var lat = try self.vc.theDroneImage!.getLatitude()
                var lon = try self.vc.theDroneImage!.getLongitude()
                self.htmlString += "Latitude: \(lat)<br>"
                self.htmlString += "Longitude: \(lon)<br>"
                let urlStr = "https://maps.google.com/maps/search/?api=1&t=k&query=\(lat),\(lon)"
                self.htmlString += "<a href='\(urlStr)'>\(urlStr)</a><br>"
                try self.htmlString += "Make: \(vc.theDroneImage!.getCameraMake())<br>"
                try self.htmlString += "Model: \(vc.theDroneImage!.getCameraModel())<br>"
                try self.htmlString += "Software version: \(vc.theDroneImage!.getMetaDataValue(key: "drone-parrot:SoftwareVersion"))<br>"
                
            }
            catch {
                self.htmlString += "Some meta data missing \(error)<br>"
            }
            self.htmlString += "<br>aux:Lens \(vc.theDroneImage!.metaData!["aux:Lens"])<br>"
            
            self.htmlString += "<br>MetaData: \(vc.theDroneImage!.metaData!)<br>"
            self.htmlString += "<br>RawMetaData: \(vc.theDroneImage!.rawMetaData!)<br>"
            self.htmlString += "<br>Xmp/Xml: \(vc.theDroneImage!.xmlString)<br>"
        }
        
        // display the text finally!
        setTextViewText(htmlStr: self.htmlString)
        
    }
    
    // take htmlString and encode it and set
    // it to our textView
    private func setTextViewText(htmlStr hString: String)
    {
        let data = Data(hString.utf8)
        if let attribString = try? NSAttributedString(data: data,
                                                           options: [.documentType: NSAttributedString.DocumentType.html],
                                                           documentAttributes: nil) {
            self.textView.attributedText = attribString
        }
    }
    
} // DebugViewController
