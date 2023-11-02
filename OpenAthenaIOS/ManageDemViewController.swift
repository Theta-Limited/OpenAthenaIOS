//
//  ManageDemViewController.swift
//  OpenAthenaIOS
//
//  Created by Bobby Krupczak on 10/12/23.
//
//  Manage elevation maps main screen
//  From here, you can lookup to find a map,
//  or manage the cache or potentially other
//  operations go here

import Foundation
import UIKit
import CoreLocation

class ManageDemViewController: UIViewController
{
    var app: AppDelegate = UIApplication.shared.delegate as! AppDelegate
    var vc: ViewController!
    @IBOutlet var latLonText: UITextField!
    @IBOutlet var lookupResults: UILabel!
    @IBOutlet var borderLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Manage Elevation Maps"
        borderLabel.text = "   "
        borderLabel.backgroundColor = .systemGray6
        
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        
        print("Loaded \(vc.demCache!.count()) cache entries")
    }
    
    // manage our DemCache entries
    @IBAction func didTapManageCache()
    {
        print("Manage elevation maps cache of \(vc.demCache!.count()) entries")
    
        let vct = self.storyboard?.instantiateViewController(withIdentifier: "DemCacheTable") as! DemCacheController
        vct.vc = vc
        
        self.navigationController?.pushViewController(vct, animated: true)
        
    } // didTapManageCache()
    
    // ipad apparently does not support the numeric keypad XXX
    // need to validate values obtained from text fields
    
    @IBAction func didTapLookup()
    {
        print("Going to lookup")
        
        // process latLon string; drop "degrees" and ()
        var latLonStr = latLonText.text
        latLonStr = latLonStr?.replacingOccurrences(of: "in degrees", with: "", options: .regularExpression)
        latLonStr = latLonStr?.replacingOccurrences(of: "(", with: "")
        latLonStr = latLonStr?.replacingOccurrences(of: ")", with: "")
        
        let pieces = latLonStr!.components(separatedBy: ",")
        if pieces.count == 2 {
            let lat = (pieces[0] as! NSString).doubleValue
            let lon = (pieces[1] as! NSString).doubleValue
            let demFilename = vc.demCache!.searchCache(lat: lat, lon: lon)
          if demFilename == "" || demFilename == nil {
               lookupResults.text = "Nothing found"
            }
            else {
                lookupResults.text = "Found \(demFilename)"
            }
        }
    } // didTapLookup()
    
} // ManageDemViewController
