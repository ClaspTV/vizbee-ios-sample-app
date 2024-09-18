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
        return castButton
    }
    
    func updateUIView(_ uiView: VZBCastButton, context: Context) {
        if let tintColor = tintColor {
            uiView.tintColor = tintColor
        }
    }
}
