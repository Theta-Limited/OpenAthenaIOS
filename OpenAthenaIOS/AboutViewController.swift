// AboutViewController.swift
// OpenAthenaIOS
// https://github.com/rdkgit/OpenAthenaIOS
// https://openathena.com
// Created by Bobby Krupczak on 1/27/23.
// Copyright 2024, Theta Informatics LLC
// AGPLv3
// https://www.gnu.org/licenses/agpl-3.0.txt

import UIKit

class AboutViewController: UIViewController, UIScrollViewDelegate {
    
    var app: AppDelegate = UIApplication.shared.delegate as! AppDelegate
    var imageView: UIImageView = UIImageView()
    var textView: UITextView = UITextView()
    var stackView: UIStackView = UIStackView()
    var scrollView: UIScrollView = UIScrollView()
    var contentView: UIView = UIView()
    var vc: ViewController!
    var style: String = ""
    var htmlString: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("AboutViewController viewDidLoad starting")
        
        // set html style
        style = "<style>body {font-size: \(app.settings.fontSize); } h1, h2 { display: inline; } </style>"
        
        self.title = "About OpenAthena\u{2122}"
        view.backgroundColor = .secondarySystemBackground
        //view.overrideUserInterfaceStyle = .light
        
        // scrollview
        scrollView.frame = view.bounds
        scrollView.zoomScale = 1.0
        scrollView.maximumZoomScale = 5.0
        scrollView.minimumZoomScale = 0.5
        scrollView.delegate = self
        scrollView.isUserInteractionEnabled = true
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.backgroundColor = .secondarySystemBackground
        
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        // text view
        textView.isSelectable = true
        textView.isEditable = false
        textView.font = .systemFont(ofSize: 16)
        textView.isScrollEnabled = true
        textView.backgroundColor = .secondarySystemBackground

        // image view
        imageView.image = UIImage(named: "athena")
        imageView.contentMode = .scaleAspectFit

        // stackview
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
        
        getAbout()
        
        // set layout constraints
        
        textView.heightAnchor.constraint(equalToConstant: 0.66*view.frame.size.height).isActive = true
        imageView.heightAnchor.constraint(equalToConstant: 0.33*view.frame.size.height).isActive = true

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
    
    private func getAbout()
    {
        htmlString = "\(style) "
        + "<b>OpenAthena\u{2122} version \(ViewController.getAppVersion()) build \(vc.getAppBuildNumber()!)</b></br>"
        + "Matthew Krupczak, Bobby Krupczak et al.<br>"
        + "AGPL-3.0, some rights reserved "
        + "<a href='https://openathena.com/'>OpenAthena.com</a><br>"
        + "<br>OpenAthena\u{2122} allows common drones to spot precise geodetic locations.<br>"
        
        + "<br>For best results, please calibrate your drone's compass\u{1F9ED} before flight.<br>"
        
        + "<br><a href='https://github.com/Theta-Limited/'>View the project on GitHub</a><br>"
                
        + "<br>Elevation maps/data obtained from <a href='https://www.opentopography.org'>OpenTopography</a> SRTM_GL1 and GLO-30 datasets.<br>"
        
        + "<br>NATO/MGRS, WGS84, UTM output vertical datum is EMG96 meters above mean sea level.  "
        + "CK-42 output vertical datum is meters height above the Krassowsky 1940 elipsoid.<br>"

        // privacy policy
        + "<br>See <a href='https://openathena.com/privacy'>this page</a> for the OpenAthena\u{2122} privacy policy<br>"
        + "<br>Device UID: \(UIDGenerator.getDeviceHostnamePhonetic())<br>"

        // add libraries, that we use, here
        + "<br>Software libraries used:<br>"
        + "<ul>"
        + "<li><a href='https://github.com/ngageoint'>National Geospatial-Intelligence Agency TIFF library</a> "
        + "<li><a href='https://github.com/Dimowner/WGS84_TO_SK42/'>WGS84 to CK42 library</a> "
        + "<li><a href='https://github.com/ngageoint/'>National Geospatial-Intelligence Agency MGRS conversion library</a> "
        + "<li><a href='https://github.com/wtw-software/UTMConversion'>UTMConversion</a> "
        + "<li><a href='https://github.com/ky1vstar/NSExceptionSwift'>NSExceptionSwift</a>  "
        + "<li><a href='https://github.com/matthiaszimmermann/EGM96'>EGM96 offset</a>  "
        + "</ul>"
        
        setTextViewText(htmlStr: htmlString)
        
    } // getAbout()
    
    // pinch/zoom the entire stack view, not just image!
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        //print("viewForZooming returning imageView")
        return contentView
    }
    
    private func configureMenuItems()
    {
        
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
        // re issue #37, run entire on dispatchqueue
        DispatchQueue.main.async {
            if let attribString = self.vc.htmlToAttributedString(fromHTML: hString) {
                self.textView.attributedText = attribString
            }
        }
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?)
    {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if self.traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
           setTextViewText(htmlStr: htmlString)
        }
    }
    
} // AboutViewController
