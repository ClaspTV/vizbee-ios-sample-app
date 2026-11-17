//
//  CastingViewModel.swift
//  VizbeeDemo
//
//  Copyright © Vizbee Inc. All rights reserved.
//

import SwiftUI
import GoogleCast

class CastingViewModel:  NSObject, ObservableObject {
    @Published var castingDevice: String?
    @Published var isConnected: Bool = false
    
    override init() {
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(onConnected), name: Notification.Name(GoogleCastManager.kCastConnected), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onDisconnected), name: Notification.Name(GoogleCastManager.kCastDisconnected), object: nil)
    }
    
    @objc private func onConnected() {
        DispatchQueue.main.async {
            self.isConnected = true
            self.castingDevice = GoogleCastManager.shared.connectedDeviceName
        }
    }
    
    @objc private func onDisconnected() {
        DispatchQueue.main.async {
            self.isConnected = false
            self.castingDevice = nil
        }
    }
    
    func disconnectSession() {
        GoogleCastManager.shared.disconnectSession()
    }
}
