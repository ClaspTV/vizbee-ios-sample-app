//
//  PlayerView.swift
//  VizbeeDemo
//
//  Copyright © Vizbee Inc. All rights reserved.
//

import SwiftUI
import AVKit
import VizbeeKit

struct PlayerView: View {
    @ObservedObject var viewModel: VideoPlayerViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var isLandscape = false
    @State private var isPlaying = false
    @State private var showControls = true
    @State private var progress: Double = 0
    @State private var isFullScreen = false
    @State private var imageLoadTrigger = UUID()

    init(video: Video, allVideos: [Video], initialPosition position: Double = 0.0) {
        self.viewModel = VideoPlayerViewModel(currentVideo: video, allVideos: allVideos)
        self.viewModel.initialPosition = position
    }

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                videoPlayerWithControls(geometry: geometry)

                if !isLandscape && !isFullScreen {
                    videoList
                }
            }
            .edgesIgnoringSafeArea(isLandscape || isFullScreen ? .all : .bottom)
            .navigationBarHidden(true)
            .onAppear {
                updateOrientation()
            }
            .onDisappear {
                viewModel.cleanup()
            }
            .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
                updateOrientation()
            }
            .onReceive(viewModel.$shouldReloadImages) { shouldReload in
                if shouldReload {
                    self.imageLoadTrigger = UUID()
                    DispatchQueue.main.async {
                        self.viewModel.shouldReloadImages = false
                    }
                }
            }
        }
    }

    private func videoPlayerWithControls(geometry: GeometryProxy) -> some View {
        ZStack {
            if let player = viewModel.player {
                CustomVideoPlayer(player: player)
                    .aspectRatio(isLandscape || isFullScreen ? nil : 16/9, contentMode: .fit)
                    .frame(maxWidth: .infinity, maxHeight: isLandscape || isFullScreen ? .infinity : nil)
                    .overlay(
                        Group {
                            if viewModel.isCasting {
                                castingOverlay
                            } else {
                                CustomPlayerControls(
                                    isPlaying: $isPlaying,
                                    showControls: $showControls,
                                    progress: $progress,
                                    initialPosition: $viewModel.initialPosition,
                                    isFullScreen: $isFullScreen,
                                    player: player,
                                    isLandscape: isLandscape,
                                    screenSize: geometry.size
                                )
                            }
                        }
                    )
                    .onTapGesture {
                        withAnimation {
                            showControls.toggle()
                        }
                    }
            } else {
                Color.black
                    .aspectRatio(16/9, contentMode: .fit)
            }
        }
        .id(viewModel.currentVideo.id)
    }

    private var castingOverlay: some View {
        GeometryReader { geometry in
            ZStack {
                
                // black overlay
                Color.gray.opacity(1)
            
                // Background image
                Group {
                    CustomAsyncImage(urlString: self.viewModel.currentVideo.imageURL)
                        .id("\(viewModel.currentVideo.id)-\(imageLoadTrigger)")
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
                .clipped()

                // Semi-transparent black overlay
                Color.black.opacity(0.7)

                // Content
                VStack {
                    // Top bar with CastButton
                    HStack {
                        Spacer()
                        CastButton(tintColor: UIColor.white)
                            .frame(width: 30, height: 30)
                            .padding(8)
                    }

                    Spacer()
                }

                // Centered text
                Text(viewModel.castingMessage)
                    .foregroundColor(.white)
                    .padding()
                    .multilineTextAlignment(.center)
                    .frame(width: geometry.size.width)
                    .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
            }
        }
    }

    private var videoList: some View {
        List(viewModel.allVideos.filter { $0.id != viewModel.currentVideo.id }) { video in
            Button(action: {
                viewModel.playVideo(video)
            }) {
                VideoRow(video: video)
                    .id("\(video.id)-\(imageLoadTrigger)")
            }
        }
        .listStyle(PlainListStyle())
    }

    private func updateOrientation() {
        let orientation = UIDevice.current.orientation
        isLandscape = orientation.isLandscape
        if orientation.isPortrait || orientation == .portraitUpsideDown {
            isLandscape = false
        }
        if isLandscape {
            UIViewController.attemptRotationToDeviceOrientation()
        }
    }
}

// Preview remains the same
struct PlayerView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            PlayerView(video: VideoData.videos[0],
                       allVideos: VideoData.videos)
            .previewDisplayName(Constants.Preview_Title.lightMode)
            
            PlayerView(video: VideoData.videos[0],
                       allVideos: VideoData.videos)
            .preferredColorScheme(.dark)
            .previewDisplayName(Constants.Preview_Title.darkMode)
        }
    }
}
