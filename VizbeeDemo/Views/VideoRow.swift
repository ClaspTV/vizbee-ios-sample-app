//
//  VideoRow.swift
//  VizbeeDemo
//
//  Copyright © Vizbee Inc. All rights reserved.
//

import SwiftUI

struct VideoRow: View {
    let video: Video
    
    init(video: Video) {
        self.video = video
    }
    
    var body: some View {
        HStack {
            CustomAsyncImage(urlString:self.video.imageURL)
                .frame(width: 100, height: 150)
                .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(video.title ?? "")
                    .font(.headline)
                Text(video.subtitle ?? "")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Preview
struct VideoRow_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            VideoRow(video: VideoData.videos[0])
                .previewLayout(.sizeThatFits)
                .padding()
                .previewDisplayName(Constants.Preview_Title.lightMode)
            
            VideoRow(video: VideoData.videos[0])
                .previewLayout(.sizeThatFits)
                .padding()
                .preferredColorScheme(.dark)
                .previewDisplayName(Constants.Preview_Title.darkMode)
        }
    }
}
