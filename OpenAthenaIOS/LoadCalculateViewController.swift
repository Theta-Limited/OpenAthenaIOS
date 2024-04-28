//
//  LoadCalculateViewController.swift
//  OpenAthenaIOS
//
//  Created by Bobby Krupczak on 3/13/24.
//  Load and calculate all within a single view controller
//  in order to simplify the UI and align it more closely
//  with Android version of OA
//  Essentially combine ImageViewController and
//  CalculateViewController into single view controller
//  and handle everything in a single view
//  We leave ImageViewController and CalculateViewController
//  in the code base so that we can refer back to them and/or
//  change back to them.

import Foundation
import UIKit
import UniformTypeIdentifiers
import ImageIO
import MobileCoreServices
import UTMConversion
import CoreLocation
import mgrs_ios

class LoadCalculateViewController: UIViewController,
                                    UIImagePickerControllerDelegate, 
                                    UINavigationControllerDelegate,
                                    UIScrollViewDelegate
{
    var app: AppDelegate = UIApplication.shared.delegate as! AppDelegate
    var vc: ViewController!
    var imageView: UIImageView = UIImageView()
    var textView: UITextView = UITextView()
    var stackView: UIStackView = UIStackView()
    var scrollView: UIScrollView = UIScrollView()
    var selectButton: UIButton = UIButton(type: .system)
    var contentView: UIView = UIView()
    var htmlString: String = ""
    var imagePicker: UIImagePickerController?
    var style: String = ""
    var cotSender: CursorOnTargetSender? = nil
    var adjustedAlt: Double = 0.0
    var target: [Double] = [0,0,0,0, 0,0,0,0, 0]
    var actionSendCoT: UIAction? = nil
    var actionResetPtr: UIAction? = nil
    var activityIndicator: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // set html style
        style = "<style>body {font-size: \(app.settings.fontSize); } h1, h2 { display: inline; } </style>"

        self.title = "Analyze"
        view.backgroundColor = .secondarySystemBackground
        
        // add settings and others to hamburger menu
        configureMenuItems()
        
        // build our view/display
        
        scrollView.frame = view.bounds
        scrollView.zoomScale = 1.0
        scrollView.maximumZoomScale = 5.0
        scrollView.minimumZoomScale = 0.5
        scrollView.delegate = self
        scrollView.isUserInteractionEnabled = true
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.backgroundColor = .secondarySystemBackground
        
        contentView.translatesAutoresizingMaskIntoConstraints = false

        // image setup
        imageView.contentMode = .scaleAspectFit
        if vc.theDroneImage != nil {
            imageView.image = vc.theDroneImage?.theImage
        }
        let singleTap = UITapGestureRecognizer(target: self, action: #selector(didTapImage))
        imageView.addGestureRecognizer(singleTap)
        imageView.isUserInteractionEnabled = true
        
        textView.isSelectable = true
        textView.isEditable = false
        textView.isScrollEnabled = true // ???
        textView.font = .systemFont(ofSize: 16)
        htmlString = "\(style)Select a drone image<br>"
        setTextViewText(htmlStr: htmlString)
        textView.backgroundColor = .secondarySystemBackground
        
        // button setup
        // we can choose from several different pickers  -- photo, document, image
        // image seems to be the one we want
        // selectButton.backgroundColor = .systemYellow
        selectButton.setTitle("Select Drone Image \u{1F5bc}", for: .normal)
        selectButton.addTarget(self, action: #selector(didTapSelectImage), for: .touchUpInside)
        selectButton.layer.cornerRadius = 3.0
        selectButton.clipsToBounds = true
        
        // stackview setup
        stackView.frame = view.bounds
        stackView.axis = .vertical
        stackView.distribution = .fillProportionally
        //stackView.distribution = .fillEqually
        //stackView.distribution = .equalSpacing
        stackView.spacing = 5
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        stackView.addArrangedSubview(selectButton)
        stackView.addArrangedSubview(imageView)
        stackView.addArrangedSubview(textView)
        
        if vc.theDroneImage != nil {
            imageView.image = vc.theDroneImage?.theImage
            // mark the image as its already been selected previously
            // re issue #35
            markImagePixel(x_prop: vc.theDroneImage!.targetXprop, y_prop: vc.theDroneImage!.targetYprop)
        }
        
        contentView.addSubview(stackView)
        scrollView.addSubview(contentView)
        view.addSubview(scrollView)
        
        // set up layout constraints
        // set constraints
        selectButton.heightAnchor.constraint(equalToConstant: 0.1*view.frame.size.height).isActive = true
        textView.heightAnchor.constraint(equalToConstant: 0.45*view.frame.size.height).isActive = true
        imageView.heightAnchor.constraint(equalToConstant: 0.45*view.frame.size.height).isActive = true

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
                
    } // viewDidLoad
    
    // re issue #36, don't forget this function so that we can pinch/zoom
    // the image
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return contentView
    }
    
    // when view is set to appear, reset the htmlString
    // if we go forward to calculate then back to selectImage,
    // viewDidLoad may not be called again and then we
    // run into scrolling issue
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        
        print("LoadCalculateViewController: viewWillAppear starting")
        
        // create a cursor on target sender and pass Athena settings
        cotSender = CursorOnTargetSender(params: app.settings)
        
        doCalculations(altReference: DroneTargetResolution.AltitudeFromGPS)
         
    } // willAppear
    
    override func viewWillDisappear(_ animated: Bool)
    {
        super.viewWillDisappear(animated)
        print("LoadCalculate viewWillDisappear")
        if cotSender != nil {
            cotSender?.close()
        }
    }
    
    // select an image and then kick off calculations
    @IBAction func didTapSelectImage()
    {
        if imagePicker == nil {
            imagePicker = UIImagePickerController()
            imagePicker?.sourceType = .photoLibrary
            imagePicker?.delegate = self
            imagePicker?.allowsEditing = false
        }
        present(imagePicker!, animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any])
    {
        // immediately dismiss so we can present alerts if needed
        imagePicker!.dismiss(animated: true, completion: nil)

        var imageURL = info[UIImagePickerController.InfoKey(rawValue: "UIImagePickerControllerImageURL")] as? URL
        
        if imageURL != nil {
            // reset htmlString here
            htmlString = "\(style)<b>OpenAthena</b><br>Loading image<br>"
            print("Image url is \(imageURL!)")
            // toss any existing DEM so we force calculation code to reload
            // a new DEM
            vc.dem = nil
            
            do {
                
                var anImage = createDroneImage(imageURL: imageURL!)

                // no need to save image directory since imagepicker
                // will save this for us
                // self.vc.theDroneImage!.updateMetaData()
                
                getImageData()
                
                // check for DEM and load if necessary
                // if lat,lon == 0.0,0.0 don't bother XXX
                let result = findLoadElevationMap()
                htmlString += "Found elevation map: \(result)<br>"
                
                do {
                    let groundAlt = try self.vc.dem?.getAltitudeFromLatLong(
                        targetLat: self.vc.theDroneImage!.getLatitude(),
                        targetLong: self.vc.theDroneImage!.getLongitude())
                    // re issue #30, round degrees to 6 and distance/alt to 0
                    var groundAltStr = roundDigitsToString(val: groundAlt ?? -1.0, precision: 0)
                    if app.settings.unitsMode == .Metric {
                        self.htmlString += "Ground altitude under drone is \(groundAltStr)m (hae)<br>"
                    }
                    else {
                        let groundAltFt = app.metersToFeet(meters: groundAlt ?? -1.0)
                        groundAltStr = roundDigitsToString(val: groundAltFt , precision: 0)
                        self.htmlString += "Ground altitude under drone is \(groundAltStr)ft (hae)<br>"
                    }
                }
                
            }
            catch {
                // error!
                htmlString += "Loading image resulted in error \(error)<br>"
            }
        }
        else {
            // raise error
            print("Not able to access image URL")
            htmlString += "Not able to access image URL<br>"
        }
        
        if vc.theDroneImage != nil {
            markImagePixel(x_prop: vc.theDroneImage!.targetXprop, y_prop: vc.theDroneImage!.targetYprop)
        }
        
        // Now, do the calculations if possible
        if vc.dem != nil && vc.theDroneImage != nil {
            doCalculations(altReference: DroneTargetResolution.AltitudeFromGPS)
        }
        
        setTextViewText(htmlStr: htmlString)
                
    } // imagePicker
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController)
    {
        picker.dismiss(animated: true, completion: nil)
    }
    
    // create our main menu and glue it into navigation controller
    private func configureMenuItems()
    {
        //print("Configuring menus on calculate screen")
        // create my own access to storyboard here since I didnt explicitly
        // set up the storyboard plumbing when I created this class in Xcode
        // I shoulda created this class as a File -> New -> File -> Cocoa Touch Class, Swift/Storyboard
        
        // uiactions have states
        // we can also selectively change the options menu periodically
        // to add or remove different options based on whether an
        // image is loaded yet XXX
        
        let aStoryboard = UIStoryboard(name: "Main", bundle: nil)
        
        actionSendCoT = UIAction(title:"Send CoT", image: UIImage(systemName: "target"), handler: { _ in

            // grab target info out of target[] array
            // get image date/time in iso8601/UTC format
            if self.vc.theDroneImage == nil || self.vc.dem == nil {
                return
            }
            
            let imageISO = self.vc.theDroneImage!.getDateTimeUTC()
                            
            let ret = self.cotSender?.sendCoT(targetLat: self.target[1], targetLon: self.target[2],
                                              // adjusted alt of target
                                              // Hae: self.target[8],
                                              Hae: self.target[3],
                                              Theta: self.target[5],
                                              exifDateTimeISO: imageISO)
            
            // if CoT sent, give some sorta notification XXX
            if ret == false {
                self.htmlString += "CoT send failed \(self.getCurrentLocalTime())<br>"
            }
            else {
                self.htmlString += "CoT sent \(self.getCurrentLocalTime())<br>"
            }
            self.setTextViewText(htmlStr: self.htmlString)
        })
        
        actionResetPtr = UIAction(title:"Reset pointer", image: UIImage(systemName:"arrow.clockwise"), handler: {_ in
            //print("Reset pointer")
            // reset pointer back to 50% 50%
            if self.vc.theDroneImage != nil && self.vc.dem != nil {
                self.unMarkImagePixel()
                self.vc.theDroneImage!.targetXprop =  0.50
                self.vc.theDroneImage!.targetYprop = 0.50
                self.markImagePixel(x_prop: self.vc.theDroneImage!.targetXprop, y_prop: self.vc.theDroneImage!.targetYprop)
                
                // recalculate new target location
                
                self.doCalculations(altReference: DroneTargetResolution.AltitudeFromGPS)
            }
        })
        
        // set these based on whether
        // there is an image or not
        if vc.theDroneImage == nil {
            actionResetPtr!.attributes = [.disabled]
        }
        if vc.dem == nil {
            actionSendCoT!.attributes = [.disabled]
        }
        
        let optionsMenu = UIMenu(title: "", children: [
            UIAction(title:"Settings", image: UIImage(systemName:"gear.circle")) {
                action in
                //print("Settings")
                //let vc = self.storyboard?.instantiateViewController(withIdentifier: "Settings") as! SettingsViewController
                let vc = SettingsViewController()
                vc.vc = self.vc
                self.navigationController?.pushViewController(vc, animated: true)
            },
            UIAction(title:"About", image: UIImage(systemName:"info.circle")) {
                action in
                print("LoadCalculate invoking AboutViewController")
                let vc = aStoryboard.instantiateViewController(withIdentifier: "About") as! AboutViewController
                vc.vc = self.vc
                self.navigationController?.pushViewController(vc, animated: true)
            },
            UIAction(title:"Manage Elevation Maps", image: UIImage(systemName:"map")) {
                action in
                print("LoadCaclulate invoking Manage elevation maps")
                let vc = aStoryboard.instantiateViewController(withIdentifier: "ManageDemViewController") as! ManageDemViewController
                vc.vc = self.vc
                self.navigationController?.pushViewController(vc, animated: true)
            },
            UIAction(title:"Debug", image: UIImage(systemName:"binoculars.fill")) {
                action in
                //print("Debug")
                let vc = aStoryboard.instantiateViewController(withIdentifier: "Debug") as! DebugViewController
                vc.vc = self.vc
                self.navigationController?.pushViewController(vc, animated: true)
            },
            actionResetPtr!,
            actionSendCoT!
        ])
            
        // line.3.horizontal is only available in iOS 15+
        // we exported it and added it to our project
        let aButton = UIBarButtonItem(image: UIImage(systemName: "line.horizontal.3"),
                                      primaryAction: nil,
                                      menu: optionsMenu)
        // line.3.horizontal only available iOS 15+
        // line.horizontal.3 available iOS 13+
        // Argggghhh
        
        navigationItem.rightBarButtonItem = aButton
        
    } // configure menu items
    
    // create a drone image or subclass based on the image
    // and manufacturer; kinda a chicken and egg
    // in that we have to fetch some metadata
    // to make the determination
    // not all the EXIFF data is retrieved by
    // the ios/swift libs so we use tiff:Make
    // instead of exif.image.make
    
    func createDroneImage(imageURL: URL) -> DroneImage?
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
                self.vc.theDroneImage = DroneImageDJI()
            case let str where str.contains("skydio"):
                self.vc.theDroneImage = DroneImageSkydio()
            case let str where str.contains("parrot"):
                self.vc.theDroneImage = DroneImageParrot()
            case let str where str.contains("autel"):
                self.vc.theDroneImage = DroneImageAutel()
            default: // all else including unknown
                self.vc.theDroneImage = DroneImage()
            }
            self.vc.theDroneImage!.rawData = data
            self.vc.theDroneImage!.theImage = image
            self.vc.theDroneImage!.name = imageURL.lastPathComponent
            self.vc.theDroneImage!.droneParams = self.vc.droneParams
            self.vc.theDroneImage!.settings = app.settings
            imageView.image = image
            self.vc.theDroneImage!.updateMetaData()
            
            return nil
        }
        catch {
            // error!
            htmlString += "Loading image resulted in error \(error)<br>"
        }
        
        return nil
        
    } // createDroneImage
    
    // get meta data from image and output to textView
    
    private func getImageData()
    {
        var lat, lon: Double
        
        //print("getImageData: starting")
        
        if vc.theDroneImage == nil {
            return
        }
        
        do {
            //self.htmlString += "Image date: \(self.vc.theDroneImage!.getDateTimeUTC())<br>"
            try self.htmlString += "Camera make is: \(self.vc.theDroneImage!.getCameraMake())<br>"
        }
        catch {
            self.htmlString += "Camera make is: \(error)<br>"
        }
        
        do {
            // handle lat,lon together because typically images
            // will have both or have neither
            try lat = self.vc.theDroneImage!.getLatitude()
            try lon = self.vc.theDroneImage!.getLongitude()
            let latStr = roundDigitsToString(val: lat, precision: 6)
            let lonStr = roundDigitsToString(val: lon, precision: 6)
            //self.htmlString += "Drone lat: \(latStr)<br>"
            //self.htmlString += "Drone lon: \(lonStr)<br>"
            // build a maps URL for clicking on
            //let urlStr = "https://maps.google.com/maps/@?api=1&map_action=map&center=\(lat),\(lon)"
            //let urlStr = "https://maps.google.com/maps/search/?api=1&t=k&query=\(lat),\(lon)"
            let urlStr = "https://www.google.com/maps/search/?api=1&t=k&query=\(lat),\(lon)"
            self.htmlString += "<a href='\(urlStr)'>Drone: \(latStr),\(lonStr)</a><br>"
            
        }
        catch {
            self.htmlString += "Lat/lon: \(error)<br>"
        }
        
        do {
            let droneAlt = try self.vc.theDroneImage!.getAltitude()
            // re issue #30, round degrees to 6 and distance/alt to 0
            var droneAltStr = roundDigitsToString(val: droneAlt, precision: 0)
            if app.settings.unitsMode == .Metric {
                self.htmlString += "Drone altitude: \(droneAltStr)m (hae)<br>"
            }
            else {
                let droneAltFt = app.metersToFeet(meters: droneAlt)
                droneAltStr = roundDigitsToString(val: droneAltFt, precision: 0)
                self.htmlString += "Drone altitude: \(droneAltStr)ft (hae)<br>"
            }
        }
        catch {
            self.htmlString += "Drone altitude: \(error)<br>" 
        }
        
        //print("getImageData: done, going to setTextViewText")
        
        // display the text finally!
        setTextViewText(htmlStr: self.htmlString)
        
    } // getImageData
    
    // take html string and encode it and set it to our textView
    // use newer function, written by ChatGPT, to better encode the HTML that
    // we want
    private func setTextViewText(htmlStr hString: String)
    {
        // to avoid crashing due to NSInternalConsistencyException, don't set
        // on calling thread; dispatch to main async
        // re issue #37
        DispatchQueue.main.async {
            if let attribString = self.vc.htmlToAttributedString(fromHTML: hString) {
                self.textView.attributedText = attribString
            }
        }
    }
    
    // do image calculations anytime willAppear is invoked
    private func doCalculations(altReference: DroneTargetResolution)
    {
        var ccdInfo: DroneCCDInfo?
        
        // reset target result values
        target = [0,0,0,0, 0,0,0,0, 0]
        configureMenuItems()

        htmlString = "\(style)"
        
        // if no DEM or no image, return as they may not be loaded just yet
        
        if vc.dem == nil || vc.theDroneImage == nil {
            print("Can't perform calculations without a digital elevation module (DEM) or image")
            return
        }
                
        // try to get CCD info for drone make/model
        do {
            ccdInfo = try vc.droneParams?.lookupDrone(make: vc.theDroneImage!.getCameraMake(),
                                                      model: vc.theDroneImage!.getCameraModel(),
                                                      targetWidth: vc.theDroneImage!.theImage!.size.width)
            vc!.theDroneImage!.ccdInfo = ccdInfo
        }
        catch {
            print("No CCD info for drone image, using estimates")
            vc!.theDroneImage!.ccdInfo = nil
        }
        
        // run the calculations and display target first
        // issue #30
    
        do {
            // calculate altitude of what we're looking at
            try target = vc!.theDroneImage!.resolveTarget(dem: vc!.dem!,
                                                          altReference: altReference)
        }
        catch DroneImageError.BadAltitude {
            htmlString += "Bad altitude data<br>"
            // raise alert
            let alert = UIAlertController(title: "Bad Altitude Data",
                                          message: "Image contains bad altitude data.  Would you like me to re-try using altitude above ground estimate if available?",
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: {_ in
                print("doCalculate: attempting re-calculate with altitude above ground estimate")
                self.htmlString += "Attempting to re-calculate with altitude above ground estimate<br>"
                self.doCalculations(altReference: DroneTargetResolution.AltitudeAboveGround)
            }))
            
            alert.addAction(UIAlertAction(title: "No", style: .cancel, handler:nil))
            self.present(alert, animated: true)
        }
        catch let error as DroneImageError {
            print("Calculation error: \(error.rawValue)")
            htmlString += "Calculation error: \(error.rawValue)<br>"
            
            // raise alert
            let alert = UIAlertController(title: "Calculation Error",
                                          message: error.rawValue,
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler:nil))
            self.present(alert, animated: true)
        }
        catch let error as ElevationModuleError {
            print("DEM error \(error.rawValue)")
            htmlString += "DEM error \(error.rawValue)<br>"
            // raise alert
            let alert = UIAlertController(title: "DEM Error",
                                          message: error.rawValue,
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler:nil))
            self.present(alert, animated: true)
        }
        catch {
            print("Calculation error: \(error)")
            htmlString += "Calculation error: \(error)"
            
            // raise alert
            let alert = UIAlertController(title: "Calculation Error",
                                          message: error.localizedDescription,
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler:nil))
            self.present(alert, animated: true)
        }
        
        // return from resolveTarget
        // 0 distance to target
        // 1 last latitude value along raycast
        // 2 last longitude value along raycast
        // 3 last altitude along raycast is WGS84
        // 4 terrain altitude of datapoint nearest last raycast position
        // 5 is the gimbalPitchDegree or theta
        // 6 azimuthOffset in degrees
        // 7 thetaOffset or pitch offset in degrees
        // 8 is adjusted alt target[3] + offset which we calculate and set
        // check for [ 0,0,0,0, 0,0,0,0, 0 ]
        // internally, all distances/altitudes are in meters
        
        print("resolveTarget returned \(target)")
        
        if target == [ 0.0, 0.0, 0.0, 0.0,  0.0, 0.0, 0.0, 0.0,  0.0] {
            print("doCalculations: target return values all zeros, returning")
            setTextViewText(htmlStr: htmlString)
            return
        }
        
        // get EGM96 offset from WGS84
        let offset = EGM96Geoid.getOffset(lat: target[1], lng: target[2])
        
        let latStr = roundDigitsToString(val: target[1], precision: 6)
        let lonStr = roundDigitsToString(val: target[2], precision: 6)
        // issue #30, round distance, alt to nearest meter
        var distanceStr = roundDigitsToString(val: target[0], precision: 0)
        var altStr = roundDigitsToString(val: target[3] + offset, precision: 0)
        let azOff = roundDigitsToString(val: target[6], precision: 2)
        // swap sign of thetaOff to keep with aircraft conventions (tait-bryan)
        let thetaOff = roundDigitsToString(val: -1.0 * target[7], precision: 2)
        target[8] = target[3] + offset
        
        //let nearestAltStr = roundDigitsToString(val: target[4] + offset, precision: 6)
                
        //htmlString += "<h2>Target Lat,Lon: \(latStr),\(lonStr)</h2><br>"
        
        //htmlString += "Resolve target: \(target)<br>"
        //let urlStr = "https://maps.../maps/@?api=1&map_action=map&center=\(target[1]),\(target[2])"
        let urlStr = "https://www.google.com/maps/search/?api=1&t=k&query=\(latStr),\(lonStr)"
        htmlString += "<a href='\(urlStr)'><h2>Lat,Lon: \(latStr),\(lonStr)</h2></a><br>"
        if app.settings.unitsMode == .Metric {
            htmlString += "<h2>Alt: \(altStr)m</h2><br>"
        }
        else {
            let altFt = app.metersToFeet(meters: target[3])
            altStr = roundDigitsToString(val: altFt, precision: 0)
            htmlString += "<h2>Alt: \(altStr)ft</h2><br>"
            let distanceFt = app.metersToFeet(meters: target[0])
            distanceStr = roundDigitsToString(val: distanceFt, precision: 0)
        }
        
        // would love a URL that we could have two pins on -- one for where drone is
        // and one for where target is; don't think we can do that w/o an Maps API key
        // and that would cost us
        
        // reported WGS84 altitude is target[3] or altStr
        
        // check the settings for output mode and see if we need to do any conversions
        // by default, everything internally is in WGS84 format
        if app.settings.outputMode == AthenaSettings.OutputModes.CK42Geodetic {
            var ck42lat, ck42lon, ck42alt: Double
            (ck42lat,ck42lon,ck42alt) = CK42Geodetic.WGS84_CK42(Bd: target[1], Ld: target[2], H: target[3])
            
            let ck42latStr = roundDigitsToString(val: ck42lat, precision: 6)
            let ck42lonStr = roundDigitsToString(val: ck42lon, precision: 6)
            // issue #30, round alt to nearest meter
            let ck42altStr = roundDigitsToString(val: ck42alt, precision: 0)
            htmlString += "<h2>CK42 Lat,Lon: \(ck42latStr),\(ck42lonStr)</h2><br>"
            htmlString += "<h2>CK42 Alt: \(ck42altStr)m</h2><br>"
        }
        
        if app.settings.outputMode == AthenaSettings.OutputModes.CK42GaussKruger {
            var ck42lat, ck42lon, ck42alt: Double
            (ck42lat,ck42lon,ck42alt) = CK42Geodetic.WGS84_CK42(Bd: target[1], Ld: target[2], H: target[3])
            let ck42latStr = roundDigitsToString(val: ck42lat, precision: 6)
            let ck42lonStr = roundDigitsToString(val: ck42lon, precision: 6)
            // issue #30, round alt to nearest meter
            let ck42altStr = roundDigitsToString(val: ck42alt, precision: 0)
            htmlString += "<h2>CK42 Lat,Lon: \(ck42latStr),\(ck42lonStr)</h2><br>"
            htmlString += "<h2>CK42 Alt: \(ck42altStr)m</h2><br>"
            
            var ck42GKlat, ck42GKlon: Int64
            
            (ck42GKlat,ck42GKlon) = CK42GaussKruger.CK42_to_GaussKruger(CK42_LatDegrees: ck42lat, CK42_LonDegrees: ck42lon)
            
            htmlString += "<h2>CK42 GK Northing, Easting: \(ck42GKlat),\(ck42GKlon)</h2><br>"
        }
        
        // all MGRS 1m, 10m, 100m
        if app.settings.outputMode == AthenaSettings.OutputModes.MGRS {
            
            let mgrsStr = MGRSGeodetic.WGS84_MGRS1m(Lat: target[1],Lon: target[2],Alt: target[3])
            let mgrsSplitStr = MGRSGeodetic.splitMGRS(mgrs: mgrsStr)
            
            //htmlString += "<h2>MGRS1m: \(mgrsStr)</h2><br>"
            let urlStr = "https://www.google.com/maps/search/?api=1&t=k&query=\(mgrsStr)"
            htmlString += "<a href='\(urlStr)'><h2>MGRS1m: \(mgrsSplitStr)</h2></a><br>"
            if app.settings.unitsMode == .Metric {
                htmlString += "<h2>Alt: \(altStr)m</h2><br>"
            }
            else {
                htmlString += "<h2>Alt: \(altStr)ft</h2><br>"
            }

            let mgrs10Str = MGRSGeodetic.WGS84_MGRS10m(Lat: target[1], Lon: target[2],Alt: target[3])
            let mgrs10SplitStr = MGRSGeodetic.splitMGRSRegex(mgrs: mgrs10Str)
            htmlString += "<h2>MGRS10m: \(mgrs10SplitStr)</h2><br>"
                        
            let mgrs100Str = MGRSGeodetic.WGS84_MGRS100m(Lat: target[1], Lon: target[2],Alt: target[3])
            let mgrs100SplitStr = MGRSGeodetic.splitMGRSRegex(mgrs: mgrs100Str)
            htmlString += "<h2>MGRS100m: \(mgrs100SplitStr)</h2><br>"
            
            //htmlString += "\(mgrsStr)<br>"
            //htmlString += "\(mgrs10Str)<br>"
            //htmlString += "\(mgrs100Str)<br>"
            
        }

        // UTM
        if app.settings.outputMode == AthenaSettings.OutputModes.UTM {
            let coordinate = CLLocationCoordinate2D(latitude: target[1], longitude: target[2])
            let utmCoordinate = coordinate.utmCoordinate()
            let nStr = roundDigitsToString(val: utmCoordinate.northing, precision: 6)
            let eStr = roundDigitsToString(val: utmCoordinate.easting, precision: 6)
            if (utmCoordinate.hemisphere == .northern) {
                htmlString += "<h2>UTM: N, \(utmCoordinate.zone) \(eStr) E, \(nStr) N</h2><br>"
            }
            else {
                htmlString += "<h2>UTM: S, \(utmCoordinate.zone) \(eStr) E, \(eStr) N</h2><br>"
            }
        } // UTM
        
        //htmlString += "Elevation map: \(vc.dem?.tiffURL?.lastPathComponent ?? "")<br>"
        //htmlString += "Image \(vc.theDroneImage!.name ?? "Unknown")<br>"
        //htmlString += "Image date: \(vc.theDroneImage!.getDateTimeUTC())<br>"
        //htmlString += "\(foundCCDInfoString)"
        
        htmlString += "Azimuth offset: \(azOff) degrees<br>"
        htmlString += "Theta (pitch) offset: \(thetaOff) degrees<br>"
        
        if app.settings.unitsMode == .Metric {
            htmlString += "Distance to target \(distanceStr)m<br>"
        }
        else {
            // previously calculated, converted
            htmlString += "Distance to target \(distanceStr)ft<br>"
        }
        //htmlString += "Nearest terrain alt \(nearestAltStr) meters<br>"
        
        do {
            // determine alt of ground under drone itself first
            // for comparison
            
            let groundAlt = try self.vc.dem?.getAltitudeFromLatLong(
                targetLat: self.vc.theDroneImage!.getLatitude(),
                targetLong: self.vc.theDroneImage!.getLongitude())
            
            // issue #30, round alt to nearest meter
            var groundAltStr = roundDigitsToString(val: groundAlt ?? -1, precision: 0)
            if app.settings.unitsMode == .Metric {
                htmlString += "Ground altitude under drone is \(groundAltStr)m (hae)<br>"
            }
            else {
                let groundAltFt = app.metersToFeet(meters: groundAlt ?? -1)
                groundAltStr = roundDigitsToString(val: groundAltFt, precision: 0)
                htmlString += "Ground altitude under drone is \(groundAltStr)ft (hae)<br>"
            }
        } catch { htmlString += "Unable to determine ground altitude under drone?!<br>" }
        
        switch altReference {
        case DroneTargetResolution.AltitudeFromGPS:
            htmlString += "Altitude: GPS<br>"
        case DroneTargetResolution.AltitudeFromRelative:
            htmlString += "Altitude: relative<br>"
        case DroneTargetResolution.AltitudeAboveGround:
            htmlString += "Altitude: above ground<br>"
        }
        
        print("doCalculations: going to get image data")
        
        getImageData()
        
        // display some params from the drone ccd info params that we matched
        // to this drone; re issue #38
        
        if ccdInfo != nil {
            htmlString += "Drone CCD Info for: \(ccdInfo!.makeModel)<br>"
            htmlString += "Drone lens type: \(ccdInfo!.lensType)<br>"
            htmlString += "Drone thermal: \(ccdInfo!.isThermal)<br>"
            htmlString += "Drone image width: \(ccdInfo!.widthPixels)<br>"
            htmlString += "Drone image height: \(ccdInfo!.heightPixels)<br>"
            htmlString += "Drone: \(ccdInfo!.comment)<br>"
        }
                
        setTextViewText(htmlStr: htmlString)
        
        // enable these options menu actions; since uiactions are immutable, re-create
        // entire menu
        
        configureMenuItems()
        
    } // doCalculations
    
    @IBAction func didTapImage(tapGestureRecognizer: UITapGestureRecognizer)
     {
         guard let image = imageView.image else {
             return
         }
         
         unMarkImagePixel()

         var touchPoint: CGPoint = tapGestureRecognizer.location(in: imageView)
         let imageRect: CGRect = aspectFitRect(aspectRatio: image.size, insideRect: imageView.bounds)
         
         if imageRect.contains(touchPoint) == false {
             print("Touch point outside of image")
             return
         }
         
         // touch point relative to imageView then translate to the image coordinates
         touchPoint.x -= imageRect.origin.x
         touchPoint.y -= imageRect.origin.y
             
         let wScale: CGFloat = image.size.width / imageRect.size.width
         let hScale: CGFloat = image.size.height / imageRect.size.height
         
         let newX = touchPoint.x * wScale
         let newY = touchPoint.y * hScale
                
         vc.theDroneImage!.targetXprop =  newX / image.size.width
         vc.theDroneImage!.targetYprop = newY / image.size.height
         markImagePixel(x_prop: vc.theDroneImage!.targetXprop, y_prop: vc.theDroneImage!.targetYprop)
         
         // recalculate new target location
         doCalculations(altReference: DroneTargetResolution.AltitudeFromGPS)
    
     } // didTapImage
     
     func unMarkImagePixel()
     {
         imageView.image = vc.theDroneImage?.theImage
     }
     
     // from hackingwithswift.com
     // does this handle pinch/zoom ?
     // also from stackoverflow.com/questions/76316417/
     // pass in image size and then the bounds of imageView containing image
     // also can be done via AVFoundation: AVMakeRect()
     // result in points within view, not pixels
     
     func aspectFitRect(aspectRatio: CGSize, insideRect: CGRect) -> CGRect
     {
         var fitWidth: CGFloat = insideRect.width
         var fitHeight: CGFloat = insideRect.height
         let maxW: CGFloat = fitWidth / aspectRatio.width
         let maxH: CGFloat = fitHeight / aspectRatio.height
         
         if maxH < maxW {
             fitWidth = fitHeight / aspectRatio.height * aspectRatio.width
         }
         else if maxW < maxH {
             fitHeight = fitWidth / aspectRatio.width * aspectRatio.height
         }
         
         return CGRect(x: (insideRect.width - fitWidth) * 0.5,
                       y: (insideRect.height - fitHeight) * 0.5,
                       width: fitWidth,
                       height: fitHeight)
     } // aspectFitRect
    
     func markImagePixel(x_prop: CGFloat, y_prop: CGFloat)
     {
         guard let image = imageView.image else {
             return
         }
         let imageSize = image.size
         let scale: CGFloat = 0
         let length: CGFloat = max(imageSize.width/48, imageSize.height/48)
         let gap: CGFloat = length / 1.5
         let width: CGFloat = gap / 1.5
         let actualX = imageSize.width * x_prop
         let actualY = imageSize.height * y_prop
                 
         UIGraphicsBeginImageContextWithOptions(imageSize, false, scale)
         
         imageView.image!.draw(at: CGPoint.zero)
         var uiColor = hexToUIColor(rgbVal: 0xFE00DD)
         uiColor.setFill()

         // horizontal lines in target
         var rectangle = CGRect(x: actualX - length - gap, y: actualY-width/2,
                                width: length, height: width)
         UIRectFill(rectangle)
         
         rectangle = CGRect(x: actualX + gap, y: actualY-width/2,
                            width: length, height: width)
         UIRectFill(rectangle)
         
         // vertical lines in target
         rectangle = CGRect(x: actualX-width/2, y: actualY - length - gap,
                            width: width, height: length)
         UIRectFill(rectangle)
         
         rectangle = CGRect(x: actualX-width/2, y: actualY + gap,
                            width: width, height: length)
         UIRectFill(rectangle)
         
         // for testing, draw a white rectangle 20x20 centered at actual x,y
         //uiColor = hexToUIColor(rgbVal: 0xFFFFFF)
         //uiColor.setFill()
         //rectangle = CGRect(x: actualX-10, y: actualY-10, width: 20, height: 20)
         //UIRectFill(rectangle)
         
         let newImage = UIGraphicsGetImageFromCurrentImageContext()
         UIGraphicsEndImageContext()
         
         imageView.image = newImage
         
     }
     // create UIColor from hex RGB value
     // https://stackoverflow.com/questions/24074257/how-can-i-use-uicolorfromrgb-in-swift
     func hexToUIColor(rgbVal: Int) -> UIColor {
         return UIColor (
             red: CGFloat((rgbVal & 0xFF0000) >> 16) / 255.0,
             green: CGFloat((rgbVal & 0x00FF00) >> 8) / 255.0,
             blue: CGFloat(rgbVal & 0x0000FF) / 255.0,
             alpha: CGFloat(1.0)
         )
     }
     
     // borrowed from https://www.advancedswift.com/rounding-floats-and-doubles-in-swift/
     public enum RoundingPrecision {
         case ones
         case tenths
         case hundredths
         case thousandths
         case tenthousandths
         case hundredthousandths
     }
     
     public func preciseRound(_ value: Double, precision: RoundingPrecision = .ones) -> CGFloat {
         switch precision {
         case .ones:
             return round(value)
         case .tenths:
             return round(value*10.0) / 10.0
         case .hundredths:
             return round(value*100.0) / 100.0
         case .thousandths:
             return round(value*1000.0) / 1000.0
         case .tenthousandths:
             return round(value*10000.0) / 10000.0
         case .hundredthousandths:
             return round(value*100000.0) / 100000.0
         }
     }
     
     // take a double (e.g. lat, lon, elevation, distance, etc. and round to X digits of precision and
     // return string
     public func roundDigitsToString(val: Double, precision: Double) -> String {
         let num = (val * pow(10,precision)).rounded(.toNearestOrAwayFromZero) / pow(10,precision)
         // after we round it, if caller wanted 0 digits of precision, chop the .0 off of float
         if precision == 0 {
             return String(Int(num))
         }
         return String(num)
     }
    
    // once image has been selected, find/load the
    // elevation map from our cache of elevation maps
    // if not found, offer to go fetch it
    // then reload
    private func findLoadElevationMap() -> Bool
    {
        var result = true
        var lat: Double = 0.0
        var lon: Double = 0.0
        
        print("findLoadElevationMap: starting")
        
        do {
            lat = try vc.theDroneImage!.getLatitude()
            lon = try vc.theDroneImage!.getLongitude()
            lat = DemDownloader.truncateDouble(val: lat, precision: 6)
            lon = DemDownloader.truncateDouble(val: lon, precision: 6)
            htmlString += "Coordinates: \(lat),\(lon)<br>"
            
            // regardless of whether we have a DEM already loaded,
            // just do a look up and load that DEM
            // possible again
            let filename = vc.demCache!.searchCacheFilename(lat: lat, lon: lon)
            if filename != "" {
                print("findLoadElevationMap: found \(filename)")
                // load the DEM and return
                try vc.dem = vc.demCache!.loadDemFromCache(lat: lat, lon: lon)
                htmlString += "Loaded \(filename) from elevation map cache<br>"
                                
                // would be nice to have the resulting filename be
                // clickable for more information on the DEM itself
                // right now, user then has to go find the entry in the cache
                // and then click on it.  Future version XXX
            }
            else {
                print("Did not find DEM")
                result = false
                // would you like me to download one?
                if lat != 0.0 && lon != 0.0 {
                    shouldIDownloadAlert(lat: lat, lon: lon, len: 15000.0)
                }
                else {
                    htmlString += "Can't download an elevation map without coordinates.  Does this image have exif data?<br>"
                }
            }
        }
        catch {
            print("Caught error: Did not find DEM for \(lat),\(lon)")
            result = false
            htmlString += "Error locating image coordinates or digital elevation map<br>"
            // would you like me to download one?
            if lat != 0.0 && lon != 0.0 {
                shouldIDownloadAlert(lat: lat, lon: lon, len: 15000.0)
            }
            else {
                htmlString += "Can't download an elevation map without coordinates.  Does this image have exif data?<br>"
            }
        }
        
        setTextViewText(htmlStr: htmlString)
        return result
        
    } // findLoadElevationMap
    
    // handler courtesy of ChatGPT plus modifications
    private func shouldIDownloadAlert(lat: Double, lon: Double, len: Double)
    {
        print("Should I download alert starting")
        let alertController = UIAlertController(title: "Elevation map not found",
                                                message: "Download an elevation map for surrounding area?",
                                                preferredStyle: .alert)
        let yesAction = UIAlertAction(title: "Yes", style: .default) { (action) in
            self.htmlString += "Downloading elevation map . . .<br>"
            self.updateTextView()
            self.fetchNewElevationMap(lat: lat, lon: lon, len: len)
        }
        let noAction = UIAlertAction(title: "No", style: .default) { (action) in
            self.htmlString += "Not going to download elevation map<br>"
            self.updateTextView()
            // do nothing
        }
        
        alertController.addAction(yesAction)
        alertController.addAction(noAction)
        self.present(alertController, animated: true, completion: nil)
        
    } // shouldIDownloadAlert
    
    // user has specifically requested we got get an elevation map/model
    // if it succeeds, load it
    private func fetchNewElevationMap(lat: Double, lon: Double, len: Double)
    {
        
        // start spinner or activity indicator first
        activityIndicator = UIActivityIndicatorView(style: .large)
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(activityIndicator)
        //activityIndicator.center = self.view.center
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20)
        ])
        //activityIndicator.backgroundColor = .white
        //activityIndicator.color = .red
        activityIndicator.hidesWhenStopped = true
        activityIndicator.startAnimating()
        
        // unleash the download
        
        let aDownloader = DemDownloader(lat: lat, lon: lon, length: len)
        aDownloader.download(completionHandler: { ( resultCode, bytes, filename ) in
            
            // stop the spinner or activity indicator
            DispatchQueue.main.async {
                self.activityIndicator.stopAnimating()
            }
            
            // now handle result processing
            let resultStr = DemDownloader.httpResultCodeToString(resultCode: resultCode)
            self.app.sendNotification(title: "Download Result",
                                      text: "Download result: \(resultStr), \(bytes) bytes, \(filename)")
            if resultCode == 200 {
                // gotta force cache reload
                self.vc.demCache = DemCache()
                let aDem = try? self.vc.demCache?.loadDemFromCache(lat: lat, lon: lon)
                if aDem != nil {
                    self.vc.dem = aDem
                    self.htmlString += "Successfully downloaded and loaded elevation map<br>"
                    self.htmlString += "\(aDem!.tiffURL.lastPathComponent)<br>"
                    self.updateTextView()
                    DispatchQueue.main.async {
                        self.doCalculations(altReference: DroneTargetResolution.AltitudeFromGPS)
                    }
                }
            }
            else {
                self.htmlString += "Unable to download elevation map: \(resultStr)<br>"
                self.updateTextView()
            }
            
        })
        
    } // fetchNewElevationMap
    
    // update the text view while not on main ui thread
    // call this function from completion handlers and other
    // code blocks that are not allowed to directly call the main UI thread
    private func updateTextView()
    {
        DispatchQueue.main.async {
            self.setTextViewText(htmlStr: self.htmlString)
        }
    }
    
    private func getCurrentLocalTime() -> String
    {
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime]
        let currentDateTime = Date()
        return dateFormatter.string(from: currentDateTime)
        
        // return Date().description(with: .current)
        
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?)
    {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if self.traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
           setTextViewText(htmlStr: htmlString)
        }
    }
    
} // LoadCalculateViewController
