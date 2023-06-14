//
//  ElevationViewController.swift
//  OpenAthenaIOS
//  https://github.com/rdkgit/OpenAthenaIOS
//  https://openathena.com
//  Created by Bobby Krupczak on 1/27/23

// download, build, import
// https://github.com/ngageoint/tiff-ios
// In OpenAthenaIOS project files, add library by file add via finder
// To fix build error, see this stack overflow article
// stackoverflow.com/questions/40896784/has-missing-or-invalid-cfbundleexecutable-in-its-info-plist
// Bridging header file
// Then fixed include file problems by hand; probably better way to do this XXX
// To get permission to access downloads and other directories:
// https://developer.apple.com/documentation/uikit/view_controllers/providing_access_to_directories

// We'd like to remember the folder we last looked at and when we open document
// picker again, start with last folder; solve this by not constantly
// recreating the document picker view controller

import UIKit
import Photos
import PhotosUI
import UniformTypeIdentifiers
import MobileCoreServices

class ElevationViewController: UIViewController, UIDocumentPickerDelegate, UIScrollViewDelegate {
    //PHPickerViewControllerDelegate
    
    var app: AppDelegate = UIApplication.shared.delegate as! AppDelegate
    var vc: ViewController!
    var textView: UITextView = UITextView()
    var imageView: UIImageView = UIImageView()
    var selectButton = UIButton(type: .system)
    var stackView = UIStackView()
    var scrollView = UIScrollView()
    var contentView = UIView()
    var htmlString: String = ""
    var documentPickerController: UIDocumentPickerViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // set up our document picker now so it will not get recreated constantly
//        let types = [UTType.tiff, UTType.png, UTType.jpeg, UTType.bmp, UTType.data,
//                     UTType.gif, UTType.heic, UTType.heif, UTType.image]
//
//        documentPickerController = UIDocumentPickerViewController(forOpeningContentTypes: types)
//        documentPickerController!.delegate = self
        
        self.title = "Load DEM \u{26F0}"
        view.backgroundColor = .white
        
        // why are some back buttons "back" and the one in this view
        // is "OpenAthena" ?
        
        // build the view/display of stackview, button, image, text all
        // within a scrollview then add constraints
        
        scrollView.frame = view.bounds
        scrollView.zoomScale = 1.0
        scrollView.maximumZoomScale = 5.0
        scrollView.minimumZoomScale = 0.5
        scrollView.delegate = self
        scrollView.isUserInteractionEnabled = true
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        imageView.contentMode = .center

        textView.isSelectable = true
        textView.isEditable = false
        textView.font = .systemFont(ofSize: 16)
        textView.isScrollEnabled = false
        htmlString = "Load a digital elevation model (in GeoTIFF format)<br>"
        setTextViewText(htmlStr: htmlString)
        
        // button setup
        selectButton.setTitle("Select DEM Image File \u{26F0}", for: .normal)
        selectButton.addTarget(self, action: #selector(didTapLoadButton), for: .touchUpInside)
        selectButton.layer.cornerRadius = 3.0
        //selectButton.titleLabel?.textAlignment = .center
        selectButton.clipsToBounds = true
        
        // stackview setup
        stackView.frame = scrollView.bounds // view or scrollview?
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.distribution = .fillProportionally
        //stackView.distribution = .fillEqually
        //stackView.distribution = .equalSpacing
        stackView.spacing = 5
        
        stackView.addArrangedSubview(selectButton)
        stackView.addArrangedSubview(imageView)
        stackView.addArrangedSubview(textView)
        
        // set next button
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Next \u{1F5bc}", style: .plain, target: self, action: #selector(gotoNext))
        
        if vc.dem != nil {
            htmlString += "Current GeoTIFF \(vc.dem?.tiffURL?.lastPathComponent ?? "")<br>"
            imageView.image = UIImage(named: "gnome-mime-image-tiff")
        }
        
        scrollView.addSubview(contentView)
        contentView.addSubview(stackView)
        view.addSubview(scrollView)
        
        // set constraints
        selectButton.heightAnchor.constraint(equalToConstant: 0.1*view.frame.size.height).isActive = true
        textView.heightAnchor.constraint(equalToConstant: 0.60*view.frame.size.height).isActive = true
        imageView.heightAnchor.constraint(equalToConstant: 0.30*view.frame.size.height).isActive = true

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
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        //print("viewForZooming returning imageView")
        return contentView
    }
    
    // allow usser to proceed to drone image selection even if
    // they don't have a DEM; will degrade accuracy
    
