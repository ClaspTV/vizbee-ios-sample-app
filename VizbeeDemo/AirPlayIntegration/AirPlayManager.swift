//
//  AirPlayManager.swift
//  VizbeeDemo
//
//  Created by Radhakrishna Bojja on 30/10/25.
//


import Foundation
import AVFoundation
import Combine

class AirPlayManager: ObservableObject {
    static let shared = AirPlayManager()
    
    @Published var isAirPlayRouteActive: Bool = false
    @Published var airPlayDeviceName: String?
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        setupRouteMonitoring()
        checkInitialRoute()
    }
    
    private func setupRouteMonitoring() {
        NotificationCenter.default.publisher(for: AVAudioSession.routeChangeNotification)
            .sink { [weak self] notification in
                self?.handleRouteChange(notification)
            }
            .store(in: &cancellables)
    }
    
    private func checkInitialRoute() {
        updateAirPlayState()
    }
    
    private func handleRouteChange(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else {
            return
        }
        
        print("=== AirPlay Route Change ===")
        print("Reason: \(routeChangeReasonString(reason))")
        
        updateAirPlayState()
        
        print("============================")
    }
    
    private func updateAirPlayState() {
        let audioSession = AVAudioSession.sharedInstance()
        let currentRoute = audioSession.currentRoute
        
        let airPlayOutput = currentRoute.outputs.first { $0.portType == .airPlay }
        
        isAirPlayRouteActive = airPlayOutput != nil
        airPlayDeviceName = airPlayOutput?.portName
        
        print("AirPlay Active: \(isAirPlayRouteActive)")
        if let name = airPlayDeviceName {
            print("Device: \(name)")
        }
    }
    
    private func routeChangeReasonString(_ reason: AVAudioSession.RouteChangeReason) -> String {
        switch reason {
        case .unknown: return "Unknown"
        case .newDeviceAvailable: return "New Device Available"
        case .oldDeviceUnavailable: return "Old Device Unavailable"
        case .categoryChange: return "Category Change"
        case .override: return "Override"
        case .wakeFromSleep: return "Wake From Sleep"
        case .noSuitableRouteForCategory: return "No Suitable Route"
        case .routeConfigurationChange: return "Route Configuration Change"
        @unknown default: return "Unknown (\(reason.rawValue))"
        }
    }
}