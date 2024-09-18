//
//  CastingViewModel.swift
//  VizbeeDemo
//
//  Copyright © Vizbee Inc. All rights reserved.
//

import SwiftUI
import VizbeeKit

class CastingViewModel:  NSObject, ObservableObject {
    @Published var castingState: VZBSessionState = .notConnected
    @Published var castingDevice: String?
    @Published var isConnected: Bool = false
    
    private var sessionManager: VZBSessionManager? { Vizbee.getSessionManager() }
    
    override init() {
        super.init()
        sessionManager?.add(self)
    }
}

// MARK: - Session Management
extension CastingViewModel: VZBSessionStateDelegate {
    func onSessionStateChanged(_ newState: VZBSessionState) {
        DispatchQueue.main.async {
            self.castingState = newState
            
            switch newState {
            case .noDeviceAvailable, .notConnected:
                self.onDisconnected()
            case .connecting:
                self.onDisconnected()
            case .connected:
                self.onConnected()
            @unknown default:
                self.isConnected = false
            }
        }
    }
    
    private func onConnected() {
        isConnected = true
        addVideoStatusListener()
        
        NotificationCenter.default.post(name: Notification.Name("VZBCastConnected"), object: nil)
        
        if let screen = sessionManager?.getCurrentSession()?.vizbeeScreen.screenInfo {
            castingDevice = screen.friendlyName
        }
        
        doSignIn()
    }
    
    private func onDisconnected() {
        if isConnected {
            isConnected = false
            removeVideoStatusListener()
            
            NotificationCenter.default.post(name: Notification.Name("VZBCastDisconnected"), object: nil)
            
            castingDevice = nil
        }
    }
    
    func getConnectedScreen() -> VZBScreen? {
        return sessionManager?.getCurrentSession()?.vizbeeScreen
    }
    
    func disconnectSession() {
        sessionManager?.disconnectSession()
    }
    
    private func doSignIn() {
        // Implement sign-in logic if needed
    }
}

// MARK: - Video Status Management
extension CastingViewModel: VZBVideoStatusUpdateDelegate {
    func addVideoStatusListener() {
        sessionManager?.getCurrentSession()?.videoClient.addVideoStatusDelegate(self)
    }
    
    func removeVideoStatusListener() {
        sessionManager?.getCurrentSession()?.videoClient.removeVideoStatusDelegate(self)
    }
    
    func onVideoStatusUpdate(_ videoStatus: VZBVideoStatus?) {
        guard let videoStatus = videoStatus,
              let _ = videoStatus.guid else { return }
        
        switch videoStatus.playerState {
        case .started:
            break
        default:
            break
        }
    }
}
