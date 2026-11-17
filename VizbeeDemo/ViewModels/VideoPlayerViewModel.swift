import SwiftUI
import AVKit
import Combine

class VideoPlayerViewModel: ObservableObject {
    @Published var currentVideo: Video
     @Published var player: AVPlayer?
     @Published var initialPosition: Double = 0.0
     @Published var shouldReloadImages: Bool = false
     let allVideos: [Video]
     
     private var cancellables = Set<AnyCancellable>()
     
     init(currentVideo: Video, allVideos: [Video]) {
         self.currentVideo = currentVideo
         self.allVideos = allVideos
         setupPlayer()
     }
     
     func playVideo(_ video: Video) {
         currentVideo = video
         initialPosition = 0.0
         shouldReloadImages = true
         setupPlayer()
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
     
    func cleanup() {
        player?.pause()
        player = nil
        cancellables.removeAll()
    }
}
