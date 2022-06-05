//
//  PostCreatorView.swift
//
//  Generates views for creating posts
//
//  Created by Matthew Dornfeld on 3/26/22.
//

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

enum ErrorPickingImageFromLibrary: Error {
    case cancelledWithOutPickingImage
    case errorPickingImage
}

enum ErrorCreatingPost: Error {
    case imageNotSelected
    case errorSerializingImage
    case errorSavingPostToDatabase
}

struct PostCreatorEnvironment {
    let mainQueue: AnySchedulerOf<DispatchQueue>
    let imagedatabase: ImageDatabase = Constants.imageDatabase

    let processImagePickedFromPhotoAlbum: (Result<ImagePicker.PhotoAlbumImage, ErrorPickingImageFromLibrary>) -> Effect<UIImage, ErrorPickingImageFromLibrary> = { result in
        switch result {
        case let .success(photoAlbumImage):

            if let uiImage = photoAlbumImage as? UIImage {
                return Effect(value: uiImage)
            } else {
                return Effect(error: ErrorPickingImageFromLibrary.errorPickingImage)
            }

        case let .failure(error):
            return Effect(error: error)
        }
    }

    let createPost: (UIImage?) -> Effect<ImageMetadata, ErrorCreatingPost> = { uiImageMaybe in
        guard let uiImage = uiImageMaybe else {
            return Effect(error: ErrorCreatingPost.imageNotSelected)
        }

        if let serializedImage = uiImage.serializeImage() {
            let imageId = Utils.generateRandomInt64()

            let imageMetadata = ImageMetadata.with {
                $0.imageID = imageId
                $0.createdAt = Utils.getCurrentProtobufTimestamp()
            }

            let imageWithMetadata = ImageWithMetadata.with {
                $0.imageMetadata = imageMetadata
                $0.imageAsBase64Png = serializedImage
            }

            do {
                try Constants.imageDatabase.put(imageWithMetadata: imageWithMetadata)
            } catch {
                return Effect(error: ErrorCreatingPost.errorSavingPostToDatabase)
            }

            return Effect(value: imageMetadata)
        } else {
            return Effect(error: ErrorCreatingPost.errorSerializingImage)
        }
    }
}

enum PostCreatorAction {
    case showImagePicker
    case hideImagePicker
    case pickImageFromLibrary(Result<ImagePicker.PhotoAlbumImage, ErrorPickingImageFromLibrary>)
    case pickImageFromLibraryHandleErrors(Result<UIImage, ErrorPickingImageFromLibrary>)
    case unpickImage
    case createPost
    case createPostHandleErrors(Result<ImageMetadata, ErrorCreatingPost>)
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
            case .cancelledWithOutPickingImage:
                break
            case .errorPickingImage:
                logger.error("Error picking image")
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

        case let .createPostHandleErrors(.success(imageMetadata)):
            logger.info("Created post \(imageMetadata.imageID)")
            return .none

        case let .createPostHandleErrors(.failure(error)):
            switch error {
            case .imageNotSelected:
                break
            default:
                logger.error("Error creating post for reason \(error)")
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
                    self.parent.viewStore.send(.pickImageFromLibrary(.failure(ErrorPickingImageFromLibrary.cancelledWithOutPickingImage)))
                }
                return
            }

            if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { photoAlbumImageMaybe, _ in

                    let result: Result<PhotoAlbumImage, ErrorPickingImageFromLibrary> = photoAlbumImageMaybe
                        .map { photoAlbumImage in .success(photoAlbumImage)
                        } ?? .failure(ErrorPickingImageFromLibrary.cancelledWithOutPickingImage)

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

    init() {
        self.init(store: Store(
            initialState: PostCreatorState(),
            reducer: PostCreatorReducer.reducer,
            environment: PostCreatorEnvironment(
                mainQueue: .main
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
