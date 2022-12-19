//
//  CameraView.swift
//  build_app
//
//  Created by Matthew Dornfeld on 11/6/22.
//

import ComposableArchitecture
import Foundation
import SwiftUI
import UIKit

struct CameraView: UIViewControllerRepresentable {
    typealias UIViewControllerType = UIImagePickerController
    let viewStore: ViewStore<ImageSelectorReducer.State, ImageSelectorReducer.Action>

    func makeCoordinator() -> CameraView.Coordinator {
        return Coordinator(self)
    }

    func makeUIViewController(context: Context) -> UIViewControllerType {
        let viewController = UIViewControllerType()
        viewController.delegate = context.coordinator
        viewController.sourceType = .camera
        return viewController
    }

    func updateUIViewController(_: UIViewControllerType, context _: Context) {}
}

extension CameraView {
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        var parent: CameraView

        init(_ parent: CameraView) {
            self.parent = parent
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            DispatchQueue.main.async {
                self.parent.viewStore.send(.pickImageFromCamera(.failure(ImageSelectorReducer.Error.CancelledWithOutPickingImage())))
            }
            picker.dismiss(animated: true)
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            let pickImageFromCameraResult: Result<UIImage, PulpFictionRequestError> = {
                if let uiImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
                    return .success(uiImage)
                } else {
                    return .failure(ImageSelectorReducer.Error.ErrorPickingImageFromCamera())
                }
            }()

            DispatchQueue.main.async {
                self.parent.viewStore.send(.pickImageFromCamera(pickImageFromCameraResult))
            }
            picker.dismiss(animated: true)
        }
    }
}
