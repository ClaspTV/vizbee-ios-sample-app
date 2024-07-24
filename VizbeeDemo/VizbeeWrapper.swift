//
//  VizbeeWrapper.swift
//  This is the template file for intializing Vizbee SDK and listening for session changes
//
import Foundation
import VizbeeKit

// ConnectionState enumeration
enum ConnectionState {
    case connected
    case disconnected
}

class VizbeeWrapper: NSObject {
  
    @objc static let shared = VizbeeWrapper()
    var isSDKInitialized: Bool = false
  
    @objc static let kVZBCastConnected = "vizbee.cast.connected"
    static let kVZBCastDisconnected = "vizbee.cast.disconnected"
    
    var isConnected = false
    var sessionManager: VZBSessionManager?
    private var vizbeeAnalyticsHandler: VizbeeAnalyticsHandler?
    
    @objc var mobileToTVMessager: MobileToTVMessager?
    
    private static let logTag = "VZBApp_VizbeeWrapper"
    
    // ------------------
    // MARK: - SDK init
    // -----------------
    
    @objc func initVizbeeSDK() {
        
        // appId
        let appId =  "vzb7031540890"
        
        // app adapter
        let appAdapter = VizbeeAppAdapter()
        
        // options
        let options = VZBOptions()
        options.useVizbeeUIWindowAtLevel = .normal + 3
        options.uiConfig = DemoAppVizbeeStyle.lightTheme
        options.customMetricsAttributes = ["Key-1_Hel10": "Value-1", "Key-2_!#l0 L": "Value-2", "Key-3": "Value-3"]
        
        // init Vizbee SDK
        initVizbeeSDK(appId: appId, appAdapter: appAdapter, options: options)
        
        // init mobileToTVMessager
        mobileToTVMessager = MobileToTVMessager()
        mobileToTVMessager?.listenForTVConnectionState()
    }
    
    @objc func initVizbeeSDK(appId: String, appAdapter: VizbeeAppAdapter, options: VZBOptions) {
      
        if (!isSDKInitialized) {
            
            isSDKInitialized = true
            
            // initialize vizbee sdk
            Vizbee.start(withAppID: appId,
                         appAdapterDelegate: appAdapter,
                         andVizbeeOptions: options)
            
            // setup session manager
            sessionManager = Vizbee.getSessionManager()
            addSessionStateDelegate(sessionDelegate: self)
            
            // init vizbee analytics
            vizbeeAnalyticsHandler = VizbeeAnalyticsHandler();
        }
    }
    
    func getConnectedTVInfo() -> ConnectedTVInfo {
        
        let vizbeeScreen = VizbeeWrapper.shared.sessionManager?.getCurrentSession()?.vizbeeScreen
        var connectedTVInfo = ConnectedTVInfo()
        connectedTVInfo.id = vizbeeScreen?.screenInfo?.deviceId ?? ""
        connectedTVInfo.friendlyName = vizbeeScreen?.screenInfo?.friendlyName ?? ""
        connectedTVInfo.model = vizbeeScreen?.screenInfo?.model ?? ""
        connectedTVInfo.type = vizbeeScreen?.screenType?.typeName ?? ""
        
        return connectedTVInfo
    }
    
    func send(eventName: String, eventData: Dictionary<String, Any>) {
        
        // send event
        sessionManager?.getCurrentSession().eventManager.sendEvent(
            withName: eventName,
            andData: eventData
        )
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
        
        // listen for video status
        addVideoStatusListener()

        // Broadcast - post cast connected notification
        NotificationCenter.default.post(name: Notification.Name(VizbeeWrapper.kVZBCastConnected), object: nil)
        
        // analytics handler
        let screen = sessionManager?.getCurrentSession()?.vizbeeScreen
        vizbeeAnalyticsHandler?.onConnectedToScreen(screen: screen)
        
        // send(eventName: kVZBEventName, eventData: Dictionary())
    }
    
    func onDisconnected() {

        if (isConnected) {

            isConnected = false
            removeVideoStatusListener()

            // Broadcast - post cast connected notification
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
