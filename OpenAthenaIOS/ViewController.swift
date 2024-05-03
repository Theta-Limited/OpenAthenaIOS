//
//  ViewController.swift
//  OpenAthenaIOS
//  https://github.com/rdkgit/OpenAthenaIOS
//  https://openathena.com
//  Created by Bobby Krupczak on 1/27/23.
//
//  App main view controller

import UIKit

class ViewController: UIViewController {
    
    var app: AppDelegate = UIApplication.shared.delegate as! AppDelegate
    var version: Double = 2.61
    @IBOutlet var textView: UITextView!
    @IBOutlet var imageView: UIImageView!
    var dem: DigitalElevationModel?
    var theDroneImage: DroneImage?
    var htmlString: String = ""
    var droneParams: DroneParams?
    var demCache: DemCache?
    var style: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("OpenAthena starts!")
        
        // set html style and accommodate dark mode and light mode
        //
        style =
    "<style>body {font-size: \(app.settings.fontSize); } h1, h2 { display: inline; } </style>"
        
        //textView.textColor = .label
        //textView.overrideUserInterfaceStyle = .unspecified
        
        print("viewController: output mode is \(app.settings.outputMode)")
        //print("viewController: output mode rawval is \(app.settings.outputMode.rawValue)")
        print("viewController: units mode is \(app.settings.unitsMode)")
        
        self.title = "OpenAthena"
        navigationController?.navigationBar.tintColor = .label
        view.backgroundColor = .secondarySystemBackground
        //view.overrideUserInterfaceStyle = .light
        //navigationController?.navigationBar.tintColor = .systemPink
        configureMenuItems()
        
        droneParams = DroneParams()
        if app.settings.droneParamsBookmark != nil {
            
            // convert bookmark back into URL; save in defaults too
            do {
                var isStale = false
                let aURL = try URL(resolvingBookmarkData: app.settings.droneParamsBookmark!, bookmarkDataIsStale: &isStale)
                app.settings.droneParamsURL = aURL
                print("Going to load drone params from user supplied bookmark/file \(app.settings.droneParamsURL)")
                droneParams = DroneParams(jsonURL: app.settings.droneParamsURL!)
                print("Drone params date \(droneParams?.droneParamsDate ?? "unkown")")
                // depending on permissions, a droneParams json file may be loadable
                // via dialog but not loadable at app start up; make sure we can
                // fall back to the bundled loan param
                // re issue #19
                if droneParams == nil || droneParams?.droneParamsDate == nil || droneParams?.droneParamsDate == "" {
                    print("Defaulting back to bundled droneParams file")
                    droneParams = DroneParams()
                }
            }
            catch {
                print("Unable to convert saved drone params bookmark back to URL")
            }
        }
        
        // load DEM cache
        demCache = DemCache()
        print("Loaded \(demCache!.count()) cache entries")
        
        textView.isEditable = false
        textView.isSelectable = true
        //textView.textColor = .label
        
        imageView.contentMode = .scaleAspectFit
        imageView.image = UIImage(named:"athena")
        
        // let pinchGesture = UIPanGestureRecognizer(target: self,
        //                                         action: #selector(didPinch(_:)))
        //
        // textView.addGestureRecognizer(pinchGesture)
        
        doMain()
        testEGM96Offsets()
        
