//
//  AppDelegate.swift
//  VizbeeDemo
//
//  Copyright © Vizbee Inc. All rights reserved.
//

import UIKit
import SwiftUI

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        let window = UIWindow(frame: UIScreen.main.bounds)
        let homeView = HomeView()
        window.rootViewController = CustomHostingController(rootView: homeView)
        self.window = window
        window.makeKeyAndVisible()
        
        return true
    }

}
