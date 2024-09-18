import SwiftUI
import AVKit
import Combine
import VizbeeKit

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
         let request = VZBRequest(appVideo: video, guid: video.id, startPosition: UInt(position))
         
         request.didPlay(onTV: { [weak self] screen in
             // Handle TV play if needed
             DispatchQueue.main.async {
                 self?.currentVideo = video
                 self?.initialPosition = 0.0
                 self?.shouldReloadImages = true
             }
         })
         
         request.doPlay(onPhone: { [weak self] status in
             DispatchQueue.main.async {
                 self?.currentVideo = video
                 self?.initialPosition = 0.0
                 self?.shouldReloadImages = true
                 self?.setupPlayer()
             }
         })
         if let vc = UIApplication.shared.windows.first?.rootViewController {
             Vizbee.smartPlay(request, presenting: vc)
         }
     }
    
    private func observeCastNotifications() {
        NotificationCenter.default.publisher(for: Notification.Name(VizbeeWrapper.kVZBCastConnected))
            .sink { [weak self] _ in
                self?.handleCastConnected()
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: Notification.Name(VizbeeWrapper.kVZBCastDisconnected))
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
        let friendlyName = VizbeeWrapper.shared.getConnectedTVInfo().friendlyName
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
