//
//  ImageSelectorView.swift
//  build_app_source
//
//  Created by Matthew Dornfeld on 11/18/22.
//

import Foundation
import SwiftUI

import ComposableArchitecture
import Foundation
import Logging
import SwiftUI

/// Enum for the image options when creating an image post
enum ImageSourceType: String, DropDownMenuOption {
    /// Image source is the camera
    case Camera
    /// Imafe source is the photo album
    case Album

    var prompt: String {
        switch self {
        case .Camera:
            return "Tap to select a photo from your camera"
        case .Album:
            return "Tap to select a photo from your photo album"
        }
    }

    @ViewBuilder
    func getImageSourceView(viewStore: PulpFictionViewStore<ImageSelectorReducer>) -> some View {
        switch self {
        case .Camera:
            CameraView(viewStore: viewStore)
        case .Album:
            PhotoAlbumView(viewStore: viewStore)
        }
    }
}

/// Reducer for the PostCreatorView
struct ImageSelectorReducer: ReducerProtocol {
    private let logger: Logger = .init(label: String(describing: ImageSelectorReducer.self))

    struct State: Equatable {
        /**
         Image for the post being created
         */
        var postUIImageMaybe: UIImage?
        /**
         If true swill show the photo album image picker view
         */
        var showImagePicker: Bool = false
    }

    enum Action {
        /// Set to true to show the image picker
        case updateShowImagePicker(Bool)
        /// Action that's executed when an image is picked from the library
        case pickImageFromLibrary(Result<PhotoAlbumView.PhotoAlbumImage, PulpFictionRequestError>)
        /// Action that's executed when an image is picked from the camera
        case pickImageFromCamera(Result<UIImage, PulpFictionRequestError>)
        /// Logs an error along with its cause
        case logError(PulpFictionRequestError)
        /// Action that's executed to unselect an image
        case unpickImage
    }

    enum Error {
        class ErrorPickingImageFromLibrary: PulpFictionRequestError {}
        class CancelledWithOutPickingImage: ErrorPickingImageFromLibrary {}
        class ErrorConvertingPhotoAlbumImageToUIImage: ErrorPickingImageFromLibrary {}

        class ErrorPickingImageFromCamera: PulpFictionRequestError {}

        class ErrorCreatingPost: PulpFictionRequestError {}
        class ImageNotSelected: PulpFictionRequestError {}
        class ErrorSavingPostToDatabase: PulpFictionRequestError {}
    }

    func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
        switch action {
        case let .updateShowImagePicker(newShowImagePicker):
            state.showImagePicker = newShowImagePicker
            return .none

        case let .pickImageFromLibrary(.success(photoAlbumImageMaybe)):
            if let uiImage = photoAlbumImageMaybe as? UIImage {
                state.postUIImageMaybe = uiImage
            } else {
                return .task { .pickImageFromLibrary(.failure(Error.ErrorConvertingPhotoAlbumImageToUIImage())) }
            }

            return .none

        case .pickImageFromLibrary(.failure(_ as Error.CancelledWithOutPickingImage)):
            return .none

        case let .pickImageFromLibrary(.failure(error)):
            return .task { .logError(error) }

        case let .pickImageFromCamera(.success(uiImage)):
            state.postUIImageMaybe = uiImage
            return .none

        case .pickImageFromCamera(.failure(_ as Error.CancelledWithOutPickingImage)):
            return .none

        case let .pickImageFromCamera(.failure(error)):
            return .task { .logError(error) }

        case let .logError(error):
            logger.error(
                "Error picking image",
                metadata: [
                    "cause": "\(error)",
                ]
            )
            return .none

        case .unpickImage:
            state.postUIImageMaybe = nil
            return .none
        }
    }
}

/// View for selecting images
struct ImageSelectorView<TopNavigationBar: ToolbarContent>: View {
    let topNavigationBarSupplier: (ViewStore<ImageSelectorReducer.State, ImageSelectorReducer.Action>) -> TopNavigationBar
    let imageSourceType: ImageSourceType
    private let store: ComposableArchitecture.StoreOf<ImageSelectorReducer> = Store(
        initialState: ImageSelectorReducer.State(),
        reducer: ImageSelectorReducer()
    )
    var body: some View {
        WithViewStore(store) { viewStore in
            ZStack {
                Rectangle()
                    .fill(.white)

                VStack {
                    BoldCaption(
                        text: imageSourceType.prompt,
                        color: .gray
                    )
                    Symbol(
                        symbolName: "photo.stack",
                        size: 40,
                        color: .gray
                    ).padding(.top, 5)
                }

                viewStore.binding(
                    get: { $0.postUIImageMaybe },
                    send: .unpickImage
                )
                .wrappedValue
                .map {
                    Image(uiImage: $0)
                        .resizable()
                        .scaledToFit()
                }
            }
            .onTapGesture {
                viewStore.send(.updateShowImagePicker(true))
            }
            .sheet(isPresented: viewStore.binding(
                get: \.showImagePicker,
                send: .updateShowImagePicker(false)
            )) { imageSourceType.getImageSourceView(viewStore: viewStore) }
            .padding([.horizontal, .bottom])
            .toolbar { topNavigationBarSupplier(viewStore) }
        }
    }
}
