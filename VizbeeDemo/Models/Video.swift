//
//  Video.swift
//  VizbeeDemo
//
//  Copyright © Vizbee Inc. All rights reserved.
//

import SwiftUI


struct Video: Identifiable, Hashable {
    let id: String
    let title: String?
    let subtitle: String?
    let streamURL: String
    let isLive: Bool
    let imageURL: String?
    let longDescription: String?
    let captionsURL: String?
    let adBreaks: [Any]?
    
    init(id: String,
         title: String? = "",
         subtitle: String? = "",
         streamURL: String,
         isLive: Bool = false,
         imageURL: String? = nil,
         longDescription: String? = "",
         captionsURL: String? = nil,
         adBreaks: [Any]? = [])
    {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.streamURL = streamURL
        self.isLive = isLive
        self.imageURL = imageURL
        self.longDescription = longDescription
        self.captionsURL = captionsURL
        self.adBreaks = adBreaks
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Video, rhs: Video) -> Bool {
        lhs.id == rhs.id
    }
}
