//
//  AppDelegate.swift
//  VizbeeDemo
//
//  Copyright © Vizbee Inc. All rights reserved.
//

import UIKit
import SwiftUI
import GoogleCast

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        // Initialize Google Cast SDK before the window, which creates the mini controller
        GoogleCastManager.shared.initialize()
        
        let window = UIWindow(frame: UIScreen.main.bounds)
        let castingViewModel = CastingViewModel()
        let homeView = HomeView(castingViewModel: castingViewModel)
        window.rootViewController = CustomHostingController(rootView: homeView)
        self.window = window
        window.makeKeyAndVisible()
        
        return true
    }

}
