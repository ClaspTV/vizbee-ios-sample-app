//
//  AirPlayButton.swift
//  VizbeeDemo
//
//  Created by Radhakrishna Bojja on 30/10/25.
//


import SwiftUI
import AVKit

struct AirPlayButton: UIViewRepresentable {
    let tintColor: UIColor
    
    func makeUIView(context: Context) -> AVRoutePickerView {
        let routePicker = AVRoutePickerView()
        routePicker.tintColor = tintColor
        routePicker.activeTintColor = tintColor
        routePicker.prioritizesVideoDevices = true
        return routePicker
    }
    
    func updateUIView(_ uiView: AVRoutePickerView, context: Context) {
        uiView.tintColor = tintColor
        uiView.activeTintColor = tintColor
    }
}