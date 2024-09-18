//
//  CustomHostingController.swift
//  VizbeeDemo
//
//  Copyright © Vizbee Inc. All rights reserved.
//

import SwiftUI
import VizbeeKit

class CustomHostingController<Content: View>: UIHostingController<Content>{
    private var castBarController: VZBCastBarViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if castBarController == nil {
            castBarController = Vizbee.createCastBarController()
            if let castBarView = castBarController?.view {
                view.addSubview(castBarView)
                castBarView.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    castBarView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                    castBarView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                    castBarView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
                    castBarView.heightAnchor.constraint(equalToConstant: 64)
                ])
            }
        }
    }
}
