//
//  AppDelegate.swift
//  OpenAthenaIOS
//  https://github.com/rdkgit/OpenAthenaIOS
//  https://openathena.com
//  Created by Bobby Krupczak on 1/27/23.
//

import UIKit
import UserNotifications

@main
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    var settings: AthenaSettings = AthenaSettings()
    var uNC = UNUserNotificationCenter.current()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        // load defaults
        settings.loadDefaults()
        
        // load the EGM96Geod here so its only loaded one time due to its size
        // and that it needs to be decompressed
        // XXX TODO
        var aBool = EGM96Geoid.initEGM96Geoid()
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



}

