//
//  ImageViewController.swift
//  OpenAthenaIOS
//  https://github.com/rdkgit/OpenAthenaIOS
//  https://openathena.com
//  Created by Bobby Krupczak on 1/28/23.
//  IOAcademy photo picker tutorial
//  Stack Overflow
//  questions/2660201/what-parameters-should-i-use-in-a-google-maps-url-to-go-to-a-lat-lon

import Photos
import PhotosUI
import UIKit
import Foundation
import UniformTypeIdentifiers
import ImageIO
import MobileCoreServices

class ImageViewController: UIViewController,
                           PHPickerViewControllerDelegate,
                           UIDocumentPickerDelegate,
                           UIScrollViewDelegate,
                           UIImagePickerControllerDelegate,
                           UINavigationControllerDelegate
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
    var documentPickerController: UIDocumentPickerViewController?
    var photoPicker: PHPickerViewController?
    var imagePicker: UIImagePickerController?
    var style: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // set html style
        style = "<style>body {font-size: \(app.settings.fontSize); } h1, h2 { display: inline; } </style>"

        self.title = "Choose Image \u{1F5bc}"
        view.backgroundColor = .secondarySystemBackground
        //view.overrideUserInterfaceStyle = .light
        
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

        imageView.contentMode = .scaleAspectFit
        
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
        }
        
        // set next button
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Next \u{1F9EE}", style: .plain, target: self, action: #selector(gotoNext))
        
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
    
    // when view is set to appear, reset the htmlString
    // if we go forward to calculate then back to selectImage,
    // viewDidLoad may not be called again and then we
    // run into scrolling issue
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        
        // don't reset the htmlString here because we may want to continue
        // to see the image data for currently selected image if
        // we go back from CalculateViewController
        // htmlString = "\(style)<b>OpenAthena</b><br>Select a drone image<br>"
        // setTextViewText(htmlStr: htmlString)
    }
    
    @objc func gotoNext() {
        guard vc.theDroneImage != nil else {
            //print("Please select a drone image")
            htmlString += "Please select a drone image<br>"
            setTextViewText(htmlStr: htmlString)
            //textView.attributedText = NSAttributedString(string: htmlString)
            return
        }
        let vc = storyboard?.instantiateViewController(withIdentifier: "Calculate") as! CalculateViewController
        vc.vc = self.vc
        navigationController?.pushViewController(vc, animated: true)
    }
    
    // ---------------------------------------------------------------------
    // select drone image from Documents
    // Document picker can't access photos though and thats
    // usually where drone images end up
    // this code path deprecated with auto elevation map selection/downloading
    // Don't use this approach now because its difficult to get
    // at drone images on this device; have to export, save to documents, etc.
    // better approach is to use the imagePickerController which has
    // access to photo libraries and gets image meta data
    
    @IBAction func didTapSelectImageFromDocuments()
    {
        //var config = PHPickerConfiguration(photoLibrary: .shared())
        //config.selectionLimit = 1
        //config.filter = .images
        //let vc = PHPickerViewController(configuration: config)
        //vc.delegate = self
        //present(vc, animated: true)
        
        // try a generic document picker instead of imag
        // remove TIFF as option but leave all other image types
        let types = [UTType.png, UTType.jpeg, UTType.bmp, UTType.data,
                     UTType.gif, UTType.heic, UTType.heif, UTType.image]
            
        // dont constantly re-create the picker controller so that we can
        // pick back up where we left off (last location)
        if documentPickerController == nil {
            
            documentPickerController = UIDocumentPickerViewController(forOpeningContentTypes: types)
            documentPickerController!.delegate = self
            if app.settings.imageDirectoryURL != nil {
                documentPickerController!.directoryURL = app.settings.imageDirectoryURL
            }
        }
        
        self.present(documentPickerController!, animated: true, completion: nil)
    }
                     
    // pick a photo via document picker
    public func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        
        guard let imageURL = urls.first else {
            print("error picking image")
            self.htmlString += "Error picking image; try again<br>"
            return
        }
            
        //print("picked geotiff \(tiffURL)")
        self.htmlString += "Picked image \(imageURL.lastPathComponent)<br>"
        
        let fileManager = FileManager.default
        if fileManager.isReadableFile(atPath: imageURL.path) == false {
            guard imageURL.startAccessingSecurityScopedResource() else {
                // raise error
                return
            }
        }
            
        do {
//            var data = try Data(contentsOf: imageURL)
//            var image = UIImage(data: data)
//            self.vc.theDroneImage = DroneImage()
//            self.vc.theDroneImage!.rawData = data
//            self.vc.theDroneImage!.theImage = image
//            self.vc.theDroneImage!.name = imageURL.lastPathComponent
//            self.vc.theDroneImage!.droneParams = self.vc.droneParams
//            self.vc.theDroneImage!.settings = app.settings
//            imageView.image = image
            
            var anImage = createDroneImage(imageURL: imageURL)
            
            // save the directory of where we got this file
            var aDir = imageURL.deletingLastPathComponent()
            app.settings.imageDirectoryURL = aDir
            app.settings.writeDefaults()
            
            // move metadata refreshing to droneimage class
            //let src = CGImageSourceCreateWithData(data as CFData,nil)!
            //let md = CGImageSourceCopyPropertiesAtIndex(src,0,nil) as! NSMutableDictionary
            //let md2 = CGImageSourceCopyMetadataAtIndex(src,0,nil)
            //self.vc.theDroneImage!.metaData = md
            //self.vc.theDroneImage!.rawMetaData = md2
            
            // self.vc.theDroneImage!.updateMetaData()

            // print out some of the meta data
            getImageData()
            
        }
        catch {
            print("Load image resulting in error \(error)")
            htmlString += "Loading image resulted in error \(error)<br>"
        }
        
        setTextViewText(htmlStr: htmlString)
        
        // call stopAccessing so as to not leak memory
        imageURL.stopAccessingSecurityScopedResource()
        
    } // picked image file

    public func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
       print("Document picker view was cancelled")
       dismiss(animated: true, completion: nil)
    }
    
    // ---------------------------------------------------------------------
    // select drone image from shared photos using Photo Picker
    // if we use the PHPickerViewController, we can't get at the
    // raw data of the photo and thus we can't get the XMP meta data
    // so for now, don't use this approach XXX
    // this code path not active
    
    @IBAction func didTapSelectPhoto()
    {
        if photoPicker == nil {
            var config = PHPickerConfiguration(photoLibrary: .shared())
            config.selectionLimit = 1
            config.filter = PHPickerFilter.any(of: [ .images ])
            photoPicker = PHPickerViewController(configuration: config)
            photoPicker!.delegate = self
        }
        present(photoPicker!, animated: true)
    }
    
    // PHPicker delegate functions
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult])
    {
        picker.dismiss(animated: true, completion: nil)
        
        results.first!.itemProvider.loadObject(ofClass: UIImage.self) { reading, error in
            guard let image = reading as? UIImage, error == nil else {
                print("Error reading image")
                self.htmlString += "Error loading image \(error)<br>"
                self.setTextViewText(htmlStr: self.htmlString)
                return
            }
            
            do {
                // might not be able to get the raw image data
                // var data = image XXX
                
                // if we switch pack to photo picker, we need to handle
                // determination of drone maker and create DroneImage or subclasses
                // based on the manufacturer XXX
                                
                var data = Data()
                self.vc.theDroneImage = DroneImage()
                self.vc.theDroneImage!.rawData = data
                self.vc.theDroneImage!.theImage = image
                self.vc.theDroneImage!.name = "unknown filename"
                self.vc.theDroneImage!.droneParams = self.vc.droneParams
                self.imageView.image = image
                self.vc.theDroneImage!.settings = self.app.settings

                // don't save directory since photo picker will do so
                
                self.vc.theDroneImage!.updateMetaData()
                
                // print out some of the meta data
                self.getImageData()
            }
            catch {
                print("Load photo result in error \(error)")
                self.htmlString += "Loading photo resulted in error \(error)<br>"
            }
        }
        setTextViewText(htmlStr: htmlString)
            
    } // photo picker
    
    // ---------------------------------------------------------------------
    // pick image from photos; make sure we have permission and
    // we should be able to access raw image data as well as metadata
    // for image
    // code path is active combined with auto elevation map fetching
    // and downloading!
    
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
            do {
                
                var anImage = createDroneImage(imageURL: imageURL!)
                
//                let data = try Data(contentsOf: imageURL!)
//                var image = UIImage(data: data)
//                self.vc.theDroneImage = DroneImage()
//                self.vc.theDroneImage!.rawData = data
//                self.vc.theDroneImage!.theImage = image
//                self.vc.theDroneImage!.name = imageURL!.lastPathComponent
//                self.vc.theDroneImage!.droneParams = self.vc.droneParams
//                imageView.image = image
//                self.vc.theDroneImage!.settings = app.settings
                
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
                    let groundAltStr = roundDigitsToString(val: groundAlt ?? -1.0, precision: 0)
                    self.htmlString += "Ground altitude under drone is \(groundAltStr)m (hae)<br>"
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
        
        setTextViewText(htmlStr: htmlString)
                
    } // imagePicker
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController)
    {
        picker.dismiss(animated: true, completion: nil)
    }
    
    // ---------------------------------------------------------------------
    // regardless of picker, create a DroneImage and load raw image data
    // we need raw image data to access meta data and XMP/XML additions
    
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
        
        do {
            self.htmlString += "Image date: \(self.vc.theDroneImage!.getDateTimeUTC())<br>"
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
            self.htmlString += "Latitude: \(latStr)<br>"
            self.htmlString += "Longitude: \(lonStr)<br>"
            // build a maps URL for clicking on
            //let urlStr = "https://maps.google.com/maps/@?api=1&map_action=map&center=\(lat),\(lon)"
            let urlStr = "https://maps.google.com/maps/search/?api=1&t=k&query=\(lat),\(lon)"
            self.htmlString += "<a href='\(urlStr)'>\(urlStr)</a><br>"
            
        }
        catch {
            self.htmlString += "Lat/lon: \(error)<br>"
        }
        
        do {
            let droneAlt = try self.vc.theDroneImage!.getAltitude()
            // re issue #30, round degrees to 6 and distance/alt to 0
            let droneAltStr = roundDigitsToString(val: droneAlt, precision: 0)
            self.htmlString += "Drone altitude: \(droneAltStr)m (hae)<br>"
        }
        catch {
            self.htmlString += "Drone altitude: \(error)<br>"
        }
        
