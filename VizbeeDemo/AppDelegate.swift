//
//  AppDelegate.swift
//  VizbeeDemo
//
//  Copyright © Vizbee Inc. All rights reserved.
//

import UIKit
import SwiftUI
import VizbeeKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        let window = UIWindow(frame: UIScreen.main.bounds)
        let castingViewModel = CastingViewModel()
        let homeView = HomeView(castingViewModel: castingViewModel)
        window.rootViewController = CustomHostingController(rootView: homeView)
        self.window = window
        window.makeKeyAndVisible()
        
        // Initialize Vizbee SDK
        VizbeeWrapper.shared.initVizbeeSDK()
        
        // start listening for connection state changes
        NotificationCenter.default.addObserver(self, selector: #selector(handleOnConnection(_:)), name: NSNotification.Name(VizbeeWrapper.kVZBCastConnected), object: nil)
        
        // listen for message
        listenForMessages()
        
        return true
    }
    
    /// handle tv connection state
    @objc func handleOnConnection(_ noitification: NSNotification) {
        
        print("Vizbee::AppDelegate: handleOnConnection - Mobile is now connected to the TV.")
        
        // send initial message on connection if needed
        let mobileToTVMessager = VizbeeWrapper.shared.mobileToTVMessager
        if let eventName = mobileToTVMessager?.kEventName, let message = mobileToTVMessager?.getMessage() {
            mobileToTVMessager?.send(eventName:eventName, data: message)
        }
    }
    
    /// Handle received messages from the connected TV
    func listenForMessages() {
        
        // Set up message listener
        let mobileToTVMessager = VizbeeWrapper.shared.mobileToTVMessager
        mobileToTVMessager?.setMessageListener { connectedTVInfo, messageName, message in
            // Message received from TV
            print("Vizbee::AppDelegate: listenForMessages - Received message from TV \(connectedTVInfo.friendlyName) MessageName: '\(messageName)', Message: \(message)")
            
            // Add your custom handling logic here
        }
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        if let userInterfaceStyle = UIApplication.shared.windows.first?.traitCollection.userInterfaceStyle{
            Vizbee.setUIConfig(DemoAppVizbeeStyle.getUIStyle(style: userInterfaceStyle))
        }
    }

}
