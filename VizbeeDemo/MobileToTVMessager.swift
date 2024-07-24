//
//  MobileToTVMessager.swift
//  VizbeeDemo
//

import UIKit

import VizbeeKit

// MobileToTVMessager class responsible for managing
// communication between mobile and TV using VizbeeWrapper.

class MobileToTVMessager: NSObject {
    
    @objc let kEventName = "com.vizbee.axionista"
        
    // used send the message from mobile to the TV
    var productId = 0
    
    @objc func listenForTVConnectionState() {
        print("Vizbee::MobileToTVMessager: listenForTVConnectionState - listen for connection and messages")
        
        // start listening for connection state changes
        NotificationCenter.default.addObserver(self, selector: #selector(handleOnConnection(_:)), name: NSNotification.Name(VizbeeWrapper.kVZBCastConnected), object: nil)

    }
    
    /// register a listener to receive connection state updates
    @objc func handleOnConnection(_ notification: NSNotification) {
        print("Vizbee::MobileToTVMessager: listenForConnectionState - Mobile is now connected to the TV.")
        
        // setup event manager
        self.addEventHandler(eventHandler: self)
    }
    
    /// check if mobile is currently connected to TV
    @objc func isConnectedToTV() -> Bool {
        return VizbeeWrapper.shared.isConnected;
    }
    
    /// retrieve information about the connected TV
    func getConnectedTVInfo() -> ConnectedTVInfo {
        return VizbeeWrapper.shared.getConnectedTVInfo()
    }

    // Event related
        
    // Define a typealias for the closure signature
    typealias MessageListener = (ConnectedTVInfo, String, [AnyHashable: Any]) -> Void
    
    // Closure property to store the listener
    var messageListener: MessageListener?
    
    // Function to register the listener
    func setMessageListener(listener: @escaping MessageListener) {
        self.messageListener = listener
    }
    
    /// send an event with associated data to the connected TV
    @objc func send(eventName: String, data: Dictionary<String, Any>) {
        
        print("Vizbee::MobileToTVMessager: send - Sending event '\(eventName)' with data: \(data)")
        VizbeeWrapper.shared.send(eventName: eventName, eventData: data)
    }
    
    @objc func getMessage() -> [String: Any] {
        
        // increment productId for each message (for testing)
        productId += 1
        
        let message: [String: Any] = [
            "message": [
                "productId": productId
            ]
        ]
        
        return message
    }
}

// ----------------------------
// MARK: - Event Management
// ----------------------------
extension MobileToTVMessager: VZBEventHandler {
  
    func addEventHandler(eventHandler: VZBEventHandler) {
        let sessionManager = VizbeeWrapper.shared.sessionManager
        let eventManager = sessionManager?.getCurrentSession()?.eventManager
        guard let eventManager = eventManager else { return }
        eventManager.register(forEvent: kEventName, eventHandler: eventHandler)
    }

    func onEvent(_ event: VZBEvent) {
        
        // call the listener closure if it's set
        let connectedTVInfo = VizbeeWrapper.shared.getConnectedTVInfo()
        messageListener?(connectedTVInfo, event.name, event.data)
    }
}

struct ConnectedTVInfo {
    var id = ""             // identifier of the TV
    var type = ""           // type of the TV (e.g., roku, firetv, etc.)
    var friendlyName = ""   // friendly name of the TV
    var model = ""          // Model of the TV
}
