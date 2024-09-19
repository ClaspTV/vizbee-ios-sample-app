//
//  VizbeeWrapper.swift
//  This is the template file for intializing Vizbee SDK and listening for session changes
//

import Foundation
import VizbeeKit

class VizbeeWrapper: NSObject {
  
    static let shared = VizbeeWrapper()
    var isSDKInitialized: Bool = false
  
    static let kVZBCastConnected = "vizbee.cast.connected"
    static let kVZBCastDisconnected = "vizbee.cast.disconnected"
    
    var isConnected = false
    private var sessionManager: VZBSessionManager?
    private var vizbeeAnalyticsHandler: VizbeeAnalyticsHandler?
    
    // ------------------
    // MARK: - SDK init
    // -----------------
    
    func initVizbeeSDK() {
      
        if (!isSDKInitialized) {
            
            isSDKInitialized = true
            
            /*
             * SDK init
             */
            
            let appAdapter = VizbeeAppAdapter()
            let options = VZBOptions()
            options.uiConfig = VizbeeStyles.lightTheme

            // Update with correct Vizbee assigned VizbeeAppID
            Vizbee.start(withAppID: "vzb*********",
                         appAdapterDelegate: appAdapter,
                         andVizbeeOptions: options)
            
            /*
             * Setup session manager
             */
            
            sessionManager = Vizbee.getSessionManager()
            addSessionStateDelegate(sessionDelegate: self)
            
            /*
             * Init vizbee analytics
             */
            
            vizbeeAnalyticsHandler = VizbeeAnalyticsHandler();
        }
    }
  
    // ------------------
    // MARK: - SignIn
    // ------------------

    func doSignIn() {

        let vizbeeSigninAdapter = VizbeeSigninAdapter()
        guard let sessionManager = sessionManager else { return }
        guard let currentSession = sessionManager.getCurrentSession() else { return }
        vizbeeSigninAdapter.getSigninInfo { authInfo in
            guard let authInfo = authInfo else { return }
            let eventManager = currentSession.eventManager
            eventManager.sendEvent(withName: "tv.vizbee.homesign.signin", andData: ["authInfo": authInfo])
        }
    }
}

// ----------------------------
// MARK: - Session Management
// ----------------------------

extension VizbeeWrapper: VZBSessionStateDelegate {
  
    func addSessionStateDelegate(sessionDelegate: VZBSessionStateDelegate) {
        guard let sessionManager = sessionManager else { return }
        sessionManager.add(sessionDelegate)
    }

    func onSessionStateChanged(_ newState: VZBSessionState) {
        switch newState {
        case VZBSessionState.noDeviceAvailable: fallthrough
        case VZBSessionState.notConnected:
            
            onDisconnected()
            
        case VZBSessionState.connecting:
            
            onDisconnected()

            // analytics handler
            vizbeeAnalyticsHandler?.onConnecting()
            
        case VZBSessionState.connected:
            
            onConnected()
            
        default:
            isConnected = false
        }
    }
  
    func onConnected() {

        isConnected = true
        addVideoStatusListener()

        // post cast connected notification
        NotificationCenter.default.post(name: Notification.Name(VizbeeWrapper.kVZBCastConnected), object: nil)
        
        // analytics handler
        let screen = sessionManager?.getCurrentSession()?.vizbeeScreen
        vizbeeAnalyticsHandler?.onConnectedToScreen(screen: screen)
      
        // signin handler
        doSignIn()
    }
    
    func onDisconnected() {

        if (isConnected) {

            isConnected = false
            removeVideoStatusListener()

            // post cast disconnected notification
            NotificationCenter.default.post(name: Notification.Name(VizbeeWrapper.kVZBCastDisconnected), object: nil)
            
            // analytics handler
            vizbeeAnalyticsHandler?.onDisconnect()
        }
    }
    
    func getConnectedScreen() -> VZBScreen? {
        return sessionManager?.getCurrentSession()?.vizbeeScreen
    }
  
    func disconnectSession() {
        sessionManager?.disconnectSession()
    }
}

// --------------------------------
// MARK: - Video Status Management
// --------------------------------

extension VizbeeWrapper: VZBVideoStatusUpdateDelegate {
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
            vizbeeAnalyticsHandler?.onVideoStart(vzbVideoStatus: videoStatus)
            
        default:
            break
        }
    }
}