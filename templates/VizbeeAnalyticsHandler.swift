//
//  VizbeeAnalyticsHandler.swift
//  This is the template for tracking vizbee analytics
//

import Foundation
import VizbeeKit

class VizbeeAnalyticsHandler: NSObject {

    override init() {
        super.init()
        Vizbee.getAnalyticsManager().add(self)
    }

    deinit {
        Vizbee.getAnalyticsManager().remove(self)
    }

    //----------------------------
    // UIFlow events
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
}

extension VizbeeAnalyticsHandler: VZBAnalyticsDelegate {
    
    func onAnalyticsEvent(_ event: VZBAnalyticsEventType, withAttrs attrs: [AnyHashable: Any]) {

        switch event {
        case .castIntroductionCardShown:
            onCastIntroductionCardShown(attrs: attrs)
        case .smartInstallCardShown:
            onSmartInstallCardShown(attrs: attrs)
        default:
            // this is return instead of default because we don't
            // want the metrics call to get executed at all
            return
        }
    }
}