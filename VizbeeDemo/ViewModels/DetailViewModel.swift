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
        let request = VZBRequest(appVideo: video, guid: video.id, startPosition: UInt(startPosition ?? 0))
        
        request.didPlay(onTV: { screen in
            // Handle TV play if needed
        })
        
        request.doPlay(onPhone: { [weak self] status in
            DispatchQueue.main.async {
                self?.presentPlayer()
            }
        })
        
        if let vc = UIApplication.shared.windows.first?.rootViewController {
            Vizbee.smartPlay(request, presenting: vc)
        }
    }
    
    private func presentPlayer() {
        guard let rootViewController = UIApplication.shared.windows.first?.rootViewController else {
            return
        }
        PlayerPresenter.shared.presentPlayer(video: video, atPosition: 0, presenting: rootViewController)
    }
}
