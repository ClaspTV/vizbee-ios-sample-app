//
//  CastButton.swift
//  VizbeeDemo
//
//  Copyright © Vizbee Inc. All rights reserved.
//

import SwiftUI
import GoogleCast

struct CastButton: UIViewRepresentable {
    var tintColor: UIColor?
    
    init(tintColor: UIColor? = nil) {
        self.tintColor = tintColor
    }
    
    func makeUIView(context: Context) -> GCKUICastButton {
        let castButton = GCKUICastButton(frame: CGRect(x: 0, y: 0, width: 24, height: 24))
        if let tintColor = tintColor {
            castButton.tintColor = tintColor
        }
        return castButton
    }
    
    func updateUIView(_ uiView: GCKUICastButton, context: Context) {
        if let tintColor = tintColor {
            uiView.tintColor = tintColor
        }
    }
}