//        do {
//            let droneRelAlt = try self.vc.theDroneImage!.getRelativeAltitude()
//            let droneRelAltStr = roundDigitsToString(val: droneRelAlt, precision: 6)
//            self.htmlString += "Drone relative altitude: \(droneRelAltStr)m (hae)<br>"
//        }
//        catch {
//            self.htmlString += "Drone relative altitude: not reported<br>"
//        }
        
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
        
        do {
            try self.htmlString += "DigitalZoom: \(self.vc.theDroneImage!.getZoom())<br>"
        }
        catch {
            self.htmlString += "Zoom: \(error)<br>"
        }
        
        self.htmlString += "Is Drone? \(self.vc.theDroneImage!.isDroneImage())<br>"
        
        // display the text finally!
        setTextViewText(htmlStr: self.htmlString)
        
    } // getImageData
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        //print("viewForZooming returning imageView")
        return contentView
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
                htmlString += "Touch 🧮 to continue<br>"
                
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
        
    } // findLoadElevationModel
    
    // user has specifically requested we got get an elevation map/model
    // if it succeeds, load it
    private func fetchNewElevationMap(lat: Double, lon: Double, len: Double)
    {
        let aDownloader = DemDownloader(lat: lat, lon: lon, length: len)
        aDownloader.download(completionHandler: { ( resultCode, bytes, filename ) in
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
                    self.htmlString += "Touching 🧮 to continue<br>"
                    self.updateTextView()
                }
            }
            else {
                self.htmlString += "Unable to download elevation map: \(resultStr)<br>"
                self.updateTextView()
            }
            
        })
        
    } // fetchNewElevationMap
    
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
        
    } // shouldI?
    
    // update the text view while not on main ui thread
    // call this function from completion handlers and other
    // code blocks that are not allowed to directly call the main UI thread
    private func updateTextView()
    {
        DispatchQueue.main.async {
            self.setTextViewText(htmlStr: self.htmlString)
        }
    }
    
    // take htmlString and encode it and set
    // it to our textView
    private func setTextViewTextOld(htmlStr hString: String)
    {
        //let data = Data(hString.utf8)
        let data = hString.data(using: String.Encoding.utf16, allowLossyConversion: true)
        let font = UIFont.systemFont(ofSize: CGFloat(app.settings.fontSize))
        
        if let d = data {
            if let attribString = try? NSMutableAttributedString(data: d,
                                                                 options: [.documentType: NSAttributedString.DocumentType.html],
                                                                 documentAttributes: nil) {
                
                attribString.addAttribute(NSAttributedString.Key.font, value: font,
                                          range: NSRange(location: 0,length: attribString.length))
                attribString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.label, range: NSMakeRange(0,attribString.length))
                
                self.textView.attributedText = attribString
            }
        }
    } // setTextViewOld
    
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
    
    // take a double (e.g. lat, lon, elevation, etc. and round to 6 digits of precision and
    // return string
    public func roundDigitsToString(val: Double, precision: Double) -> String {
        let num = (val * pow(10,precision)).rounded(.toNearestOrAwayFromZero) / pow(10,precision)
        // if precision is 0, drop the .0 from float
        if precision == 0 {
            return String(Int(num))
        }
        return String(num)
    }
    
} // ImageViewController
