//
//  PostCreatorView.swift
//
//  Generates views for creating posts
//
//  Created by Matthew Dornfeld on 3/26/22.
//

import Bow
import BowEffects
import ComposableArchitecture
import Logging
import PhotosUI
import SwiftProtobuf
import SwiftUI

struct PostCreatorState: Equatable {
    /**
     Image for the post being created
     */
    var postUIImageMaybe: UIImage?
    /**
     If true swill show the photo album image picker view
     */
    var showingImagePickerView = false
}

enum PostCreatorErrors {
    class ErrorPickingImageFromLibrary: PulpFictionRequestError {}
    class CancelledWithOutPickingImage: ErrorPickingImageFromLibrary {}
    class ErrorPickingImage: ErrorPickingImageFromLibrary {}

    class ErrorCreatingPost: PulpFictionRequestError {}
    class ImageNotSelected: PulpFictionRequestError {}
    class ErrorSerializingImage: PulpFictionRequestError {}
    class ErrorSavingPostToDatabase: PulpFictionRequestError {}
}

typealias Effect = ComposableArchitecture.Effect
typealias Store = ComposableArchitecture.Store

struct PostCreatorEnvironment {
    let mainQueue: AnySchedulerOf<DispatchQueue>
    let postDataCache: PostDataCache

    func processImagePickedFromPhotoAlbum(_ result: Result<ImagePicker.PhotoAlbumImage, PulpFictionRequestError>) -> Effect<UIImage, PulpFictionRequestError> {
        switch result {
        case let .success(photoAlbumImage):

            if let uiImage = photoAlbumImage as? UIImage {
                return Effect(value: uiImage)
            } else {
                return Effect(error: PostCreatorErrors.ErrorPickingImage())
            }

        case let .failure(error):
            return Effect(error: error)
        }
    }

    func createPost(_ uiImageMaybe: UIImage?) -> ComposableArchitecture.Effect<PostMetadata, PulpFictionRequestError> {
        guard let uiImage = uiImageMaybe else {
            return Effect(error: PostCreatorErrors.ImageNotSelected())
        }

        if let serializedImage = uiImage.serializeImage() {
            let createPostRequest = CreatePostRequest
                .createImagePostRequest("", serializedImage)
            let imagePostData = ImagePostData(createPostRequest.createImagePostRequest)

            return postDataCache
                .put(imagePostData)
                .mapError { _ in PostCreatorErrors.ErrorSavingPostToDatabase() }
                .toEffect()
        } else {
            return Effect(error: PostCreatorErrors.ErrorSerializingImage())
        }
    }
}

enum PostCreatorAction {
    case showImagePicker
    case hideImagePicker
    case pickImageFromLibrary(Result<ImagePicker.PhotoAlbumImage, PulpFictionRequestError>)
    case pickImageFromLibraryHandleErrors(Result<UIImage, PulpFictionRequestError>)
    case unpickImage
    case createPost
    case createPostHandleErrors(Result<PostMetadata, PulpFictionRequestError>)
}

