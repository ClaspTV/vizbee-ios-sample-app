//
//  CustomPlayerControls.swift
//  VizbeeDemo
//
//  Copyright © Vizbee Inc. All rights reserved.
//

import SwiftUI
import AVKit
import VizbeeKit
import Combine

struct CustomPlayerControls: View {
    @Binding var isPlaying: Bool
    @Binding var showControls: Bool
    @Binding var progress: Double
    @Binding var initialPosition: Double
    @Binding var isFullScreen: Bool
    let player: AVPlayer
    let isLandscape: Bool
    let screenSize: CGSize
    
    @State private var isSeekingIndex = 0
    @State private var currentTime: Double = 0
    @State private var duration: Double = 0
    @State private var playerItemObserver: AnyCancellable?
    @State private var hideControlsTask: DispatchWorkItem?
    
    let timer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {

                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        toggleControls()
                    }
                
                if showControls {

                    Color.black.opacity(0.5)
                        .edgesIgnoringSafeArea(.all)
                    
                    // Controls
                    VStack {
                        // Top right cast button
                        HStack {
                            Spacer()
                            CastButton(tintColor: .white)
                                .frame(width: 30, height: 30)
                                .padding(.top, 20)
                                .padding(.trailing, 20)
                        }
                        
                        Spacer()
                        
                        // Bottom controls
                        VStack(spacing: 10) {
                            ProgressSlider(progress: $progress, currentTime: currentTime, duration: duration, onSeek: seekTo)
                            
                            HStack {
                                PlayPauseButton(isPlaying: $isPlaying, player: player)
                                Text(timeString(from: currentTime))
                                    .font(.caption)
                                    .foregroundColor(.white)
                                Spacer()
                                Text(timeString(from: duration))
                                    .font(.caption)
                                    .foregroundColor(.white)
                                FullScreenButton(isFullScreen: $isFullScreen)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, isLandscape || isFullScreen ? 40 : 20)
                    }
                    .transition(.opacity)
                }
            }
        }
        .onReceive(player.publisher(for: \.timeControlStatus)) { status in
            isPlaying = status == .playing
        }
        .onReceive(timer) { _ in
            updateProgress()
        }
        .onAppear {
            setupPlayerItemObserver()
            updateDuration()
            scheduleControlsHiding()
        }
        .onDisappear {
            playerItemObserver?.cancel()
            hideControlsTask?.cancel()
        }
    }
    
    private func toggleControls() {
        withAnimation {
            showControls.toggle()
        }
        scheduleControlsHiding()
    }
    
    private func scheduleControlsHiding() {
        hideControlsTask?.cancel()
        
        if showControls {
            hideControlsTask = DispatchWorkItem {
                withAnimation {
                    self.showControls = false
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 5, execute: hideControlsTask!)
        }
    }
    
    private func setupPlayerItemObserver() {
        playerItemObserver?.cancel()
        
        playerItemObserver = player.publisher(for: \.currentItem)
            .compactMap { $0 }
            .flatMap { item in
                item.publisher(for: \.status)
                    .filter { $0 == .readyToPlay }
            }
            .first()
            .sink { _ in
                updateDuration()
                applyInitialPositionIfNeeded()
            }
    }
    
    private func updateProgress() {
        guard let playerItem = player.currentItem,
              playerItem.status == .readyToPlay else { return }
        
        let currentTime = CMTimeGetSeconds(player.currentTime())
        self.currentTime = currentTime
        
        if duration == 0 {
            updateDuration()
        }
        
        if duration > 0 {
            progress = currentTime / duration
        }
    }
    
    private func updateDuration() {
        let playerItem = player.currentItem
        if playerItem?.status == .readyToPlay,
           let duration = playerItem?.asset.duration.seconds,
           duration > 0,
           !duration.isNaN {
            self.duration = duration
        }
    }
    
    private func seekTo(progress: Double, completion: @escaping (Bool) -> Void) {
        guard let duration = player.currentItem?.duration, duration.isValid, !duration.seconds.isNaN else {
            completion(false)
            return
        }
        let targetTime = CMTimeMultiplyByFloat64(duration, multiplier: Float64(progress))
        player.seek(to: targetTime, toleranceBefore: .zero, toleranceAfter: .zero, completionHandler: completion)
    }
    
    private func applyInitialPositionIfNeeded() {
        guard initialPosition > 0, duration > 0 else { return }
        
        let progress = initialPosition / duration
        seekTo(progress: progress) { success in
            if success {
                player.play()
                DispatchQueue.main.async {
                    self.initialPosition = 0  // Reset initialPosition after applying
                }
            }
        }
    }
    
    private func edgeInsets(for geometry: GeometryProxy) -> EdgeInsets {
        let horizontalPadding: CGFloat = 20
        let verticalPadding: CGFloat = 40
        return EdgeInsets(
            top: geometry.safeAreaInsets.top + verticalPadding,
            leading: geometry.safeAreaInsets.leading + horizontalPadding,
            bottom: geometry.safeAreaInsets.bottom + verticalPadding,
            trailing: geometry.safeAreaInsets.trailing + horizontalPadding
        )
    }
    
    private func timeString(from seconds: Double) -> String {
        let totalSeconds = Int(seconds)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

struct ProgressSlider: View {
    @Binding var progress: Double
    let currentTime: Double
    let duration: Double
    let onSeek: (Double, @escaping (Bool) -> Void) -> Void
    
    var body: some View {
        Slider(value: $progress, in: 0...1) { _ in
            onSeek(progress) { _ in }
        }
        .accentColor(.white)
    }
}

struct PlayPauseButton: View {
    @Binding var isPlaying: Bool
    let player: AVPlayer
    
    var body: some View {
        Button(action: {
            if isPlaying {
                player.pause()
            } else {
                player.play()
            }
            isPlaying.toggle()
        }) {
            Image(systemName: isPlaying ? Constants.Images.pause : Constants.Images.play)
                .foregroundColor(.white)
                .font(.system(size: 20))
        }
    }
}

struct FullScreenButton: View {
    @Binding var isFullScreen: Bool
    
    var body: some View {
        Button(action: {
            isFullScreen.toggle()
        }) {
            Image(systemName: isFullScreen ? Constants.Images.fullscreenExpand : Constants.Images.fullscreenCollapse)
                .foregroundColor(.white)
                .font(.system(size: 20))
        }
    }
}
