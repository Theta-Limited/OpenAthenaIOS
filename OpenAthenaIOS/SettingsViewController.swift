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
    @IBOutlet var compassOffsetSlider: UISlider!
    @IBOutlet var compassOffsetLabel: UILabel!
    @IBOutlet var compassOffsetValueLabel: UILabel!
    var newCompassCorrection: Float = 0.0
    var newCompassSliderValue: Float = 100.0
    @IBOutlet var resetOffsetButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "OpenAthena Settings"
        view.backgroundColor = .secondarySystemBackground
        //view.overrideUserInterfaceStyle = .light
        
        print("SettingsView: outputMode raw value is \(app.settings.outputMode.rawValue)")
        
        pickerView.dataSource = self
        pickerView.delegate = self
        pickerView.selectRow(app.settings.outputMode.rawValue, inComponent: 0, animated: true)
        newOutputMode = app.settings.outputMode
        
        // initialize compass settings slider to current value and
        // set slider parameters; keep consistent with OAAndroid
        newCompassCorrection = app.settings.compassCorrection
        newCompassSliderValue = app.settings.compassSliderValue
        compassOffsetLabel.text = "Manual Azimuth Correction"
        compassOffsetValueLabel.text = "\(newCompassCorrection)"
        compassOffsetSlider.minimumValue = 0.0
        compassOffsetSlider.maximumValue = 200.0
        compassOffsetSlider.value = newCompassSliderValue
    }
    
    // from android OpenAthena
    // slider values 0..200 converted to compass offset correction -15,15
    private func calculateCompassCorrectionOffset(sliderValue: Float) -> Float
    {
        // convert slider value to -1,1 first
        var mappedValue: Float = (sliderValue / 100.0) - 1.0
        
        // use log function to gradually increase effect of value as further away
        // from middle
        let LOG_SCALE: Float = 0.05
        var logValue: Float
    
        if mappedValue > 0 {
            logValue = log(mappedValue * LOG_SCALE + 1.0)
        }
        else if mappedValue < 0 {
            logValue = -1.0 * log(-1.0*mappedValue * LOG_SCALE + 1.0)
        }
        else {
            logValue = 0.0
        }
        
        // scale the result to fit within range of -15,15 degrees
        var offset: Float = logValue * (15.0 / log(1 + LOG_SCALE))
        // chop offset to 2 decimal places
        offset = (offset * pow(10,2)).rounded(.toNearestOrAwayFromZero) / pow(10,2)
        return offset
    }
    
    // reset the compass slider value
    @IBAction func didTouchReset()
    {
        newCompassSliderValue = 100.0
        newCompassCorrection = 0.0
        compassOffsetSlider.value = 100.0
        compassOffsetValueLabel.text = "\(newCompassCorrection)"
    }
    
    // user changed value via slider
    @IBAction func compassCorrectionSliderDidSlide(_ sender: UISlider)
    {
        newCompassSliderValue = sender.value
        print("compassCorrection value set to \(newCompassSliderValue),\(newCompassCorrection)")
        newCompassCorrection = calculateCompassCorrectionOffset(sliderValue: newCompassSliderValue)
        //correctionTextField.text = "Manual Azimuth Correction: \(newCompassCorrection)"
        compassOffsetValueLabel.text = "\(newCompassCorrection)"
        
    }
    
    // user changed value via text view
    @IBAction func compassCorrectionTextFieldDidChange(textField: UITextField)
    {
        // strip text chars leaving just the numbers
        // if its not a valid number, then don't do anything
        var result = ""
        result = (textField.text?.filter("-0123456789.".contains))!
        if result == "" {
            return
        }
        
        print("New compass correction slider value is \(result)")
        newCompassSliderValue = Float(result) ?? 0.0
        newCompassCorrection = calculateCompassCorrectionOffset(sliderValue: newCompassSliderValue)
        //correctionTextField.text = "Manual Azimuth Correction: \(newCompassCorrection)"
        // update the slider too
        compassOffsetSlider.value = newCompassSliderValue
    }
    
    @IBAction func didTapSaveButton()
    {
        print("Saving defaults")
        
        app.settings.outputMode = newOutputMode
        app.settings.compassCorrection = newCompassCorrection
        app.settings.compassSliderValue = newCompassSliderValue
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

