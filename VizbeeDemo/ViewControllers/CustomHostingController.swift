//
//  CustomHostingController.swift
//  VizbeeDemo
//
//  Copyright © Vizbee Inc. All rights reserved.
//

import SwiftUI
import GoogleCast

class CustomHostingController<Content: View>: UIHostingController<Content>, GCKUIMiniMediaControlsViewControllerDelegate {
    private var miniMediaControlsViewController: GCKUIMiniMediaControlsViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if miniMediaControlsViewController == nil {
            let controller = GCKCastContext.sharedInstance().createMiniMediaControlsViewController()
            controller.delegate = self
            addChild(controller)
            view.addSubview(controller.view)
            controller.didMove(toParent: self)
            controller.view.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                controller.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                controller.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                controller.view.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
                controller.view.heightAnchor.constraint(equalToConstant: 64)
            ])
            controller.view.isHidden = !controller.active
            miniMediaControlsViewController = controller
        }
    }
    
    func miniMediaControlsViewController(_ miniMediaControlsViewController: GCKUIMiniMediaControlsViewController, shouldAppear: Bool) {
        miniMediaControlsViewController.view.isHidden = !shouldAppear
    }
}
