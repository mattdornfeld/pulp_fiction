//
// Created by Matthew Dornfeld on 4/3/22.
//

import Bow
import BowOptics
import ComposableArchitecture
import Logging
import SwiftUI

private struct ImagePostViewState: Equatable {
    var shouldLoadCommentsPage: Bool = false
}

private struct ImagePostViewEnvironment {
    let mainQueue: AnySchedulerOf<DispatchQueue>
}

private enum ImagePostViewAction {
    case loadCommentsPage
    case unloadCommentsPage
}

private enum ImagePostViewReducer {
    static let reducer = Reducer<ImagePostViewState, ImagePostViewAction, ImagePostViewEnvironment> {
        state, action, _ in
        switch action {
        case .loadCommentsPage:
            state.shouldLoadCommentsPage = true
            return .none
        case .unloadCommentsPage:
            state.shouldLoadCommentsPage = false
            return .none
        }
    }
}

/// Renders an image post
public struct ImagePostView: PostView, AutoSetter {
    private let postFeedMessenger: PostFeedMessenger
    private let postUIImage: UIImage
    private let userAvatarUIImage: UIImage
    public let creatorUserPostData: UserPostData
    public let id: Int
    public let imagePostData: ImagePostData
    private var isForCommentsScrollView: Bool = false
    private let store: Store<ImagePostViewState, ImagePostViewAction> = Store(
        initialState: ImagePostViewState(),
        reducer: ImagePostViewReducer.reducer,
        environment: ImagePostViewEnvironment(mainQueue: .main)
    )
    private static let logger = Logger(label: String(describing: ImagePostView.self))

    public static func == (lhs: ImagePostView, rhs: ImagePostView) -> Bool {
        lhs.postUIImage == rhs.postUIImage
            && lhs.userAvatarUIImage == rhs.userAvatarUIImage
            && lhs.creatorUserPostData == rhs.creatorUserPostData
            && lhs.id == rhs.id
            && lhs.imagePostData == rhs.imagePostData
    }

    private func buildCommentsIcon(_: ViewStore<ImagePostViewState, ImagePostViewAction>) -> some View {
        SymbolWithCaption(
            symbolName: "text.bubble",
            symbolCaption: imagePostData
                .postInteractionAggregates
                .numChildComments
                .formatAsStringForView()
        )
    }

    private func buildCommentsIconWithNavigation(_ viewStore: ViewStore<ImagePostViewState, ImagePostViewAction>) -> some View {
        return buildCommentsIcon(viewStore).navigateOnTap(
            isActive: viewStore.binding(
                get: \.shouldLoadCommentsPage,
                send: ImagePostViewAction.unloadCommentsPage
            ),
            destination: CommentScrollView(
                imagePostView: ImagePostView
                    .setter(for: \.isForCommentsScrollView)
                    .set(self, true),
                postFeedMessenger: postFeedMessenger
            )
        ) { viewStore.send(.loadCommentsPage) }
    }

    public var body: some View {
        WithViewStore(store) { viewStore in
            VStack {
                HStack(alignment: .bottom) {
                    HStack {
                        CircularImage(
                            uiImage: userAvatarUIImage,
                            radius: 15,
                            borderColor: .red,
                            borderWidth: 1
                        ).padding(.leading, 5)
                        BoldCaption(creatorUserPostData.userDisplayName)
                    }
                    Spacer()
                    Symbol(symbolName: "ellipsis")
                        .padding(.trailing, 10)
                        .padding(.bottom, 4)
                }
                postUIImage.toImage().resizable().scaledToFit()
                HStack {
                    VStack(alignment: .leading) {
                        HStack {
                            SymbolWithCaption(
                                symbolName: "arrow.up",
                                symbolCaption: imagePostData.postInteractionAggregates.getNetLikes().formatAsStringForView()
                            )

                            if isForCommentsScrollView {
                                buildCommentsIcon(viewStore)
                            } else {
                                buildCommentsIconWithNavigation(viewStore)
                            }

                        }.padding(.bottom, 1)
                        HStack {
                            BoldCaption(creatorUserPostData.userDisplayName)
                                .append(textView: Caption(imagePostData.caption))
                        }
                        Caption(imagePostData.postMetadata.createdAt.formatAsStringForView()).foregroundColor(.gray)
                    }.padding(.leading, 4)
                    Spacer()
                }
            }
            .makeSwipable()
        }
    }

    public static func create(
        postViewIndex: Int,
        imagePostData: ImagePostData,
        userPostData: UserPostData,
        postFeedMessenger: PostFeedMessenger
    ) -> Either<PulpFictionRequestError, ImagePostView> {
        let createPostUIImageEither = Either<PulpFictionRequestError, UIImage>.var()
        let createUserAvatarUIImageEither = Either<PulpFictionRequestError, UIImage>.var()

        return binding(
            createPostUIImageEither <- imagePostData.imagePostContentData.toUIImage(),
            createUserAvatarUIImageEither <- userPostData.userPostContentData.toUIImage(),
            yield: ImagePostView(
                postFeedMessenger: postFeedMessenger,
                postUIImage: createPostUIImageEither.get,
                userAvatarUIImage: createUserAvatarUIImageEither.get,
                creatorUserPostData: userPostData,
                id: postViewIndex,
                imagePostData: imagePostData
            )
        )^.onError { cause in
            logger.error(
                "Error loading post \(imagePostData.postMetadata.postUpdateIdentifier)",
                metadata: [
                    "cause": "\(cause)",
                ]
            )
        }
    }
}