        requestNotificationAuthorization()
        
    } // viewDidLoad
    
    // if user changed from dark mode to regular mode, or vice versa, this call back
    // will have been invoked.  If color appearance changed, re-draw the html string
    // using appropriate font colors
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?)
    {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if self.traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
           setTextViewText(htmlStr: htmlString)
        }
    }
    
    private func requestNotificationAuthorization()
    {
        let authOptions = UNAuthorizationOptions.init(arrayLiteral: .alert, .badge, .sound)
        app.uNC.requestAuthorization(options: authOptions, completionHandler: { (success, error) in
            if let error = error {
                print("Error requesting notification authorization \(error)")
            }
            else {
                print("Notifications allowed: \(success)")
            }
            
        })
    }
    
    private func doMain()
    {
        htmlString = "\(style)<body><b>OpenAthena\u{2122} v\(getAppVersion())</b><br>"
        htmlString += "Coordinate system is \(app.settings.outputMode)<p>"
        htmlString += "Units: \(app.settings.unitsMode)<p>"
        
        // we dont explicitly load a DEM now since adding support for
        // automatic DEM downloading/loading
        // htmlString += "1: load a Digital Elevation Model (DEM) &#\u{26F0};<br>" // GeoTIFF
        // htmlString += "1: load a Digital Elevation Model (DEM) &#9968;<br>" // GeoTIFF
        
        // htmlString += "1: load a drone image &#128444; <br>"
        // htmlString += "2: calculate &#129518; <br>"
        // htmlString += "<br>Mash the &#127937; button to begin!<br>"
        
        // htmlString += "<br>Drone params date: \(droneParams?.droneParamsDate ?? "none; please load")<br>"
        
        // let aLocation = EGM96Location(lat: 33.753746, lng: -84.386330)
        // let offset = EGM96Geoid.getOffset(location: aLocation)
        // htmlString += "<br>Offset at \(aLocation) is \(offset)m<br>"
        
        htmlString += "Press &#127937; Start to begin<br>"
        
        setTextViewText(htmlStr: htmlString)
        
    }
    
    private func testEGM96Offsets() {
        
        var offset: Double = 0.0
        var lat: Double = 0.0
        var lng: Double = 0.0
        
        // atlanta
        // lat, lng +33.7490, -84.3880
        lat = 33.7490
        lng = -84.3880
        offset = EGM96Geoid.getOffset(lat: lat, lng: lng)
        print("Atlanta (\(lat),\(lng)) offset \(offset)")
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // print("ViewController viewWillAppear invoked")
        doMain()
        
    } // viewWillAppear
    
    @objc private func didPinch(_ gesture: UIPinchGestureRecognizer) {
        print("didPinch invoked")
        if gesture.state == .changed {
            let scale = gesture.scale
            print(scale)
        }
    }
    
    @IBAction func didTapStartButton() {
        print("Start!")
        // start -> load digital elevation model -> load image -> calculate
        //let vc = self.storyboard?.instantiateViewController(withIdentifier: "Elevation") as! //ElevationViewController
        
        // go straight to LoadCalculateViewController to select an image
        let vc = LoadCalculateViewController()
        vc.vc = self
        
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    // create our main menu and glue it into navigation controller
    private func configureMenuItems()
    {
        //print("Configuring menus on main screen")
        
        let optionsMenu = UIMenu(title: "", children: [
            UIAction(title:"Settings", image: UIImage(systemName:"gear")) {
                action in
                //print("Settings")
                //let vc = self.storyboard?.instantiateViewController(withIdentifier: "Settings") //as! SettingsViewController
                let vc = SettingsViewController()
                vc.vc = self
                self.navigationController?.pushViewController(vc, animated: true)
            },
            UIAction(title:"Manage Elevation Maps", image: UIImage(systemName:"map")) {
                action in
                //print("Manage elevation maps")
                let vc = self.storyboard?.instantiateViewController(withIdentifier: "ManageDemViewController") as! ManageDemViewController
                vc.vc = self
                self.navigationController?.pushViewController(vc, animated: true)
            },
            UIAction(title:"Debug", image: UIImage(systemName:"binoculars.fill")) {
                action in
                //print("Debug")
                let vc = self.storyboard?.instantiateViewController(withIdentifier: "Debug") as! DebugViewController
                vc.vc = self
                self.navigationController?.pushViewController(vc, animated: true)
            },
            UIAction(title:"Load Drone Info", image: UIImage(named:"drone")) {
                action in
                //print("Load Drone Models")
                let vc = DroneViewController()
                vc.vc = self
                self.navigationController?.pushViewController(vc, animated: true)
            },
            UIAction(title:"About", image: UIImage(systemName:"info.circle")) {
                action in
                //print("About")
                let vc = self.storyboard?.instantiateViewController(withIdentifier: "About") as! AboutViewController
                vc.vc = self
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
    
    func getAppVersion() -> String 
    { 
        let formattedString = String(format: "%.2f",version);
        return formattedString
    }
    func getAppBuildNumber() -> String? {
        return Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String
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
            
            //attribString.addAttribute(NSAttributedString.Key.foregroundColor, value: //UIColor.label, range: NSMakeRange(0,attribString.length))
            
            attribString.addAttribute(NSAttributedString.Key.foregroundColor, value:
                UIColor.white, range: NSMakeRange(0,attribString.length))
            
            self.textView.attributedText = attribString
        }
    }
    
    // take html string and encode it and set it to our textView
    // use newer function, written by ChatGPT, to better encode the HTML that
    // we want
    private func setTextViewText(htmlStr hString: String)
    {
        // re issue #37, run all of this on dispatchqueue main
        DispatchQueue.main.async {
            if let attribString = self.htmlToAttributedString(fromHTML: hString) {
                self.textView.attributedText = attribString
            }
        }
    }
    
    // written by ChatGPT with mods by rdk
    public func htmlToAttributedString(fromHTML html: String) -> NSAttributedString?
    {
        guard let data = html.data(using: .utf8) else { return nil }
        
        // options for document type and char encoding
        let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: String.Encoding.utf8.rawValue,
        ]
        
        // try to create an attributed string from the html
        do {
            var attributedString = try NSAttributedString(data: data, options: options, documentAttributes: nil )
            
            if traitCollection.userInterfaceStyle == .dark {
                attributedString = applyColorToAttributredString(attributedString, color: .white)
            }
            else {
                attributedString = applyColorToAttributredString(attributedString, color: .black)
            }
            return attributedString
        }
        catch {
            print("Error converting HTML to attributed string \(error)")
            return nil
        }
    }
    
    public func applyColorToAttributredString(_ attributedString: NSAttributedString, color: UIColor) -> NSAttributedString
    {
        let mutable = NSMutableAttributedString(attributedString: attributedString)
        mutable.addAttributes([.foregroundColor: color], range: NSRange(location: 0, length: mutable.length))
        return mutable
    }
    
} // ViewController

