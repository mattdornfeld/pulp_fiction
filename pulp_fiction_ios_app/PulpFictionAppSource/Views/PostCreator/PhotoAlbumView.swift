//
//  PhotoAlbumView.swift
//  build_app
//
//  Created by Matthew Dornfeld on 11/6/22.
//

import ComposableArchitecture
import Foundation
import PhotosUI
import SwiftUI

/**
 Creates a view for using PHPickerViewController to select images from the device's photo album
 */
struct PhotoAlbumView: UIViewControllerRepresentable {
    typealias UIViewControllerType = PHPickerViewController
    typealias PhotoAlbumImage = NSItemProviderReading
    let viewStore: ViewStore<PostCreatorReducer.State, PostCreatorReducer.Action>

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        var parent: PhotoAlbumView

        init(_ parent: PhotoAlbumView) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)

            guard let provider = results.first?.itemProvider else {
                DispatchQueue.main.async {
                    self.parent.viewStore.send(.pickImageFromLibrary(.failure(PostCreatorReducer.Error.CancelledWithOutPickingImage())))
                }
                return
            }

            if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { photoAlbumImageMaybe, _ in

                    let result: Result<PhotoAlbumImage, PulpFictionRequestError> = photoAlbumImageMaybe
                        .map { photoAlbumImage in .success(photoAlbumImage)
                        } ?? .failure(PostCreatorReducer.Error.CancelledWithOutPickingImage())

                    DispatchQueue.main.async {
                        self.parent.viewStore.send(.pickImageFromLibrary(result))
                    }
                }
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration(photoLibrary: PHPhotoLibrary.shared())
        config.filter = .images

        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_: PHPickerViewController, context _: Context) {}
}
