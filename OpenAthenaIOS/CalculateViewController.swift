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
    var target: [Double] = [0,0,0,0,0]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("Calculate viewDidLoad invoked")
        
        self.title = "Calculate"
        view.backgroundColor = .white
        
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
        
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        // image setup
        // dont set imageView.contentMode = .scaleAspectFit
        if vc.theDroneImage != nil {
            imageView.image = vc.theDroneImage?.theImage
        }
        imageView.contentMode = .scaleAspectFit
        
        // configure textview
        textView.isSelectable = true
        textView.isEditable = false
        //textView.isScrollEnabled = false
        textView.font = .systemFont(ofSize: 16)
        textView.heightAnchor.constraint(equalToConstant: 0.66*view.frame.size.height).isActive = true
        textView.widthAnchor.constraint(equalToConstant: view.frame.size.width).isActive = true
        textView.isScrollEnabled = false
        
        // stackview setup
        stackView.frame = view.bounds
        stackView.axis = .vertical
        stackView.distribution = .fillProportionally
        stackView.spacing = 5
        
        stackView.addArrangedSubview(imageView)
        stackView.addArrangedSubview(textView)
        contentView.addSubview(stackView)
        scrollView.addSubview(contentView)
        view.addSubview(scrollView)
        
        // set the layout constraints
        textView.heightAnchor.constraint(equalToConstant: 0.60*view.frame.size.height).isActive = true
        imageView.heightAnchor.constraint(equalToConstant: 0.40*view.frame.size.height).isActive = true

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
            
        doCalculations()
        
    } // viewDidLoad
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        print("Calculate viewWillAppear invoked")
        
        // do/re-do calculations and output
        doCalculations()
        
    } // viewWillAppear
    
    private func doCalculations()
    {
        htmlString = "<b>OpenAthena</b><br>"
        htmlString += "Elevation model: \(vc.dem?.tiffURL?.lastPathComponent)<br>"
        htmlString += "Image \(vc.theDroneImage!.name ?? "Unknown")<br>"
        
        getImageData()
        
        // run the calculations
        do {
            try target = vc!.theDroneImage!.resolveTarget(dem: vc!.dem!)
        }
        catch let error as DroneImageError {
            print("Calculate error \(error.rawValue)")
            htmlString += "Calcuation error \(error.rawValue)<br>"
            
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
            print("Calculate error \(error)")
            htmlString += "Calcuation error \(error)"
            
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
        // 3 last altitude along raycast
        // 4 terrain altitude of datapoint nearest last raycast position
        
        // check for [ 0,0,0,0 ]
        if target == [ 0.0, 0.0, 0.0, 0.0, 0.0] {
            setTextViewText(htmlStr: htmlString)
            return
        }
                
        print("resolveTarget returned \(target)")
        htmlString += "Distance to target \(target[0]) meters<br>"
        htmlString += "Target altitude \(target[3]) meters<br>"
        htmlString += "Nearest terrain alt \(target[4]) meters<br>"
        htmlString += "Lat: \(target[1])<br>"
        htmlString += "Lon: \(target[2])<br>"
        htmlString += "Resolve target: \(target)<br>"
        //let urlStr = "https://maps.../maps/@?api=1&map_action=map&center=\(target[1]),\(target[2])"
        let urlStr = "https://maps.google.com/maps/search/?api=1&t=k&query=\(target[1]),\(target[2])"
        htmlString += "<a href='\(urlStr)'>\(urlStr)</a><br>"
        
        // would love a URL that we could have two pins on -- one for where drone is
        // and one for where target is; don't think we can do that w/o an Maps API key
        // and that would cost us
        
        // reported WGS84 altitude is target[3]
        
        // check the settings for output mode and see if we need to do any conversions
        // by default, everything internally is in WGS84 format
        if app.settings.outputMode == AthenaSettings.OutputModes.CK42Geodetic {
            var ck42lat, ck42lon, ck42alt: Double
            (ck42lat,ck42lon,ck42alt) = CK42Geodetic.WGS84_CK42(Bd: target[1], Ld: target[2], H: target[3])
            
            htmlString += "CK42Lat: \(ck42lat)<br>"
            htmlString += "CK42Lon: \(ck42lon)<br>"
            htmlString += "CK42Alt: \(ck42alt)<br>"
        }
        
        if app.settings.outputMode == AthenaSettings.OutputModes.CK42GaussKruger {
            var ck42lat, ck42lon, ck42alt: Double
            (ck42lat,ck42lon,ck42alt) = CK42Geodetic.WGS84_CK42(Bd: target[1], Ld: target[2], H: target[3])
            
            htmlString += "CK42Lat: \(ck42lat)<br>"
            htmlString += "CK42Lon: \(ck42lon)<br>"
            htmlString += "CK42Alt: \(ck42alt)<br>"
            
            var ck42GKlat, ck42GKlon: Int64
            
            (ck42GKlat,ck42GKlon) = CK42GaussKruger.CK42_to_GaussKruger(CK42_LatDegrees: ck42lat, CK42_LonDegrees: ck42lon)
            
            htmlString += "CK42 GK Northing: \(ck42GKlat)<br>"
            htmlString += "CK42 GK Easting: \(ck42GKlon)<br>"
        }
        
        if app.settings.outputMode == AthenaSettings.OutputModes.MGRS1m {
            var mgrsStr = MGRSGeodetic.WGS84_MGRS1m(Lat: target[1],Lon: target[2],Alt: target[3])
            htmlString += "MGRS1m: \(mgrsStr)<br>"
            htmlString += "Alt: \(target[3])<br>"
        }

        if app.settings.outputMode == AthenaSettings.OutputModes.MGRS10m {
            var mgrsStr = MGRSGeodetic.WGS84_MGRS10m(Lat: target[1],Lon: target[2],Alt: target[3])
            htmlString += "MGRS10m: \(mgrsStr)<br>"
            htmlString += "Alt: \(target[3])<br>"
        }
        
        if app.settings.outputMode == AthenaSettings.OutputModes.MGRS100m {
            var mgrsStr = MGRSGeodetic.WGS84_MGRS100m(Lat: target[1],Lon: target[2],Alt: target[3])
            htmlString += "MGRS100m: \(mgrsStr)<br>"
            htmlString += "Alt: \(target[3])<br>"
        }
                
        setTextViewText(htmlStr: htmlString)
                
    } // doCalculations
    
    // pinch/zoom the entire stack view, not just image!
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        //print("viewForZooming returning imageView")
        return contentView
    }
    
    // take htmlString and encode it and set
    // it to our textView
    private func setTextViewText(htmlStr hString: String)
    {
        let data = Data(hString.utf8)
        if let attribString = try? NSMutableAttributedString(data: data,
                                                           options: [.documentType: NSAttributedString.DocumentType.html],
                                                           documentAttributes: nil) {
            self.textView.attributedText = attribString
        }
    }
    
    // keep in sync with ImageViewController:getImageData()
    private func getImageData()
    {
        var lat, lon: Double
        
        do {
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
            self.htmlString += "Drone Latitude: \(lat)<br>"
            self.htmlString += "Drone Longitude: \(lon)<br>"
            // build a maps URL for clicking on
            //let urlStr = "https://maps.google.com/maps/@?api=1&map_action=map&center=\(lat),\(lon)"
            //let urlStr = "https://maps.google.com/maps/search/?api=1&t=k&query=\(lat),\(lon)"
            //self.htmlString += "<a href='\(urlStr)'>\(urlStr)</a><br>"
        }
        catch {
            self.htmlString += "Lat/lon: \(error)<br>"
        }
        
        do {
            try self.htmlString += "Altitude: \(self.vc.theDroneImage!.getAltitude())<br>"
        }
        catch {
            self.htmlString += "Altitude: \(error)<br>"
        }
        
        do {
            try self.htmlString += "GimbalPitch/Theta \(self.vc.theDroneImage!.getGimbalPitchDegree())<br>"
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
        print("Configuring menus on calculate screen")
        
        let optionsMenu = UIMenu(title: "", children: [
            UIAction(title:"Settings", image: UIImage(systemName:"gear.circle")) {
                action in
                print("Settings")
                let vc = self.storyboard?.instantiateViewController(withIdentifier: "Settings") as! SettingsViewController
                vc.vc = self.vc
                self.navigationController?.pushViewController(vc, animated: true)
            },
            UIAction(title:"About", image: UIImage(systemName:"info.circle")) {
                action in
                print("About")
                let vc = self.storyboard?.instantiateViewController(withIdentifier: "About") as! AboutViewController
                vc.vc = self.vc
                self.navigationController?.pushViewController(vc, animated: true)
            },
            UIAction(title:"Debug", image: UIImage(systemName:"binoculars.fill")) {
                action in
                print("Debug")
                let vc = self.storyboard?.instantiateViewController(withIdentifier: "Debug") as! DebugViewController
                vc.vc = self.vc
                self.navigationController?.pushViewController(vc, animated: true)
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
    
    
} // CalculateViewController
