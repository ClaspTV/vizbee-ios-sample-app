import Foundation
import AVFoundation
import Combine

class AirPlayManager: ObservableObject {
    static let shared = AirPlayManager()
    
    @Published var isAirPlayRouteActive: Bool = false
    @Published var airPlayDeviceName: String?
    
    private var cancellables = Set<AnyCancellable>()
    private var internalPlayer: AVPlayer?
    private var pendingRequest: AirPlayRequest?
    
    // Notification names for AirPlay state changes
    static let airPlayConnectedNotification = Notification.Name("AirPlayManagerConnected")
    static let airPlayDisconnectedNotification = Notification.Name("AirPlayManagerDisconnected")
    static let airPlayPlaybackStartedNotification = Notification.Name("AirPlayManagerPlaybackStarted")
    
    private init() {
        setupRouteMonitoring()
        checkInitialRoute()
    }
    
    // MARK: - Smart Play (Vizbee-like API)
    
    func smartPlay(_ request: AirPlayRequest) {
        print("=== AirPlayManager: smartPlay called ===")
        print("Video: \(request.videoTitle)")
        print("URL: \(request.streamURL)")
        print("isAirPlayRouteActive: \(isAirPlayRouteActive)")
        
        self.pendingRequest = request
        
        if isAirPlayRouteActive {
            // AirPlay already connected - play on TV
            playOnAirPlay(request)
        } else {
            // No AirPlay connection - play on phone
            request.onPhone?(0)
        }
    }
    
    private func playOnAirPlay(_ request: AirPlayRequest) {
        print("=== AirPlayManager: Playing on AirPlay ===")
        
        guard let url = URL(string: request.streamURL) else {
            print("Invalid stream URL")
            request.onPhone?(0)
            return
        }
        
        // Create internal player for AirPlay
        let playerItem = AVPlayerItem(url: url)
        
        if let existingPlayer = internalPlayer {
            existingPlayer.replaceCurrentItem(with: playerItem)
        } else {
            internalPlayer = AVPlayer(playerItem: playerItem)
        }
        
        // Enable AirPlay
        internalPlayer?.allowsExternalPlayback = true
        internalPlayer?.usesExternalPlaybackWhileExternalScreenIsActive = true
        
        // Seek to start position if needed
        if request.startPosition > 0 {
            internalPlayer?.seek(to: CMTime(seconds: request.startPosition, preferredTimescale: 1000))
        }
        
        // Start playback
        internalPlayer?.play()
        
        // Notify that playback started on TV
        request.onTV?(airPlayDeviceName ?? "AirPlay Device")
        
        // Post notification for UI updates
        NotificationCenter.default.post(name: Self.airPlayPlaybackStartedNotification, object: nil)
        
        print("AirPlay playback initiated")
    }
    
    private func stopAirPlayPlayback() {
        print("=== AirPlayManager: Stopping AirPlay playback ===")
        
        // Get current playback position before stopping
        let currentPosition = internalPlayer?.currentTime().seconds ?? 0
        print("Current playback position: \(currentPosition) seconds")
        
        internalPlayer?.pause()
        internalPlayer?.replaceCurrentItem(with: nil)
        internalPlayer = nil
        
        // Pass position to onPhone callback
        pendingRequest?.onPhone?(currentPosition)
        pendingRequest = nil
    }
    
    // MARK: - Route Monitoring
    
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
        
        let wasActive = isAirPlayRouteActive
        updateAirPlayState()
        
        // Handle connection state changes
        if !wasActive && isAirPlayRouteActive {
            handleAirPlayConnected()
        } else if wasActive && !isAirPlayRouteActive {
            handleAirPlayDisconnected()
        }
        
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
    
    private func handleAirPlayConnected() {
        print("=== AirPlayManager: AirPlay Connected ===")
        
        // Post notification
        NotificationCenter.default.post(name: Self.airPlayConnectedNotification, object: nil)
        
        // If we have a pending request, play it now
        if let request = pendingRequest {
            playOnAirPlay(request)
        }
    }
    
    private func handleAirPlayDisconnected() {
        print("=== AirPlayManager: AirPlay Disconnected ===")
        
        // Stop playback and cleanup
        stopAirPlayPlayback()
        
        // Post notification
        NotificationCenter.default.post(name: Self.airPlayDisconnectedNotification, object: nil)
    }
    
    // MARK: - Helpers
    
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

// MARK: - Request Model

struct AirPlayRequest {
    let videoTitle: String
    let streamURL: String
    let startPosition: Double
    let onTV: ((String) -> Void)?
    let onPhone: ((Double) -> Void)?
    
    init(videoTitle: String, streamURL: String, startPosition: Double = 0, onTV: ((String) -> Void)? = nil, onPhone: ((Double) -> Void)? = nil) {
        self.videoTitle = videoTitle
        self.streamURL = streamURL
        self.startPosition = startPosition
        self.onTV = onTV
        self.onPhone = onPhone
    }
}
