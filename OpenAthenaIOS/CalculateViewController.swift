//
//  CalculateViewController.swift
//  OpenAthenaIOS
//  https://github.com/rdkgit/OpenAthenaIOS
//  https://openathena.com
//  Created by Bobby Krupczak on 1/27/23.
//

// put X or something in center of picture
// for user knows what we are locating XXX

import UIKit
import CoreLocation
import UTMConversion

// add scrollview around imageview for pinch/zoom ?

class CalculateViewController: UIViewController, UIScrollViewDelegate {
    
    var app: AppDelegate = UIApplication.shared.delegate as! AppDelegate
    var vc: ViewController!
    var textView: UITextView = UITextView()
    var imageView: UIImageView = UIImageView()
    var stackView: UIStackView = UIStackView()
    var scrollView: UIScrollView = UIScrollView()
    var contentView: UIView = UIView()
    var htmlString: String = ""
    var target: [Double] = [0,0,0,0,0,0,0,0,0]
    var adjustedAlt: Double = 0.0
    var cotSender: CursorOnTargetSender? = nil
    var style: String = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("Calculate viewDidLoad invoked")
        
        // set html style
        style = "<style>body {font-size: \(app.settings.fontSize); } h1, h2 { display: inline; } </style>"
        
        self.title = "Calculate"
        view.backgroundColor = .secondarySystemBackground
        //view.overrideUserInterfaceStyle = .light
        
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
        // dont set imageView.contentMode = .scaleAspectFit
        if vc.theDroneImage != nil {
            imageView.image = vc.theDroneImage?.theImage
        }
        imageView.contentMode = .scaleAspectFit
        let singleTap = UITapGestureRecognizer(target: self, action: #selector(didTapImage))
        imageView.addGestureRecognizer(singleTap)
        imageView.isUserInteractionEnabled = true
        
        // configure textview
        textView.isSelectable = true
        textView.isEditable = false
        //textView.isScrollEnabled = false
        textView.font = .systemFont(ofSize: 16)
        //textView.heightAnchor.constraint(equalToConstant: 0.66*view.frame.size.height).isActive = true
        textView.isScrollEnabled = true // ?? was false but that sometimes chops text
        textView.backgroundColor = .secondarySystemBackground
        
        // stackview setup
        stackView.frame = view.bounds
        stackView.axis = .vertical
        stackView.distribution = .fillProportionally
        stackView.spacing = 5
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        stackView.addArrangedSubview(imageView)
        stackView.addArrangedSubview(textView)
        contentView.addSubview(stackView)
        scrollView.addSubview(contentView)
        view.addSubview(scrollView)
        
        // set the layout constraints
        textView.heightAnchor.constraint(equalToConstant: 0.60*view.frame.size.height).isActive = true
        imageView.heightAnchor.constraint(equalToConstant: 0.40*view.frame.size.height).isActive = true
        
        //textView.widthAnchor.constraint(equalToConstant: view.frame.size.width).isActive = true
        
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
            
        markImagePixel(x_prop: vc.theDroneImage!.targetXprop, y_prop: vc.theDroneImage!.targetYprop)
        doCalculations(altReference: DroneTargetResolution.AltitudeFromGPS)
        
        // create a cursor on target sender and pass Athena settings
        if cotSender == nil {
            print("Calculate: creating CursorOnTarget object")
            cotSender = CursorOnTargetSender(params: app.settings)
        }
        
    } // viewDidLoad
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        
        print("Calculate viewWillAppear invoked")
        
