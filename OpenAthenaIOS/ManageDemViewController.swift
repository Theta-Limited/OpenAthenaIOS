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
    var demCache: DemCache?
    @IBOutlet var latLonText: UITextField!
    @IBOutlet var lookupResults: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Manage Elevation Maps"
        
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        
        // reload dem cache now
        demCache = DemCache()
        print("Loaded \(demCache!.count()) cache entries")
    }
    
    // manage our DemCache entries
    @IBAction func didTapManageCache()
    {
        print("Manage elevation maps cache of \(demCache!.count()) entries")
    
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "DemCacheTable") as! DemCacheController
        
        self.navigationController?.pushViewController(vc, animated: true)
        
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
            let demFilename = demCache!.searchCache(lat: lat, lon: lon)
          if demFilename == "" || demFilename == nil {
               lookupResults.text = "Nothing found"
            }
            else {
                lookupResults.text = "Found \(demFilename)"
            }
        }
    } // didTapLookup()
    
}
