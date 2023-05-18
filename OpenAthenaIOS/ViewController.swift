//
//  ViewController.swift
//  OpenAthenaIOS
//  https://github.com/rdkgit/OpenAthenaIOS
//  https://openathena.com
//  Created by Bobby Krupczak on 1/27/23.
//

import UIKit

class ViewController: UIViewController {
    
    var app: AppDelegate = UIApplication.shared.delegate as! AppDelegate
    var version: Float = 1.00
    @IBOutlet var textView: UITextView!
    @IBOutlet var imageView: UIImageView!
    var dem: DigitalElevationModel?
    var theDroneImage: DroneImage?
    var htmlString: String = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("OpenAthena starts!")
        
        self.title = "OpenAthena"
        navigationController?.navigationBar.tintColor = .label
        view.backgroundColor = .white
        //navigationController?.navigationBar.tintColor = .systemPink
        configureMenuItems()
        
        textView.isEditable = false
        textView.isSelectable = true
        
        htmlString = "OpenAthena v\(version) starting<br>"
        htmlString += "Coordinate system is \(app.settings.outputMode)<p>"
        //htmlString += "1: load a Digital Elevation Model (DEM) &#\u{26F0};<br>" // GeoTIFF
        htmlString += "1: load a Digital Elevation Model (DEM) &#9968;<br>" // GeoTIFF
        htmlString += "2: load a drone image &#128444; <br>"
        htmlString += "3: calculate &#129518; <br>"
        htmlString += "<br>Mash the &#127937; button to begin!<br>"
        
        let attribString = try? NSMutableAttributedString(data: Data(htmlString.utf8),
                                                          options: [.documentType: NSAttributedString.DocumentType.html],
                                                     documentAttributes: nil)
        textView.attributedText = attribString
        
        imageView.contentMode = .scaleAspectFit
        imageView.image = UIImage(named:"athena")
        
        // let pinchGesture = UIPanGestureRecognizer(target: self,
        //                                         action: #selector(didPinch(_:)))
        //
        // textView.addGestureRecognizer(pinchGesture)
        
    }
    
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

}

