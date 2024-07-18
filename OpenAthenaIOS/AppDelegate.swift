// AppDelegate.swift
// OpenAthenaIOS
// https://github.com/rdkgit/OpenAthenaIOS
// https://openathena.com
// Created by Bobby Krupczak on 1/27/23.
// Copyright 2024, Theta Informatics LLC
// AGPLv3
// https://www.gnu.org/licenses/agpl-3.0.txt

import UIKit
import UserNotifications

@main
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate 
{

    var settings: AthenaSettings = AthenaSettings()
    var uNC = UNUserNotificationCenter.current()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        // load defaults
        settings.loadDefaults()
        settings.fontSize = 18
        
        // re issue #54 check if version changed and if so
        // reset some things
        print("App: version in settings is \(settings.OpenAthenaVersion)")
        if ViewController.version != settings.OpenAthenaVersion {
            print("App: going to erase droneParamsURL")
            settings.droneParamsBookmark = Data()
            settings.droneParamsURL = URL(string: "")
        }
        settings.OpenAthenaVersion = ViewController.version
        // save the settings before we proceed?  Dont
        // bother; wait til user updates something
        
        // load the EGM96Geod here so its only loaded one time due to its size
        // and that it needs to be decompressed
        // XXX TODO
        let aBool = EGM96Geoid.initEGM96Geoid()
        if aBool == false {
            print("Failed to properly init EGM96Geoid")
        }        
        
        print("application: outputMode is \(settings.outputMode), \(settings.outputMode.rawValue)")
        
        uNC.delegate = self
        
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
    
    func sendNotification(title titleStr: String, text message: String)
     {
         let content = UNMutableNotificationContent()
         
         content.title = titleStr
         content.body = message
         content.sound = .default
         
         if let url = Bundle.main.url(forResource: "AppIcon", withExtension: "png") {
             if let attachment = try? UNNotificationAttachment(identifier: "AppIcon", url: url, options: nil) {
                 content.attachments = [attachment]
             }
         }
         
         let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.5, repeats: false)
         let request = UNNotificationRequest(identifier: "OpenAthena Notification",
                                             content: content, trigger: trigger)
         
         uNC.add(request, withCompletionHandler: { error in
             if error != nil {
                 print("Notification error: ", error ?? "unknown error")
             }
             else {
                 print("Notification sent")
             }
         })
         
     } // send notification
     
     func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
         completionHandler()
     }
     func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
         completionHandler([.alert,.badge,.sound])
     }
    
    func feetToMeters(feet: Double) -> Double {
        let meters = feet * 0.3048
        return meters
    }
    
    func metersToFeet(meters: Double) -> Double {
        let feet = meters * 3.28084
        return feet
    }
    
    func formatSize(bytes: Int) -> String 
    {
        switch bytes {
        case 0..<1024:
            return "\(bytes) B"
        case 1024..<(1024 * 1024):
            return String(format: "%.2f KB", Double(bytes) / 1024)
        case (1024 * 1024)..<(1024 * 1024 * 1024):
            return String(format: "%.2f MB", Double(bytes) / (1024 * 1024))
        case (1024 * 1024 * 1024)..<(1024 * 1024 * 1024 * 1024):
            return String(format: "%.2f GB", Double(bytes) / (1024 * 1024 * 1024))
        default:
            return String(format: "%.2f GB", Double(bytes) / (1024 * 1024 * 1024 * 1024))
        }
    }
        
}

