//
//  VizbeeAnalyticsHandler.swift
//  This is the template for tracking vizbee analytics
//
import Foundation
import VizbeeKit

class VizbeeAnalyticsHandler: NSObject {

    private var isConnected = false
    
    override init() {
        super.init()
        
        // register to listen for UI cards shown and some of their actions
        addUICardsAndActionsListener()
        
        // register to listen for session state events (connected/disconnected)
        addSessionStateListener()
    }

    deinit {
        
        removeUICardsAndActionsListener()
        removeSessionStateListener()
        removeVideoStatusListener()
    }
    
    
    //----------------------------
    // UI card events
    //----------------------------
    
    /**
      This handler is invoked by the Vizbee SDK when the
      Cast Introduction card is shown.
      - Parameter attrs: A dictionary of flow attributes
    */
    func onCastIntroductionCardShown(attrs: [AnyHashable: Any]) {
        
        // Add your custom analytics handler here
    }
    
    /**
      This handler is invoked by the Vizbee SDK when the
      Smart Install card is shown.
      - Parameter attrs: A dictionary of flow attributes
    */
    func onSmartInstallCardShown(attrs: [AnyHashable: Any]) {
        
        // Add your custom analytics handler here
    }
    
    //----------------------------
    // Screen connection events
    //----------------------------
    
    /**
      This handler is invoked by the Vizbee SDK when the
      mobile app is connecting to a new screen.
    */
    func onConnecting() {
        
        // Add your custom analytics handler here
    }
    
    /**
      This handler is invoked by the Vizbee SDK when the
      mobile app is connected to a new screen.
      - Parameter screen: VZBScreen to which the mobile is connected
    */
    func onConnectedToScreen(screen: VZBScreen?) {
        
        // Add your custom analytics handler here
        
        let screenType: VZBScreenType? = screen?.screenType
        let _ = screenType?.typeName
    }

    /**
     This handler is invoked by the Vizbee SDK when the
     mobile app is disconnected from a screen.
    */
    func onDisconnect() {

        // Add your custom analytics handler here
    }
    
    //----------------------------
    // Video status events
    //----------------------------
    /**
      This handler is invoked by the Vizbee SDK when the
      mobile app casts a new video to the screen.
      - Parameter vzbVideoStatus: VZBVideoStatus
    */
    func onVideoStart(vzbVideoStatus: VZBVideoStatus) {
        
        // Add your custom analytics handler here
    }
    
    /**
      This handler is invoked by the Vizbee SDK when the
        video stopped to play to the screen either by the
        physical remote or from the mobile app.
      - Parameter vzbVideoStatus: VZBVideoStatus
    */
    func onVideoStop(vzbVideoStatus: VZBVideoStatus) {
        
        // Add your custom analytics handler here
    }
}

// ----------------------------
// MARK: - UI Flows & User Actions Management
// ----------------------------

extension VizbeeAnalyticsHandler: VZBAnalyticsDelegate {
    
    //---
    // MARK: - VZBAnalyticsDelegate
    //---
    
    func addUICardsAndActionsListener() {
        let analyticsManager: VZBAnalyticsManager? = Vizbee.getAnalyticsManager()
        analyticsManager?.add(self)
    }
    
    func removeUICardsAndActionsListener() {
        let analyticsManager: VZBAnalyticsManager? = Vizbee.getAnalyticsManager()
        analyticsManager?.remove(self)
    }
    
    func onAnalyticsEvent(_ event: VZBAnalyticsEventType, withAttrs attrs: [AnyHashable: Any]) {

        switch event {
        case .castIntroductionCardShown:
            onCastIntroductionCardShown(attrs: attrs)
        case .smartInstallCardShown:
            onSmartInstallCardShown(attrs: attrs)
        default:
            return
        }
    }
}

// ----------------------------
// MARK: - Session Management
// ----------------------------

extension VizbeeAnalyticsHandler: VZBSessionStateDelegate {
    
    func addSessionStateListener() {
        let sessionManager: VZBSessionManager? = Vizbee.getSessionManager()
        sessionManager?.add(self)
    }
    
    func removeSessionStateListener() {
        let sessionManager: VZBSessionManager? = Vizbee.getSessionManager()
        sessionManager?.remove(self)
    }
    
    //---
    // MARK: - VZBSessionStateDelegate
    //---
    
    func onSessionStateChanged(_ newState: VZBSessionState) {
        switch newState {
        case VZBSessionState.notConnected:
            onDisconnect()
            removeVideoStatusListener()
        case VZBSessionState.connecting:
            onConnecting()
        case VZBSessionState.connected:
            let screen = Vizbee.getSessionManager().getCurrentSession()?.vizbeeScreen
            onConnectedToScreen(screen: screen)
            
            // register to listen for video status event (started/stopped etc.)
            addVideoStatusListener()
        default:
            break
        }
    }
}

// --------------------------------
// MARK: - Video Status Management
// --------------------------------

extension VizbeeAnalyticsHandler: VZBVideoStatusUpdateDelegate {
    
    func addVideoStatusListener() {
        let sessionManager: VZBSessionManager? = Vizbee.getSessionManager()
        sessionManager?.getCurrentSession()?.videoClient.addVideoStatusDelegate(self)
    }

    func removeVideoStatusListener() {
        let sessionManager: VZBSessionManager? = Vizbee.getSessionManager()
        sessionManager?.getCurrentSession()?.videoClient.removeVideoStatusDelegate(self)
    }

    //---
    // MARK: - VZBVideoStatusUpdateDelegate
    //---
    
    func onVideoStatusUpdate(_ videoStatus: VZBVideoStatus?) {
        guard let videoStatus = videoStatus,
              let _ = videoStatus.guid else { return }
        
        switch videoStatus.playerState {
        case .started:
            onVideoStart(vzbVideoStatus: videoStatus)
        case .stopped:
            onVideoStop(vzbVideoStatus: videoStatus)
        default:
            break
        }
    }
}
