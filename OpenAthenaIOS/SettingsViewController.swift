//
//  SettingsViewController.swift
//  OpenAthenaIOS
//  https://github.com/rdkgit/OpenAthenaIOS
//  https://openathena.com
//  Created by Bobby Krupczak on 1/29/23.
//

import Foundation
import UIKit

class SettingsViewController: UIViewController {
    
    var app: AppDelegate = UIApplication.shared.delegate as! AppDelegate
    var vc: ViewController!
    @IBOutlet var pickerView: UIPickerView!
    var newOutputMode: AthenaSettings.OutputModes!
    var newLookupMode: AthenaSettings.DEMLookupModes!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "OpenAthena Settings"
        view.backgroundColor = .white
        
        print("SettingsView: outputMode raw value is \(app.settings.outputMode.rawValue)")
        
        pickerView.dataSource = self
        pickerView.delegate = self
        pickerView.selectRow(app.settings.outputMode.rawValue, inComponent: 0, animated: true)
        newOutputMode = app.settings.outputMode
        
    }
    
    @IBAction func didTapSaveButton()
    {
        print("Saving defaults")
        
        app.settings.outputMode = newOutputMode
        app.settings.writeDefaults()
        
        let alert = UIAlertController(title: "OpenAthena Settings",
                                      message: "Your settings have been saved",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Done", style: .default, handler: {_
            in print("done")
        }))
        present(alert,animated: true)
        
        vc.textView.text += "Coordinate system set to \(app.settings.outputMode)\n"
        vc.textView.text += "DEM Lookup mode set to \(app.settings.lookupMode)\n"
        
    } // save settings
    
} // SettingsViewController

extension SettingsViewController: UIPickerViewDataSource {
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return AthenaSettings.OutputModes.allCases.count
    }

} // SettingsViewController extension

extension SettingsViewController: UIPickerViewDelegate {
   
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return AthenaSettings.OutputModes.allCases[row].description
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        print("Settings picked \(row) in pickerView")
        newOutputMode = AthenaSettings.OutputModes(rawValue: row)
    }
    
} // SettingsViewController Extension

