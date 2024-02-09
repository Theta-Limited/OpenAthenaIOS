//
//  SettingsViewController.swift
//  OpenAthenaIOS
//  https://github.com/rdkgit/OpenAthenaIOS
//  https://openathena.com
//  Created by Bobby Krupczak on 1/29/23.
//

import Foundation
import UIKit

class SettingsViewController: UIViewController, UIScrollViewDelegate {
    
    var app: AppDelegate = UIApplication.shared.delegate as! AppDelegate
    var vc: ViewController!
    var pickerView: UIPickerView = UIPickerView()
    var newOutputMode: AthenaSettings.OutputModes!
    var newLookupMode: AthenaSettings.DEMLookupModes!
    var azOffsetSlider: UISlider = UISlider()
    var azOffsetLabel: UILabel = UILabel()
    //var azOffsetValueLabel: UILabel = UILabel()
    var contentView: UIView = UIView()
    var stackView: UIStackView = UIStackView()
    var newAZCorrection: Float = 0.0
    var newAZSliderValue: Float = 100.0
    @IBOutlet var resetOffsetButton: UIButton!
    var scrollView: UIScrollView = UIScrollView()
    var saveButton: UIButton = UIButton()
    var resetButton: UIButton = UIButton()
    var outputModeLabel: UILabel = UILabel()
    var pickView = UIView()
    var slideView = UIView()

    // manually build our view re Issue #24
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "OpenAthena Settings"
        view.backgroundColor = .secondarySystemBackground
        //view.overrideUserInterfaceStyle = .light
        
        print("SettingsView: outputMode raw value is \(app.settings.outputMode.rawValue)")
        
        pickerView.dataSource = self
        pickerView.delegate = self
        pickerView.selectRow(app.settings.outputMode.rawValue, inComponent: 0, animated: true)
        pickerView.translatesAutoresizingMaskIntoConstraints = false
        newOutputMode = app.settings.outputMode
        pickerView.layer.borderWidth = 0.15
        pickerView.layer.borderColor = UIColor.lightGray.cgColor
        // pickView is UIView that pickerView is contained in so that we can
        // center and properly size the pickerView within the stackView
        pickView.addSubview(pickerView)
        pickView.translatesAutoresizingMaskIntoConstraints = false
        //pickView.backgroundColor = .blue
        
