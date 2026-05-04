//
//  CastButton.swift
//  VizbeeDemo
//
//  Copyright © Vizbee Inc. All rights reserved.
//

import SwiftUI
import VizbeeKit

struct CastButton: UIViewRepresentable {
    var tintColor: UIColor?
    
    init(tintColor: UIColor? = nil) {
        self.tintColor = tintColor
    }
    
    func makeUIView(context: Context) -> VZBCastButton {
        let castButton = Vizbee.createCastButton()
        if let tintColor = tintColor {
            castButton.tintColor = tintColor
        }
        
        // Set intrinsic content size
        castButton.setContentHuggingPriority(.required, for: .horizontal)
        castButton.setContentHuggingPriority(.required, for: .vertical)
        castButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        castButton.setContentCompressionResistancePriority(.required, for: .vertical)
             
        return castButton
    }
    
    func updateUIView(_ uiView: VZBCastButton, context: Context) {
        if let tintColor = tintColor {
            uiView.tintColor = tintColor
        }
    }
}
