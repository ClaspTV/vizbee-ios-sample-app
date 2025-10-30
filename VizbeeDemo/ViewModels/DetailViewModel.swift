//
//  DetailViewModel.swift
//  VizbeeDemo
//
//  Copyright © Vizbee Inc. All rights reserved.
//

import SwiftUI
import VizbeeKit

class DetailViewModel: ObservableObject {
    @Published var video: Video
    @Published var isPlaying = false
    @Published var descriptionExpanded = false
    
    init(video: Video) {
        self.video = video
    }
    
    func toggleDescription() {
        withAnimation {
            descriptionExpanded.toggle()
        }
    }
    
    func playVideo() {
        initiateSmartPlay(video, nil)
    }
    
    private func initiateSmartPlay(_ video: Video, _ startPosition: Double? = 0.0) {
        
        // NEW: Try AirPlay first via AirPlayManager
        let airPlayRequest = AirPlayRequest(
            videoTitle: video.title ?? "no title",
            streamURL: video.streamURL,
            startPosition: startPosition ?? 0.0,
            onTV: { [weak self] deviceName in
                print("✅ AirPlay: Playing on TV - \(deviceName)")
                // Video is playing on AirPlay device
                // No need to present local player
            },
            onPhone: { [weak self] position in  // Receive position
                print("✅ AirPlay: Playing on Phone at position: \(position)")
                // AirPlay not available, use Vizbee or local player
                DispatchQueue.main.async {
                    self?.presentPlayer(at: position)
                }
            }
        )
        
        AirPlayManager.shared.smartPlay(airPlayRequest)
    }
    
//    private func initiateSmartPlay(_ video: Video, _ startPosition: Double? = 0.0) {
//        let request = VZBRequest(appVideo: video, guid: video.id, startPosition: UInt(startPosition ?? 0))
//        
//        request.didPlay(onTV: { screen in
//            // Handle TV play if needed
//        })
//        
//        request.doPlay(onPhone: { [weak self] status in
//            DispatchQueue.main.async {
//                self?.presentPlayer()
//            }
//        })
//        
//        if let vc = UIApplication.shared.windows.first?.rootViewController {
//            Vizbee.smartPlay(request, presenting: vc)
//        }
//    }
    
    private func presentPlayer(at position: Double = 0) {
        guard let rootViewController = UIApplication.shared.windows.first?.rootViewController else {
            return
        }
        PlayerPresenter.shared.presentPlayer(video: video, atPosition: position, presenting: rootViewController)
    }
}
