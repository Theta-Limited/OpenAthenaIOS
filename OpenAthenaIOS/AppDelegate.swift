//
//  AppDelegate.swift
//  OpenAthenaIOS
//  https://github.com/rdkgit/OpenAthenaIOS
//  https://openathena.com
//  Created by Bobby Krupczak on 1/27/23.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var settings: AthenaSettings = AthenaSettings()

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


}