        // initialize AZ settings slider to current value and
        // set slider parameters; keep consistent with OAAndroid
        newAZCorrection = app.settings.compassCorrection
        newAZSliderValue = app.settings.compassSliderValue
        azOffsetLabel.text = "Manual Azimuth Correction \(newAZCorrection)"
        azOffsetLabel.textAlignment = .center
        //azOffsetValueLabel.text = "\(newAZCorrection)"
        azOffsetSlider.minimumValue = 0.0
        azOffsetSlider.maximumValue = 200.0
        azOffsetSlider.value = newAZSliderValue
        azOffsetSlider.addTarget(self, action: #selector(azCorrectionSliderDidSlide), for: .valueChanged)
        azOffsetSlider.translatesAutoresizingMaskIntoConstraints = false
        slideView.translatesAutoresizingMaskIntoConstraints = false
        //slideView.backgroundColor = .red
        slideView.addSubview(azOffsetSlider)
        
        scrollView.frame = view.bounds
        scrollView.zoomScale = 1.0
        scrollView.maximumZoomScale = 5.0
        scrollView.minimumZoomScale = 1.0
        scrollView.delegate = self
        scrollView.isUserInteractionEnabled = true
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.backgroundColor = .secondarySystemBackground
        
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        saveButton.setTitle("Save Settings", for: .normal)
        saveButton.addTarget(self, action: #selector(didTapSaveButton), for: .touchUpInside)
        saveButton.setTitleColor(.systemBlue, for: .normal)
        
        resetButton.setTitle("Reset AZ Offset", for: .normal)
        resetButton.addTarget(self, action: #selector(didTouchReset), for: .touchUpInside)
        resetButton.setTitleColor(.systemBlue, for: .normal)
        
        stackView.frame = view.bounds
        stackView.axis = .vertical
        stackView.distribution = .fillProportionally
        stackView.spacing = 5
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        outputModeLabel.text = "Ouput Mode \u{1f3af}"
        outputModeLabel.textAlignment = .center
        stackView.addArrangedSubview(outputModeLabel)
        stackView.addArrangedSubview(pickView)
        stackView.addArrangedSubview(azOffsetLabel)
        stackView.addArrangedSubview(resetButton)
        stackView.addArrangedSubview(slideView)
        stackView.addArrangedSubview(saveButton)
        
        contentView.addSubview(stackView)
        scrollView.addSubview(contentView)
        view.addSubview(scrollView)
    
        // set layout constraints
        // tweaks for various pieces for height, widths
        
        outputModeLabel.heightAnchor.constraint(equalToConstant: 0.05*view.frame.size.height).isActive = true
        resetButton.heightAnchor.constraint(equalToConstant: 0.05*view.frame.size.height).isActive = true
        saveButton.heightAnchor.constraint(equalToConstant: 0.20*view.frame.size.height).isActive = true
        azOffsetLabel.heightAnchor.constraint(equalToConstant: 0.05*view.frame.size.height).isActive = true
        pickView.heightAnchor.constraint(equalToConstant: 0.3*view.frame.size.height).isActive = true
        pickView.widthAnchor.constraint(equalToConstant: 200).isActive = true
        pickerView.centerXAnchor.constraint(equalTo: pickView.centerXAnchor).isActive = true
        
        slideView.widthAnchor.constraint(equalToConstant: view.frame.size.width*0.75).isActive = true
        slideView.heightAnchor.constraint(equalToConstant: 0.15*view.frame.size.height).isActive = true
        azOffsetSlider.centerXAnchor.constraint(equalTo: slideView.centerXAnchor).isActive = true
        azOffsetSlider.widthAnchor.constraint(equalToConstant: view.frame.size.width*0.75).isActive = true
        azOffsetSlider.centerYAnchor.constraint(equalTo: slideView.centerYAnchor).isActive = true
        
        saveButton.bottomAnchor.constraint(equalTo: stackView.bottomAnchor).isActive = true
        
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
    
    // from android OpenAthena
    // slider values 0..200 converted to compass offset correction -15,15
    private func calculateAZCorrectionOffset(sliderValue: Float) -> Float
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
        newAZSliderValue = 100.0
        newAZCorrection = 0.0
        azOffsetSlider.value = 100.0
        //azOffsetValueLabel.text = "Manual Azimuth Correction: \(newAZCorrection)"
        azOffsetLabel.text = "Manual Azimuth Correction: \(newAZCorrection)"
    }
    
    // user changed value via slider
    @IBAction func azCorrectionSliderDidSlide(_ sender: UISlider)
    {
        newAZSliderValue = sender.value
        print("azCorrection value set to \(newAZSliderValue),\(newAZCorrection)")
        newAZCorrection = calculateAZCorrectionOffset(sliderValue: newAZSliderValue)
        //correctionTextField.text = "Manual Azimuth Correction: \(newCompassCorrection)"
        //azOffsetValueLabel.text = "\(newAZCorrection)"
        azOffsetLabel.text = "Manual Azimuth Correction: \(newAZCorrection)"
    }
    
    // user changed value via text view
    @IBAction func azCorrectionTextFieldDidChange(textField: UITextField)
    {
        // strip text chars leaving just the numbers
        // if its not a valid number, then don't do anything
        var result = ""
        result = (textField.text?.filter("-0123456789.".contains))!
        if result == "" {
            return
        }
        
        print("New az correction slider value is \(result)")
        newAZSliderValue = Float(result) ?? 0.0
        newAZCorrection = calculateAZCorrectionOffset(sliderValue: newAZSliderValue)
        //correctionTextField.text = "Manual Azimuth Correction: \(newCompassCorrection)"
        // update the slider too
        azOffsetSlider.value = newAZSliderValue
    }
    
    @IBAction func didTapSaveButton()
    {
        print("Saving defaults")
        
        app.settings.outputMode = newOutputMode
        app.settings.compassCorrection = newAZCorrection
        app.settings.compassSliderValue = newAZSliderValue
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

//    override func viewDidLoad() {
//        super.viewDidLoad()
//
//        self.title = "OpenAthena Settings"
//        view.backgroundColor = .secondarySystemBackground
//        //view.overrideUserInterfaceStyle = .light
//
//        print("SettingsView: outputMode raw value is \(app.settings.outputMode.rawValue)")
//
//        pickerView.dataSource = self
//        pickerView.delegate = self
//        pickerView.selectRow(app.settings.outputMode.rawValue, inComponent: 0, animated: true)
//        newOutputMode = app.settings.outputMode
//
//        // initialize compass settings slider to current value and
//        // set slider parameters; keep consistent with OAAndroid
//        newCompassCorrection = app.settings.compassCorrection
//        newCompassSliderValue = app.settings.compassSliderValue
//        compassOffsetLabel.text = "Manual Azimuth Correction"
//        compassOffsetValueLabel.text = "\(newCompassCorrection)"
//        compassOffsetSlider.minimumValue = 0.0
//        compassOffsetSlider.maximumValue = 200.0
//        compassOffsetSlider.value = newCompassSliderValue
//
//        // programmatically set leading offset for the AZ label
//        // compassOffsetValueLabel, resetOffsetButton
//        // 25 is spacing between button/label
//        // Issue #24
//        compassOffsetValueLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: -50.0).isActive = true
//        resetOffsetButton.leadingAnchor.constraint(equalTo: compassOffsetValueLabel.trailingAnchor, constant: 25).isActive = true
//
//    }