    @objc func gotoNext() {
        // check if they have set a tiffModelURL
        //guard vc.dem != nil else {
         //   print("Please select a GeoTIFF digital elevation model")
         //   self.htmlString += "Please select a GeoTIFF digital elevation model<br>"
         //   return
        //}
        if vc.dem == nil {
            print("Proceeding without a GeoTIFF digital elevation model will degrade accuracy")
            let alert = UIAlertController(title: "Proceed?",
                                          message: "Proceeding w/o a digital elevation model will reduce accuracy",
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: nil))
            alert.addAction(UIAlertAction(title: "Yes", style: .destructive,
                                    handler: {_ in
                let vc = self.storyboard?.instantiateViewController(withIdentifier: "ImageView") as! ImageViewController
                vc.vc = self.vc
                self.navigationController?.pushViewController(vc, animated: true)
            }))
            self.present(alert,animated: true)
        } else {
            let vc = storyboard?.instantiateViewController(withIdentifier: "ImageView") as! ImageViewController
            vc.vc = self.vc
            navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    @IBAction func didTapLoadButton()
    {
        print("Load DEM/GeoTIFF")
            
        //var config = PHPickerConfiguration(photoLibrary: .shared())
        //config.selectionLimit = 1
        //config.filter = .images
        //let vc = PHPickerViewController(configuration: config)
        //vc.delegate = self
        //present(vc, animated: true)
        
        // should restrict to only type tiff
        // let types = [UTType.tiff, UTType.png, UTType.jpeg, UTType.bmp, UTType.data,
        //              UTType.gif, UTType.heic, UTType.heif, UTType.image]
        
        let types = [UTType.tiff]
        
        if documentPickerController  == nil {
            documentPickerController = UIDocumentPickerViewController(forOpeningContentTypes: types)
            documentPickerController!.delegate = self
        }
        
        self.present(documentPickerController!, animated: true, completion: nil)
        
        // to find where the simulator stores local files, in the simulator FileManager,
        // create a unique folder and then find that folder under
        // /users/rdk/Library/Developer/CoreSimulator/Devices/<device-hash>/data/Containers/Shared/
        //    /AppGroup/<group-hash>/File Provider Storage/
        // Then you can add/remove files to this directory
    }
    
//    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
//        picker.dismiss(animated: true, completion: nil)
//
//        results.forEach { result in
//            result.itemProvider.loadObject(ofClass: UIImage.self) { reading, error in
//                guard let image = reading as? UIImage, error == nil else {
//                    //print("Error reading image \(error)")
//                    DispatchQueue.main.async {
//                        self.self.htmlString += "Error reading image . . .<br>"
//                    }
//                    return
//                }
//
//                // save the DEM/GeoTIFF back in main ViewController for later use
//
//            } // loadObject
//        } // foreach result
//
//    } // picker
    
    public func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        
        // out with old, in with new or error
        imageView.image = nil
        vc.dem = nil
        
        guard let tiffURL = urls.first else {
            print("error picking document")
            self.htmlString += "Error picking document; try again<br>"
            setTextViewText(htmlStr: htmlString)
            return
        }
        
        //print("picked geotiff \(tiffURL)")
        self.htmlString += "Picked GeoTIFF \(tiffURL.lastPathComponent)<br>"
        
        // read/create a DEM from the GeoTIFF
        guard let dem = DigitalElevationModel(fromURL: tiffURL) else {
            self.htmlString += "Unable to create digital elevation model from \(tiffURL.lastPathComponent)<br>"
            setTextViewText(htmlStr: htmlString)
            return
        }
        vc.dem = dem
        
        imageView.image = UIImage(named:"gnome-mime-image-tiff.png")
        
        self.htmlString += "Digital elevation model (\(vc.dem!.getDemWidth()) X  \(vc.dem!.getDemHeight())) successfully read<br>"
        self.htmlString += "Width: \(vc.dem!.getDemWidth()) Height:\(vc.dem!.getDemHeight())<br>"
        self.htmlString += "Bounding box:<br>"
        self.htmlString += "Upper left ( \(vc.dem!.getMaxLatitude()),\(vc.dem!.getMinLongitude()) )<br>"
        self.htmlString += "Lower left ( \(vc.dem!.getMinLatitude()),\(vc.dem!.getMinLongitude()) )<br>"
        self.htmlString += "Upper right ( \(vc.dem!.getMaxLatitude()),\(vc.dem!.getMaxLongitude()) )<br>"
        self.htmlString += "Lower right ( \(vc.dem!.getMinLatitude()),\(vc.dem!.getMaxLongitude()) )<br>"

        var centerLat,centerLon : Double
            (centerLat,centerLon) = vc.dem!.getCenter()
            
        let urlStr = "https://maps.google.com/maps/search/?api=1&t=k&query=\(centerLat),\(centerLon)"
        self.htmlString += "<a href='\(urlStr)'>\(urlStr)</a><br>"
        
        setTextViewText(htmlStr: htmlString)
        
    } // picked a GeoTIFF file
    
    public func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        print("Document picker view was cancelled")
        dismiss(animated: true, completion: nil)
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
    
} // ElevationViewController