struct PostCreatorReducer {
    private static let logger: Logger = .init(label: String(describing: PostCreatorReducer.self))
    static let reducer: Reducer<PostCreatorState, PostCreatorAction, PostCreatorEnvironment> = Reducer<PostCreatorState, PostCreatorAction, PostCreatorEnvironment> {
        state, action, environment in

        switch action {
        case .showImagePicker:
            state.showingImagePickerView = true
            return .none

        case .hideImagePicker:
            state.showingImagePickerView = false
            return .none

        case let .pickImageFromLibrary(uiImageMaybe):
            return environment
                .processImagePickedFromPhotoAlbum(uiImageMaybe)
                .receive(on: environment.mainQueue)
                .catchToEffect(PostCreatorAction.pickImageFromLibraryHandleErrors)

        case let .pickImageFromLibraryHandleErrors(.success(uiImage)):
            state.postUIImageMaybe = uiImage
            return .none

        case let .pickImageFromLibraryHandleErrors(.failure(error)):
            switch error {
            case let error as PostCreatorErrors.CancelledWithOutPickingImage:
                break
            case let error as PostCreatorErrors.ErrorPickingImageFromLibrary:
                logger.error(
                    "Error picking image",
                    metadata: [
                        "cause": "\(error)",
                    ]
                )
            default:
                logger.error(
                    "Unrecgonized error \(error)",
                    metadata: [
                        "cause": "\(error)",
                    ]
                )
            }
            return .none

        case .unpickImage:
            state.postUIImageMaybe = nil
            return .none

        case .createPost:
            return environment
                .createPost(state.postUIImageMaybe)
                .receive(on: environment.mainQueue)
                .catchToEffect(PostCreatorAction.createPostHandleErrors)

        case let .createPostHandleErrors(.success(postMetadata)):
            logger.info(
                "Created post",
                metadata: [
                    "imageId": "\(postMetadata.postId)",
                ]
            )
            return .none

        case let .createPostHandleErrors(.failure(error)):
            switch error {
            case let error as PostCreatorErrors.ImageNotSelected:
                break
            default:
                logger.error(
                    "Error creating post",
                    metadata: [
                        "cause": "\(error)",
                    ]
                )
            }

            return .none
        }
    }
}

/**
 Creates a view for using PHPickerViewController to select images from the device's photo album
 */
struct ImagePicker: UIViewControllerRepresentable {
    typealias UIViewControllerType = PHPickerViewController
    typealias PhotoAlbumImage = NSItemProviderReading
    let viewStore: ViewStore<PostCreatorState, PostCreatorAction>

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        var parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)

            guard let provider = results.first?.itemProvider else {
                DispatchQueue.main.async {
                    self.parent.viewStore.send(.pickImageFromLibrary(.failure(PostCreatorErrors.CancelledWithOutPickingImage())))
                }
                return
            }

            if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { photoAlbumImageMaybe, _ in

                    let result: Result<PhotoAlbumImage, PulpFictionRequestError> = photoAlbumImageMaybe
                        .map { photoAlbumImage in .success(photoAlbumImage)
                        } ?? .failure(PostCreatorErrors.CancelledWithOutPickingImage())

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

struct PostCreatorView: View {
    private let logger: Logger = .init(label: String(describing: PostCreatorView.self))
    private let store: Store<PostCreatorState, PostCreatorAction>

    init(store: Store<PostCreatorState, PostCreatorAction>) {
        self.store = store
    }

    init(_ postDataCache: PostDataCache) {
        self.init(store: Store(
            initialState: PostCreatorState(),
            reducer: PostCreatorReducer.reducer,
            environment: PostCreatorEnvironment(
                mainQueue: .main,
                postDataCache: postDataCache
            )
        ))
    }

    var body: some View {
        WithViewStore(self.store) { viewStore in
            NavigationView {
                VStack {
                    createImageSelectorView(viewStore: viewStore)
                    Button("Create Post") { viewStore.send(.createPost) }
                }
                .padding([.horizontal, .bottom])
                .navigationTitle("Create Post")
                .sheet(isPresented: viewStore.binding(get: { $0.showingImagePickerView }, send: .hideImagePicker)) {
                    ImagePicker(viewStore: viewStore)
                }
            }
        }
    }

    private func createImageSelectorView(viewStore: ViewStore<PostCreatorState, PostCreatorAction>) -> some View {
        ZStack {
            Rectangle()
                .fill(.secondary)

            Text("Tap to select a photo from your photo album")
                .foregroundColor(.white)
                .font(.headline)

            createImageView(viewStore: viewStore)
        }
        .onTapGesture {
            viewStore.send(.showImagePicker)
        }
    }

    func createImageView(viewStore: ViewStore<PostCreatorState, PostCreatorAction>) -> some View {
        return viewStore.binding(
            get: { $0.postUIImageMaybe }, send: .unpickImage
        ).wrappedValue
            .map {
                Image(uiImage: $0)
                    .resizable()
                    .scaledToFit()
            }
    }
}
