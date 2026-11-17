import SwiftUI
import AVKit
import Combine

class VideoPlayerViewModel: ObservableObject {
    @Published var currentVideo: Video
     @Published var player: AVPlayer?
     @Published var isCasting: Bool = false
     @Published var castingMessage: String = ""
     @Published var initialPosition: Double = 0.0
     @Published var shouldReloadImages: Bool = false
     let allVideos: [Video]
     
     private var cancellables = Set<AnyCancellable>()
     
     init(currentVideo: Video, allVideos: [Video]) {
         self.currentVideo = currentVideo
         self.allVideos = allVideos
         setupPlayer()
         observeCastNotifications()
     }
     
     func playVideo(_ video: Video) {
         initiateSmartPlay(video)
     }
     
     private func setupPlayer() {
         guard let url = URL(string: currentVideo.streamURL) else { return }
         let playerItem = AVPlayerItem(url: url)
         
         if let existingPlayer = player {
             existingPlayer.replaceCurrentItem(with: playerItem)
         } else {
             player = AVPlayer(playerItem: playerItem)
         }
         
         player?.seek(to: CMTime(seconds: initialPosition, preferredTimescale: 1000))
         player?.play()
     }
     
     func updateVideo(_ video: Video, atPosition position: TimeInterval) {
         self.currentVideo = video
         self.initialPosition = position
         self.shouldReloadImages = true
         setupPlayer()
     }
     
     private func initiateSmartPlay(_ video: Video, _ startPosition: Double? = nil) {
         let position = startPosition ?? initialPosition
         let playedOnTV = GoogleCastManager.shared.play(video, at: position)
         currentVideo = video
         initialPosition = 0.0
         shouldReloadImages = true
         if !playedOnTV {
             setupPlayer()
         }
     }
    
    private func observeCastNotifications() {
        NotificationCenter.default.publisher(for: Notification.Name(GoogleCastManager.kCastConnected))
            .sink { [weak self] _ in
                self?.handleCastConnected()
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: Notification.Name(GoogleCastManager.kCastDisconnected))
            .sink { [weak self] _ in
                self?.handleCastDisconnected()
            }
            .store(in: &cancellables)
    }
    
    private func handleCastConnected() {
        isCasting = true
        player?.pause()
        if let currentTime = player?.currentTime().seconds {
            initiateSmartPlay(currentVideo, currentTime)
        }
        let friendlyName = GoogleCastManager.shared.connectedDeviceName
        self.castingMessage = "Casting to \(friendlyName)"
    }
    
    private func handleCastDisconnected() {
        isCasting = false
        castingMessage = ""
    }
    
    func cleanup() {
        player?.pause()
        player = nil
        cancellables.removeAll()
    }
}
