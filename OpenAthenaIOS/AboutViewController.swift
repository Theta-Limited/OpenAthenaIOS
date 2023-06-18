//
//  AboutViewController.swift
//  OpenAthenaIOS
//  https://github.com/rdkgit/OpenAthenaIOS
//  https://openathena.com
//  Created by Bobby Krupczak on 1/27/23.
//

import UIKit

class AboutViewController: UIViewController, UIScrollViewDelegate {
    
    var app: AppDelegate = UIApplication.shared.delegate as! AppDelegate
    var imageView: UIImageView = UIImageView()
    var textView: UITextView = UITextView()
    var stackView: UIStackView = UIStackView()
    var scrollView: UIScrollView = UIScrollView()
    var contentView: UIView = UIView()
    var vc: ViewController!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "About OpenAthena"
        view.backgroundColor = .white
    
        // scrollview
        scrollView.frame = view.bounds
        scrollView.zoomScale = 1.0
        scrollView.maximumZoomScale = 5.0
        scrollView.minimumZoomScale = 0.5
        scrollView.delegate = self
        scrollView.isUserInteractionEnabled = true
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        // text view
        textView.isSelectable = true
        textView.isEditable = false
        textView.font = .systemFont(ofSize: 16)
        textView.isScrollEnabled = false

        // image view
        imageView.image = UIImage(named: "athena")
        imageView.contentMode = .scaleAspectFit

        // stackview
        stackView.frame = view.bounds
        //stackView.backgroundColor = .systemYellow
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
        let htmlString = "<!DOCTYPE html><html><body><h2>OpenAthena alpha version \(vc!.getAppVersion())</h2>"
        + "Matthew Krupczak, Bobby Krupczak, et al.<br>"
        + "GPL-3.0, some rights reserved "
        + "<a href=\"https://openathena.com/\">OpenAthena.com</a><br>"
        + "<br>Open Athena allows common drones to spot precise geodetic locations.<br>"
        + "<br><a href=\"https://github.com/mkrupczak3/OpenAthena\">View the project on GitHub</a>"
        + "<p>Project maintained by <a href=\"https://github.com/mkrupczak3\">mkrupczak3</a><br><p>"
        
        // XXX add libraries here
        + "Software libraries used:"
        + "<ul>"
        + "<li><a href='https://github.com/ngageoint'>National Geospatial-Intelligence Agency TIFF library</a></li>"
        + "<li><a href='https://github.com/Dimowner/WGS84_TO_SK42/'>WGS84 to CK42 library</a></li>"
        + "<li><a href='https://github.com/ngageoint/'>National Geospatial-Intelligence Agency MGRS conversion library</a></li>"
        + "<li><a href='https://github.com/wtw-software/UTMConversion'>UTMConversion</a></li>"
        + "<li><a href='https://github.com/ky1vstar/NSExceptionSwift'>NSExceptionSwift</a></li>"
        + "</ul>"
        
        // privacy policy
        + "<br>See <a href='https://openathena.com/privacy'>this page</a> for the OpenAthena privacy policy"
           
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
    
} // AboutViewController
