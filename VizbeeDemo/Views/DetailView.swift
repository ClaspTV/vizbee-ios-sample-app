//
//  DetailView.swift
//  VizbeeDemo
//
//  Copyright © Vizbee Inc. All rights reserved.
//

import SwiftUI
import AVKit

struct DetailView: View {
    @ObservedObject private var viewModel: DetailViewModel
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.horizontalSizeClass) private var sizeClass

    init(video: Video) {
        self.viewModel = DetailViewModel(video: video)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Video poster
                ZStack {
                    Rectangle()
                        .fill(colorScheme == .dark ? Color.black : Color.gray.opacity(0.2))
                        .frame(height: 200)
                    
                    CustomAsyncImage(urlString: self.viewModel.video.imageURL)
                        .frame(maxWidth: .infinity, maxHeight: 200)
                }
                
                VStack(alignment: .leading, spacing: 16) {
                    // Title and subtitle
                    VStack(alignment: .leading, spacing: 4) {
                        Text(viewModel.video.title ?? "")
                            .font(.title)
                            .fontWeight(.bold)
                        Text(viewModel.video.subtitle ?? "")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    // Description
                    VStack(alignment: .leading, spacing: 8) {
                        Text(viewModel.video.longDescription ?? "")
                            .font(.footnote)
                            .lineLimit(isIpad ? nil : (viewModel.descriptionExpanded ? nil : 10))
                        
                        if !isIpad && (viewModel.video.longDescription?.count ?? 0) > 400 {
                            Button(action: viewModel.toggleDescription) {
                                Text(viewModel.descriptionExpanded ? Constants.Labels.showLess : Constants.Labels.showMore)
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    
                    // Play button
                    Button(action: viewModel.playVideo) {
                        Text(Constants.Labels.play)
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(8)
                    }
                }
                .padding(.horizontal)
            }
            .padding(.bottom, 80) // Add padding for cast bar
        }
        .navigationBarTitle(Text(viewModel.video.title ?? ""), displayMode: .inline)
        .navigationBarItems(trailing: CastButton())
    }
    
    private var isIpad: Bool {
        return sizeClass == .regular
    }
}

// MARK: - Preview
struct DetailView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            NavigationView {
                DetailView(video: VideoData.videos[0])
            }
            .previewDisplayName(Constants.Preview_Title.lightMode)
            
            NavigationView {
                DetailView(video: VideoData.videos[0])
            }
            .preferredColorScheme(.dark)
            .previewDisplayName(Constants.Preview_Title.darkMode)
        }
    }
}
