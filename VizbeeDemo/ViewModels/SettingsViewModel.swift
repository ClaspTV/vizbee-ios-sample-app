//
//  SettingsViewModel.swift
//  VizbeeDemo
//
//  Copyright © Vizbee Inc. All rights reserved.
//

import SwiftUI
import VizbeeKit

class SettingsViewModel: ObservableObject {
    @Published var showAlert = false
    @Published var alertMessage = ""
    
    private let vizbeeWrapper = VizbeeWrapper.shared
    private var defaults: UserDefaults { UserDefaults.standard }

    func triggerSmartHelp(for flow: SmartHelpFlow) {
        print("Triggering smart help for \(flow)")
        switch flow {
        case .castIntroduction:
            defaults.removeObject(forKey: "vzb_any_card")
        case .smartInstall:
            let date = Calendar.current.date(byAdding: .day, value: -31, to: Date()) ?? Date()
            defaults.set(date, forKey: "vzb_any_card")
            defaults.set(date, forKey: "vzb_smart_install_card")
            defaults.synchronize()
        }
        
        
        if let viewController = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.windows.first?.rootViewController{
            Vizbee.smartHelp(viewController)
        }
    }
    
    func sendMessageToTV() {
        if let mobileToTVMessager = vizbeeWrapper.mobileToTVMessager , mobileToTVMessager.isConnectedToTV() == true{
            mobileToTVMessager.send(eventName: mobileToTVMessager.kEventName,
                                                  data: mobileToTVMessager.getMessage())
            alertMessage = "Message sent to TV"
        } else {
            alertMessage = "Not connected to the TV to send the message"
        }
        showAlert = true
    }
}

// MARK: - Helper Enums

enum SmartHelpFlow {
    case castIntroduction
    case smartInstall
}
