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
    var version: Float = 1.20
    @IBOutlet var textView: UITextView!
    @IBOutlet var imageView: UIImageView!
    var dem: DigitalElevationModel?
    var theDroneImage: DroneImage?
    var htmlString: String = ""
    var droneParams: DroneParams?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("OpenAthena starts!")
        
        print("viewController: output mode is \(app.settings.outputMode)")
        print("viewController: output mode rawval is \(app.settings.outputMode.rawValue)")
        
        self.title = "OpenAthena"
        navigationController?.navigationBar.tintColor = .label
        view.backgroundColor = .white
        //navigationController?.navigationBar.tintColor = .systemPink
        configureMenuItems()
        
        droneParams = DroneParams()
        
        textView.isEditable = false
        textView.isSelectable = true
        
      
        imageView.contentMode = .scaleAspectFit
        imageView.image = UIImage(named:"athena")
        
        // let pinchGesture = UIPanGestureRecognizer(target: self,
        //                                         action: #selector(didPinch(_:)))
        //
        // textView.addGestureRecognizer(pinchGesture)
        
        doMain()
        testEGM96Offsets()
        
    } // viewDidLoad
    
    private func doMain()
    {
        htmlString = "OpenAthena alpha v\(version) starting<br>"
        htmlString += "Coordinate system is \(app.settings.outputMode)<p>"
        //htmlString += "1: load a Digital Elevation Model (DEM) &#\u{26F0};<br>" // GeoTIFF
        htmlString += "1: load a Digital Elevation Model (DEM) &#9968;<br>" // GeoTIFF
        htmlString += "2: load a drone image &#128444; <br>"
        htmlString += "3: calculate &#129518; <br>"
        htmlString += "<br>Mash the &#127937; button to begin!<br>"
        
        //let aLocation = EGM96Location(lat: 33.753746, lng: -84.386330)
        //let offset = EGM96Geoid.getOffset(location: aLocation)
        //htmlString += "<br>Offset at \(aLocation) is \(offset)m<br>"
        
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
        
        print("ViewController viewWillAppear invoked")
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
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "Elevation") as! ElevationViewController
        vc.vc = self
        self.navigationController?.pushViewController(vc, animated: true)
    }

    // create our main menu and glue it into navigation controller
    private func configureMenuItems()
    {
        print("Configuring menus on main screen")
        
        let optionsMenu = UIMenu(title: "", children: [
            UIAction(title:"Settings", image: UIImage(systemName:"gear.circle")) {
                action in
                print("Settings")
                let vc = self.storyboard?.instantiateViewController(withIdentifier: "Settings") as! SettingsViewController
                vc.vc = self
                self.navigationController?.pushViewController(vc, animated: true)
            },
            UIAction(title:"About", image: UIImage(systemName:"info.circle")) {
                action in
                print("About")
                let vc = self.storyboard?.instantiateViewController(withIdentifier: "About") as! AboutViewController
                vc.vc = self
                self.navigationController?.pushViewController(vc, animated: true)
            },
            UIAction(title:"Debug", image: UIImage(systemName:"binoculars.fill")) {
                action in
                print("Debug")
                let vc = self.storyboard?.instantiateViewController(withIdentifier: "Debug") as! DebugViewController
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
    
    func getAppVersion() -> String { return "\(version)" }

    // take htmlString and encode it and set
    // it to our textView
    private func setTextViewText(htmlStr hString: String)
    {
        let data = Data(hString.utf8)
        let font = UIFont.systemFont(ofSize: CGFloat(app.settings.fontSize))
        
        if let attribString = try? NSMutableAttributedString(data: data,
                                                           options: [.documentType: NSAttributedString.DocumentType.html],
                                                           documentAttributes: nil) {
            attribString.addAttribute(NSAttributedString.Key.font, value: font, range: NSRange(location: 0,
                                                                                               length: attribString.length))
            self.textView.attributedText = attribString
        }
    }
    
} // ViewController

