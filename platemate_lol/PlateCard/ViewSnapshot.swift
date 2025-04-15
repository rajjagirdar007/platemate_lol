//
//  ViewSnapshot.swift
//  platemate_lol
//
//  Created by Raj Jagirdar on 4/14/25.
//


import SwiftUI
import UIKit

struct ViewSnapshot {
    static func capture<Content: View>(of view: Content) -> UIImage? {
        let controller = UIHostingController(rootView: view)
        let view = controller.view
        
        let targetSize = controller.view.intrinsicContentSize
        view?.bounds = CGRect(origin: .zero, size: targetSize)
        view?.backgroundColor = .clear
        
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { _ in
            view?.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
        }
    }
}