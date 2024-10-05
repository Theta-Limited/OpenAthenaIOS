// ManageDemViewController.swift
// OpenAthenaIOS
// Created by Bobby Krupczak on 10/12/23.
// Manage elevation maps main screen
// From here, you can lookup to find a map,
// or manage the cache or potentially other
// operations go here
// Copyright 2024, Theta Informatics LLC
// AGPLv3
// https://www.gnu.org/licenses/agpl-3.0.txt

import Foundation
import UIKit
import CoreLocation

class ManageDemViewController: UIViewController
{
    var app: AppDelegate = UIApplication.shared.delegate as! AppDelegate
    var vc: ViewController!
    @IBOutlet var latLonText: UITextField!
    //@IBOutlet var lookupResults: UILabel!
    @IBOutlet var borderLabel: UILabel!
    @IBOutlet var lookupResultsButton: UIButton!
    @IBOutlet var maritimeSwitch: UISwitch!
    var maritimeWarning: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Manage Elevation Maps"
        borderLabel.text = "   "
        borderLabel.backgroundColor = .systemGray6
        
        view.backgroundColor = .secondarySystemBackground
        //view.overrideUserInterfaceStyle = .light
        
        // its both a label and a button; right now, its
        // in label mode
        lookupResultsButton.isEnabled = false
        
        // set maritimeSwitch
        maritimeSwitch.setOn(app.settings.maritimeMode, animated: true)
    
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        
        print("Loaded \(vc.demCache!.count()) cache entries")
    }
    
    // re issue #56 handle maritime switch
    @IBAction func maritimeSwitchChanged(_ sender: UISwitch)
    {
        if maritimeSwitch.isOn {
            print("maritime mode enabled")
            app.settings.maritimeMode = true
            // raise alert if first time
            if maritimeWarning == false {
                // warn each time its enabled
                // maritimeWarning = true
                let alert = UIAlertController(title: "Warning",
                                              message: "Maritime mode is enabled.  Calculations will be very inaccurate over land!",
                                              preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
            if vc.theDroneImage != nil {
                vc.theDroneImage!.setMaritimeMode(mode: true)
            }
            if vc.dem != nil {
                vc.dem = nil
            }
        }
        else {
            print("maritime mode disabled")
            app.settings.maritimeMode = false
            if vc.theDroneImage != nil {
                vc.theDroneImage!.setMaritimeMode(mode: false)
            }
            if vc.dem != nil {
                vc.dem = nil // force re-load of DEM
            }
        }
    }
    
    // we enabled results button and user tapped it
    // to zoom in and inspect a DEM
    @IBAction func didTapResults()
    {
        if lookupResultsButton.currentTitle == nil {
            return
        }
        
        // given the name of the DEM file, get its cache entry
        
        // chop off "Found " to get results
        let pieces = lookupResultsButton.currentTitle!.components(separatedBy: " ")
        
        if pieces.count == 2 {
            // pieces[1] is the DEM_xxx filename
            let dem = vc.demCache?.searchCacheByFilename(filename: pieces[1])
            if dem != nil {
                let vct = self.storyboard?.instantiateViewController(withIdentifier: "DemCacheEntryController") as! DemCacheEntryController
                vct.cacheEntry = dem
                // re issue #52 set vc so that DemCacheEntryController does not crash due to nil vc value
                vct.vc = vc
                self.navigationController?.pushViewController(vct, animated: true)
            }
        }
    } // didTapResults
    
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
            let demFilename = vc.demCache!.searchCacheFilename(lat: lat, lon: lon)
          if demFilename == "" || demFilename == nil {
              lookupResultsButton.setTitle("Nothing found", for: .normal)
              lookupResultsButton.isEnabled = false
            }
            else {
                lookupResultsButton.setTitle("Found \(demFilename)", for: .normal)
                lookupResultsButton.isEnabled = true
            }
        }
    } // didTapLookup()
    
} // ManageDemViewController
