//
//  PlayerPresenter.swift
//  VizbeeDemo
//
//  Copyright © Vizbee Inc. All rights reserved.
//

import SwiftUI
import UIKit
import VizbeeKit

class PlayerPresenter: ObservableObject {
    static let shared = PlayerPresenter()
    
    private init() {}
    
    func presentPlayer(video: Video, atPosition position: TimeInterval, presenting viewController: UIViewController) {
        
        if let presentedVC = viewController.presentedViewController,
           presentedVC is UIHostingController<PlayerView> {
            
            if let hostingController = presentedVC as? UIHostingController<PlayerView> {
                
                let playerView = hostingController.rootView
                playerView.viewModel.updateVideo(video, atPosition: position)
            }
        } else {
            
            let playerView = PlayerView(video: video, allVideos: VideoData.videos, initialPosition: position)
            let hostingController = UIHostingController(rootView: playerView)
            viewController.present(hostingController, animated: true, completion: nil)
        }
    }
}
