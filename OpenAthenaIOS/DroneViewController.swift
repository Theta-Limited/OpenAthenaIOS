//
//  DroneViewController.swift
//  OpenAthenaIOS
//
//  https://github.com/Theta-Limited/OpenAthenaIOS
//  Created by Bobby Krupczak on 9/7/23.
//
//  Load a new droneModels.json file via dialog
//  Save this choice so its re-loaded on application
//  startup; if load fails, default back to bundled
//  droneModels.json file

import UIKit
import UniformTypeIdentifiers

class DroneViewController: UIViewController, UIDocumentPickerDelegate, UIScrollViewDelegate {
    
    var app: AppDelegate = UIApplication.shared.delegate as! AppDelegate
    var vc: ViewController!
    var htmlString: String = ""
    var textView: UITextView = UITextView()
    var selectButton = UIButton(type: .system)
    var stackView = UIStackView()
    var scrollView = UIScrollView()
    var contentView = UIView()
    var documentPickerController: UIDocumentPickerViewController?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Load Drone Info"
        view.backgroundColor = .secondarySystemBackground
        //view.overrideUserInterfaceStyle = .light
        
        // build rest of view by hand
        
        scrollView.frame = view.bounds
        scrollView.zoomScale = 1.0
        scrollView.maximumZoomScale = 5.0
        scrollView.minimumZoomScale = 0.5
        scrollView.delegate = self
        scrollView.isUserInteractionEnabled = true
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.backgroundColor = .secondarySystemBackground
        
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        textView.isSelectable = true
        textView.isEditable = false
        textView.font = .systemFont(ofSize: 16)
        textView.isScrollEnabled = false
        textView.backgroundColor = .secondarySystemBackground
        htmlString = "Load a drone information file (in JSON format)<br>"
        setTextViewText(htmlStr: htmlString)
        
        // button setup
        selectButton.setTitle("Select a Drone Information File", for: .normal)
        selectButton.addTarget(self, action: #selector(didTapLoadButton), for: .touchUpInside)
        selectButton.layer.cornerRadius = 3.0
        selectButton.clipsToBounds = true
        
        // stackView setup
        stackView.frame = view.bounds
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.distribution = .fillProportionally
        stackView.spacing = 5
        
        stackView.addArrangedSubview(selectButton)
        stackView.addArrangedSubview(textView)
        scrollView.addSubview(contentView)
        contentView.addSubview(stackView)
        view.addSubview(scrollView)
        
        // set constraints
        selectButton.heightAnchor.constraint(equalToConstant: 0.1*view.frame.size.height).isActive = true
        textView.heightAnchor.constraint(equalToConstant: 0.90*view.frame.size.height).isActive = true
        
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
        return contentView
    }
    
    @IBAction func didTapLoadButton()
    {
        print("Load a drone models.json file")
        
        let types = [UTType.json]
        
        if documentPickerController == nil {
            documentPickerController = UIDocumentPickerViewController(forOpeningContentTypes: types)
            documentPickerController!.delegate = self
        }
        
        self.present(documentPickerController!, animated: true, completion: nil)
    }
    
    public func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        
        // save old droneModels object in case of error
        let oldDroneParams = vc.droneParams
        
        guard let newURL = urls.first else {
            print("Error picking drone models json file")
            self.htmlString += "Error picking json drone models file; try again<br>"
            setTextViewText(htmlStr: htmlString)
            return
        }
        
        self.htmlString += "Going to load new drone models json file<br>"
        self.htmlString += "\(newURL.lastPathComponent)<br>"
        self.setTextViewText(htmlStr: htmlString)
        
        // re issue #19, make sure we have permission and if not, try to
        // raise our permission level
        // the URL we were using has permissions when its selected by user
        // via this dialog but when this url is saved and loaded at app
        // start time, the permissions are no longer present and the
        //  file can't be loaded
        var securityFlag: Bool = false
        
        if FileManager.default.isReadableFile(atPath: newURL.path) == false {
            securityFlag = newURL.startAccessingSecurityScopedResource()
            guard securityFlag == true else {
                print("Dont' have permission to read this droneModels json file")
                self.htmlString += "Don't have permission to read this file<br>"
                setTextViewText(htmlStr: htmlString)
                return
            }
        }
        
        let newDroneParams = DroneParams(jsonURL: newURL)
        
        // if empty or array count is one, we failed to load a valid file; let
        // user know and don't swap out DroneParams object
        if newDroneParams.droneCCDParams.isEmpty || newDroneParams.droneCCDParams.count == 1 {
            print("Error loading drone models json file")
            self.htmlString += "Error loading json drone models file; try again<br>"
            setTextViewText(htmlStr: htmlString)
            return
        }
        
        // swap old for new
        vc.droneParams = newDroneParams
        htmlString += "File date: \(vc.droneParams!.droneParamsDate!)<br>"
        htmlString += "CCD data for \(vc.droneParams!.droneCCDParams.count) drones<br>"
        setTextViewText(htmlStr: htmlString)
        
        // save the URL so it can be reloaded at next app startup
        // re issue #19, convert to a bookmark first before saving
        // so that we can read next time app starts
        // but we need to convert from bookmark back to url before reading again
        // we may need to do this conversion before stopping security access
        
        do {
            let bookmark = try newURL.bookmarkData(options: .minimalBookmark, includingResourceValuesForKeys: nil, relativeTo: nil)
            app.settings.droneParamsURL = newURL
            app.settings.droneParamsBookmark = bookmark
            app.settings.writeDefaults()
        }
        catch {
            print("DroneViewController: unable to convert url to bookmark for saving")
        }
        
        if securityFlag == true {
            newURL.stopAccessingSecurityScopedResource()
        }
        
    } // documentPicker 
    
    public func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        print("Document picker view was conancelled")
        dismiss(animated: true, completion: nil)
    }
    
    private func setTextViewText(htmlStr hString: String) {
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
    
} // DroneViewController
