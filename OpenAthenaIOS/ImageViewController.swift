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

class ImageViewController: UIViewController , //PHPickerViewControllerDelegate,
                           UIDocumentPickerDelegate,
                           UIScrollViewDelegate {
    
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
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "Choose Image \u{1F5bc}"
        view.backgroundColor = .white
        
        // build our view/display
        
        scrollView.frame = view.bounds
        scrollView.zoomScale = 1.0
        scrollView.maximumZoomScale = 5.0
        scrollView.minimumZoomScale = 0.5
        scrollView.delegate = self
        scrollView.isUserInteractionEnabled = true
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.translatesAutoresizingMaskIntoConstraints = false

        imageView.contentMode = .scaleAspectFit
        
        textView.isSelectable = true
        textView.isEditable = false
        textView.isScrollEnabled = false
        textView.font = .systemFont(ofSize: 16)
        htmlString = "Select a drone image<br>"
        setTextViewText(htmlStr: htmlString)
        
        // button setup
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
    
    @objc func gotoNext() {
        guard vc.theDroneImage != nil else {
            //print("Please select a drone image")
            htmlString += "Please select a drone image<br>"
            textView.attributedText = NSAttributedString(string: htmlString)
            return
        }
        let vc = storyboard?.instantiateViewController(withIdentifier: "Calculate") as! CalculateViewController
        vc.vc = self.vc
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @IBAction func didTapSelectImage()
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
            
              // if we wanted permissions to access photo library, do this
              // before we create the picker; unfortunately,
              // you either pick images or you pick documents, but you can't
              // do both from single picker XXX
            
//            PHPhotoLibrary.requestAuthorization { (status) in
//                if status == .authorized {
//                    print("Authorized to access photo library")
//                }
//                else {
//                    print("Not authorized to access photo library")
//                }
//            }
            
            documentPickerController = UIDocumentPickerViewController(forOpeningContentTypes: types)
            documentPickerController!.delegate = self
            if app.settings.imageDirectoryURL != nil {
                documentPickerController!.directoryURL = app.settings.imageDirectoryURL
            }
        }
        
        self.present(documentPickerController!, animated: true, completion: nil)
    }
    
    // this function used with photo picker; we've moved to document picker
    // so we can access folders/files other than just ios photo library
//    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
//        picker.dismiss(animated: true, completion: nil)
//
//        results.forEach { result in
//            result.itemProvider.loadObject(ofClass: UIImage.self) { reading, error in
//                guard let image = reading as? UIImage, error == nil else {
//                    DispatchQueue.main.async {
//                        self.htmlString += "Error reading image . . .<br>"
//                        self.textView.attributedText = NSAttributedString(string: self.htmlString)
//                    }
//                    return
//                }
//                self.vc.theDroneImage = DroneImage()
//                self.vc.theDroneImage!.theImage = image
//                self.vc.theDroneImage!.name = result.itemProvider.suggestedName
//                result.itemProvider.loadDataRepresentation(forTypeIdentifier: UTType.image.identifier) { data, err in
//                    if let data = data {
//                        let src = CGImageSourceCreateWithData(data as CFData,nil)!
//                        //let md = CGImageSourceCopyPropertiesAtIndex(src,0,nil) as! [AnyHashable:Any]
//                        let md = CGImageSourceCopyPropertiesAtIndex(src,0,nil) as! NSMutableDictionary
//
//                        let md2 = CGImageSourceCopyMetadataAtIndex(src,0,nil)
//
//                        self.vc.theDroneImage!.metaData = md
//                        self.vc.theDroneImage!.rawMetaData = md2
//                        self.vc.theDroneImage!.rawData = data as Data
//
//                        DispatchQueue.main.async { self.getImageData() }
//                    }
//                }
//
//                DispatchQueue.main.async {
//
//                    self.imageView.image = image
//                    self.htmlString = "Loaded image \(result.itemProvider.suggestedName) . . .<br>"
//                    self.textView.attributedText = NSAttributedString(string: self.htmlString)
//
//                } // DispatchQueue
//
//            } //result.itemProvidd
//
//        } // results.forEach
//
//    } // picker
                               
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
            var data = try Data(contentsOf: imageURL)
            var image = UIImage(data: data)
            self.vc.theDroneImage = DroneImage()
            self.vc.theDroneImage!.rawData = data
            self.vc.theDroneImage!.theImage = image
            self.vc.theDroneImage!.name = imageURL.lastPathComponent
            self.vc.theDroneImage!.droneParams = self.vc.droneParams
            
            imageView.image = image
            
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
            
            self.vc.theDroneImage!.updateMetaData()

            // print out some of the meta data
            getImageData()
        }
        catch {
            print("Load image resulting in error \(error)")
            htmlString += "Loading image resulted in error \(error)<br>"
        }
        
        setTextViewText(htmlStr: htmlString)
        
        //imageURL.stopAccessingSecurityScopedResource()
        
    } // picked image file

    public func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
       print("Document picker view was cancelled")
       dismiss(animated: true, completion: nil)
    }
    
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
            self.htmlString += "Latitude: \(lat)<br>"
            self.htmlString += "Longitude: \(lon)<br>"
            // build a maps URL for clicking on
            //let urlStr = "https://maps.google.com/maps/@?api=1&map_action=map&center=\(lat),\(lon)"
            let urlStr = "https://maps.google.com/maps/search/?api=1&t=k&query=\(lat),\(lon)"
            self.htmlString += "<a href='\(urlStr)'>\(urlStr)</a><br>"
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
        
        do {
            try self.htmlString += "DigitalZoom: \(self.vc.theDroneImage!.getZoom())<br>"
        }
        catch {
            self.htmlString += "Zoom: \(error)<br>"
        }
        
        self.htmlString += "Is Drone? \(self.vc.theDroneImage!.isDroneImage())"
        
        // display the text finally!
        setTextViewText(htmlStr: self.htmlString)
        
    } // getImageData
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        //print("viewForZooming returning imageView")
        return contentView
    }
    
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
    
} // ImageViewController
