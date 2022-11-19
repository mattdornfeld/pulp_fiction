//
//  CameraView.swift
//  build_app
//
//  Created by Matthew Dornfeld on 11/6/22.
//

import Foundation
import SwiftUI
import UIKit

struct CameraView: UIViewControllerRepresentable {
    typealias UIViewControllerType = UIImagePickerController

    func makeUIViewController(context: Context) -> UIViewControllerType {
        let viewController = UIViewControllerType()
        viewController.delegate = context.coordinator
        viewController.sourceType = .photoLibrary
        return viewController
    }

    func updateUIViewController(_: UIViewControllerType, context _: Context) {}

    func makeCoordinator() -> CameraView.Coordinator {
        return Coordinator(self)
    }
}

extension CameraView {
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        var parent: CameraView

        init(_ parent: CameraView) {
            self.parent = parent
        }

        func imagePickerControllerDidCancel(_: UIImagePickerController) {
            print("Cancel pressed")
        }

        func imagePickerController(_: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
                UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
            }
        }
    }
}
