//
//  GoogleCastManager.swift
//  VizbeeDemo
//
//  Copyright © Vizbee Inc. All rights reserved.
//

import Foundation
import GoogleCast

class GoogleCastManager: NSObject {

    static let shared = GoogleCastManager()

    static let kCastConnected = "googlecast.cast.connected"
    static let kCastDisconnected = "googlecast.cast.disconnected"

    private(set) var isConnected = false

    var connectedDeviceName: String {
        GCKCastContext.sharedInstance().sessionManager.currentCastSession?.device.friendlyName ?? ""
    }

    func initialize() {
        let criteria = GCKDiscoveryCriteria(applicationID: kGCKDefaultMediaReceiverApplicationID)
        let options = GCKCastOptions(discoveryCriteria: criteria)
        options.startDiscoveryAfterFirstTapOnCastButton = false
        options.physicalVolumeButtonsWillControlDeviceVolume = true
        GCKCastContext.setSharedInstanceWith(options)
        GCKCastContext.sharedInstance().useDefaultExpandedMediaControls = true
        GCKCastContext.sharedInstance().sessionManager.add(self)
    }

    func play(_ video: Video, at position: TimeInterval) -> Bool {
        guard let client = GCKCastContext.sharedInstance().sessionManager.currentCastSession?.remoteMediaClient,
              let url = URL(string: video.streamURL) else {
            return false
        }
        let metadata = GCKMediaMetadata(metadataType: .movie)
        metadata.setString(video.title ?? "", forKey: kGCKMetadataKeyTitle)
        metadata.setString(video.subtitle ?? "", forKey: kGCKMetadataKeySubtitle)
        if let imageURL = video.imageURL.flatMap(URL.init(string:)) {
            metadata.addImage(GCKImage(url: imageURL, width: 480, height: 720))
        }
        let mediaBuilder = GCKMediaInformationBuilder(contentURL: url)
        mediaBuilder.contentID = video.id
        mediaBuilder.streamType = video.isLive ? .live : .buffered
        mediaBuilder.contentType = url.pathExtension == "m3u8" ? "application/x-mpegurl" : "video/mp4"
        mediaBuilder.metadata = metadata
        let requestBuilder = GCKMediaLoadRequestDataBuilder()
        requestBuilder.mediaInformation = mediaBuilder.build()
        requestBuilder.startTime = position
        requestBuilder.autoplay = true
        client.loadMedia(with: requestBuilder.build())
        return true
    }

    func disconnectSession() {
        GCKCastContext.sharedInstance().sessionManager.endSessionAndStopCasting(true)
    }

    private func onConnected() {
        isConnected = true
        NotificationCenter.default.post(name: Notification.Name(GoogleCastManager.kCastConnected), object: nil)
    }

    private func onDisconnected() {
        guard isConnected else { return }
        isConnected = false
        NotificationCenter.default.post(name: Notification.Name(GoogleCastManager.kCastDisconnected), object: nil)
    }
}

extension GoogleCastManager: GCKSessionManagerListener {

    func sessionManager(_ sessionManager: GCKSessionManager, didStart session: GCKCastSession) {
        onConnected()
    }

    func sessionManager(_ sessionManager: GCKSessionManager, didResumeCastSession session: GCKCastSession) {
        onConnected()
    }

    func sessionManager(_ sessionManager: GCKSessionManager, didEnd session: GCKCastSession, withError error: Error?) {
        onDisconnected()
    }

    func sessionManager(_ sessionManager: GCKSessionManager, didFailToStart session: GCKCastSession, withError error: Error) {
        onDisconnected()
    }
}