        // do/re-do calculations and output
        doCalculations(altReference: DroneTargetResolution.AltitudeFromGPS)
        
    } // viewWillAppear
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        print("Calculate viewWillDisappear")
        
        cotSender?.close()
        
    }
    
    // do image calculations anytime willAppear is invoked
    private func doCalculations(altReference: DroneTargetResolution)
    {
        var ccdInfo: DroneCCDInfo?
        var foundCCDInfoString: String = ""
        
        htmlString = "\(style)"
        
        // if no DEM, throw error
        if vc.dem == nil {
            htmlString += "Can't perform calculations without a digital elevation module (DEM)<br>"
            setTextViewText(htmlStr: htmlString)
            return
        }
                
        // try to get CCD info for drone make/model
        do {
            ccdInfo = try vc.droneParams?.lookupDrone(make: vc.theDroneImage!.getCameraMake(),
                                                      model: vc.theDroneImage!.getCameraModel(),
                                                      targetWidth: vc.theDroneImage!.theImage!.size.width)
            vc!.theDroneImage!.ccdInfo = ccdInfo
            foundCCDInfoString = "Found CCD info for drone make/model \(ccdInfo!.makeModel)<br>"
        }
        catch {
            print("No CCD info for drone image, using estimates")
            foundCCDInfoString = "No CCD info for drone make/model, estimate using exif 35mm equivalent<br>"
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
        // check for [ 0,0,0,0,0,0,0,0 ]
        // internally, all distances/altitudes are in meters
        
        if target == [ 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0] {
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
        
        print("resolveTarget returned \(target)")
        
        //htmlString += "<h2>Target Lat,Lon: \(latStr),\(lonStr)</h2><br>"
        
        //htmlString += "Resolve target: \(target)<br>"
        //let urlStr = "https://maps.../maps/@?api=1&map_action=map&center=\(target[1]),\(target[2])"
        let urlStr = "https://maps.google.com/maps/search/?api=1&t=k&query=\(latStr),\(lonStr)"
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
            //htmlString += "<h2>MGRS1m: \(mgrsStr)</h2><br>"
            let urlStr = "https://maps.google.com/maps/search/?api=1&t=k&query=\(mgrsStr)"
            htmlString += "<a href='\(urlStr)'><h2>MGRS1m: \(mgrsStr)</h2></a><br>"
            if app.settings.unitsMode == .Metric {
                htmlString += "<h2>Alt: \(altStr)m</h2><br>"
            }
            else {
                htmlString += "<h2>Alt: \(altStr)ft</h2><br>"
            }

            let mgrs10Str = MGRSGeodetic.WGS84_MGRS10m(Lat: target[1], Lon: target[2],Alt: target[3])
            htmlString += "<h2>MGRS10m: \(mgrs10Str)</h2><br>"
                        
            let mgrs100Str = MGRSGeodetic.WGS84_MGRS100m(Lat: target[1], Lon: target[2],Alt: target[3])
            htmlString += "<h2>MGRS100m: \(mgrs100Str)</h2><br>"
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
        
        htmlString += "Elevation map: \(vc.dem?.tiffURL?.lastPathComponent ?? "")<br>"
        htmlString += "Image \(vc.theDroneImage!.name ?? "Unknown")<br>"
        htmlString += "Image date: \(vc.theDroneImage!.getDateTimeUTC())<br>"
        htmlString += "\(foundCCDInfoString)"
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
        
        getImageData()
                
        setTextViewText(htmlStr: htmlString)
                
    } // doCalculations
    
    // pinch/zoom the entire stack view, not just image!
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        //print("viewForZooming returning imageView")
        return contentView
    }
    
    // keep in sync with ImageViewController:getImageData()
    private func getImageData()
    {
        var lat, lon: Double
        let targetX = vc.theDroneImage!.targetXprop * vc.theDroneImage!.theImage!.size.width
        let targetY = vc.theDroneImage!.targetYprop * vc.theDroneImage!.theImage!.size.height
        
        do {
            let makeStr = try self.vc.theDroneImage!.getCameraMake()
            let modelStr = try self.vc.theDroneImage!.getCameraModel()
            self.htmlString += "Make/model: \(makeStr),\(modelStr)<br>"
        }
        catch {
            self.htmlString += "Camera make/model  is: \(error)<br>"
        }
        
        do {
            // handle lat,lon together because typically images
            // will have both or have neither
            try lat = self.vc.theDroneImage!.getLatitude()
            try lon = self.vc.theDroneImage!.getLongitude()
            let latStr = roundDigitsToString(val: lat, precision: 6)
            let lonStr = roundDigitsToString(val: lon, precision: 6)
            self.htmlString += "Drone Lat,Lon: \(latStr),\(lonStr)<br>"
            self.htmlString += "Taget pixel coordinates (\(preciseRound(targetX, precision: .tenthousandths)),\(preciseRound(targetY,precision: .tenthousandths)))<br>"
            // build a maps URL for clicking on
            //let urlStr = "https://maps.google.com/maps/@?api=1&map_action=map&center=\(lat),\(lon)"
            //let urlStr = "https://maps.google.com/maps/search/?api=1&t=k&query=\(lat),\(lon)"
            //self.htmlString += "<a href='\(urlStr)'>\(urlStr)</a><br>"
        }
        catch {
            self.htmlString += "Lat/Lon: \(error)<br>"
        }
        
        do {
            let droneAlt = try self.vc.theDroneImage!.getAltitude()
            // issue #30, round alt to nearest meter
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
        
        do {
            // convert display output to tait-bryan which is down is negative
            try self.htmlString += "GimbalPitch/Theta \(-1.0 * self.vc.theDroneImage!.getGimbalPitchDegree())<br>"
        }
        catch {
            self.htmlString += "GimbalPitch/Theta: \(error)<br>"
        }
        
        do {
            try self.htmlString += "GimbalYaw/Az: \(self.vc.theDroneImage!.getGimbalYawDegree())<br>"
        }
        catch {
            self.htmlString += "GimbalYaw/Az: \(error)<br>"
        }
        
        self.htmlString += "Is Drone? \(self.vc.theDroneImage!.isDroneImage())<br>"
        
    }
    
    // create our main menu and glue it into navigation controller
    private func configureMenuItems()
    {
        //print("Configuring menus on calculate screen")
        
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
                //print("About")
                let vc = self.storyboard?.instantiateViewController(withIdentifier: "About") as! AboutViewController
                vc.vc = self.vc
                self.navigationController?.pushViewController(vc, animated: true)
            },
            UIAction(title:"Manage Elevation Maps", image: UIImage(systemName:"map")) {
                action in
                //print("Manage elevation maps")
                let vc = self.storyboard?.instantiateViewController(withIdentifier: "ManageDemViewController") as! ManageDemViewController
                vc.vc = self.vc
                self.navigationController?.pushViewController(vc, animated: true)
            },
            UIAction(title:"Debug", image: UIImage(systemName:"binoculars.fill")) {
                action in
                //print("Debug")
                let vc = self.storyboard?.instantiateViewController(withIdentifier: "Debug") as! DebugViewController
                vc.vc = self.vc
                self.navigationController?.pushViewController(vc, animated: true)
            },
            UIAction(title:"Reset pointer", image: UIImage(systemName:"arrow.clockwise")) {
                action in
                //print("Reset pointer")
                // reset pointer back to 50% 50%
                self.unMarkImagePixel()
                self.vc.theDroneImage!.targetXprop =  0.50
                self.vc.theDroneImage!.targetYprop = 0.50
                self.markImagePixel(x_prop: self.vc.theDroneImage!.targetXprop, y_prop: self.vc.theDroneImage!.targetYprop)
                
                // recalculate new target location
                self.doCalculations(altReference: DroneTargetResolution.AltitudeFromGPS)
            },
            UIAction(title:"Send CoT", image: UIImage(systemName: "target")) {
                action in
                //print("Send CoT")
                // grab target info out of target[] array
                // get image date/time in iso8601/UTC format
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

            }
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
    
    // take htmlString and encode it and set
    // it to our textView
    private func setTextViewTextOld(htmlStr hString: String)
    {
        let data = Data(hString.utf8)
        let font = UIFont.systemFont(ofSize: CGFloat(app.settings.fontSize))
        
        if let attribString = try? NSMutableAttributedString(data: data,
                                                           options: [.documentType: NSAttributedString.DocumentType.html],
                                                           documentAttributes: nil) {
            
            attribString.addAttribute(NSAttributedString.Key.font, value: font,
                                      range: NSRange(location: 0,length: attribString.length))
            attribString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.label, range: NSMakeRange(0,attribString.length))
            
            self.textView.attributedText = attribString
        }
    }
    
    // take html string and encode it and set it to our textView
    // use newer function, written by ChatGPT, to better encode the HTML that
    // we want
    private func setTextViewText(htmlStr hString: String)
    {
        if let attribString = htmlToAttributedString(fromHTML: hString) {
            self.textView.attributedText = attribString
        }
    }
    
    // written by ChatGPT with mods by rdk
    private func htmlToAttributedString(fromHTML html: String) -> NSAttributedString?
    {
        guard let data = html.data(using: .utf8) else { return nil }
        
        // options for document type and char encoding
        let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: String.Encoding.utf8.rawValue
        ]
        
        // try to create an attributed string from the html
        do {
            let attributedString = try NSAttributedString(data: data, options: options, documentAttributes: nil )
            return attributedString
        }
        catch {
            print("Error converting HTML to attributed string \(error)")
            return nil
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
    
} // CalculateViewController
