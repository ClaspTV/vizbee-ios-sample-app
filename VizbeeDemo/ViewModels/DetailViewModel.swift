//
//  DetailViewModel.swift
//  VizbeeDemo
//
//  Copyright © Vizbee Inc. All rights reserved.
//

import SwiftUI

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
        if !GoogleCastManager.shared.play(video, at: startPosition ?? 0) {
            presentPlayer()
        }
    }
    
    private func presentPlayer() {
        guard let rootViewController = UIApplication.shared.windows.first?.rootViewController else {
            return
        }
        PlayerPresenter.shared.presentPlayer(video: video, atPosition: 0, presenting: rootViewController)
    }
}
