//
// Created by Matthew Dornfeld on 4/3/22.
//

import Bow
import BowOptics
import ComposableArchitecture
import Logging
import SwiftUI

struct ImagePostViewReducer: ReducerProtocol {
    struct State: Equatable {
        var shouldLoadCommentScrollView: Bool = false
        var shouldLoadUserProfileView: Bool = false
    }

    enum Action {
        case loadCommentScrollView
        case unloadCommentScrollView
        case loadUserProfileView
        case unloadUserProfileView
    }

    func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
        switch action {
        case .loadCommentScrollView:
            state.shouldLoadCommentScrollView = true
            return .none
        case .unloadCommentScrollView:
            state.shouldLoadCommentScrollView = false
            return .none
        case .loadUserProfileView:
            state.shouldLoadUserProfileView = true
            return .none
        case .unloadUserProfileView:
            state.shouldLoadUserProfileView = false
            return .none
        }
    }
}

extension ImagePostView {
    init(
        postFeedMessenger: PostFeedMessenger,
        postUIImage: UIImage,
        userAvatarUIImage: UIImage,
        creatorUserPostData: UserPostData,
        id: Int,
        imagePostData: ImagePostData
    ) {
        self.postFeedMessenger = postFeedMessenger
        self.postUIImage = postUIImage
        self.userAvatarUIImage = userAvatarUIImage
        self.creatorUserPostData = creatorUserPostData
        self.id = id
        self.imagePostData = imagePostData
        store = Store(
            initialState: ImagePostViewReducer.State(),
            reducer: ImagePostViewReducer()
        )
        swipablePostStore = ImagePostView.buildStore(
            postInteractionAggregates: imagePostData.postInteractionAggregates,
            loggedInUserPostInteractions: imagePostData.loggedInUserPostInteractions
        )
    }
}

/// Renders an image post
struct ImagePostView: SwipablePostView, AutoSetter {
    private let postFeedMessenger: PostFeedMessenger
    private let postUIImage: UIImage
    private let userAvatarUIImage: UIImage
    let creatorUserPostData: UserPostData
    let id: Int
    let imagePostData: ImagePostData
    private var isForCommentsScrollView: Bool = false
    private let store: ComposableArchitecture.StoreOf<ImagePostViewReducer>
    internal let swipablePostStore: ComposableArchitecture.Store<PostSwipeState, PostSwipeAction>
    private static let logger = Logger(label: String(describing: ImagePostView.self))

    static func == (lhs: ImagePostView, rhs: ImagePostView) -> Bool {
        lhs.postUIImage == rhs.postUIImage
            && lhs.userAvatarUIImage == rhs.userAvatarUIImage
            && lhs.creatorUserPostData == rhs.creatorUserPostData
            && lhs.id == rhs.id
            && lhs.imagePostData == rhs.imagePostData
    }

    private func buildCommentsIcon(_: ViewStore<ImagePostViewReducer.State, ImagePostViewReducer.Action>) -> some View {
        SymbolWithCaption(
            symbolName: "text.bubble",
            symbolCaption: imagePostData
                .postInteractionAggregates
                .numChildComments
                .formatAsStringForView()
        )
    }

    private func buildCommentsIconWithNavigation(_ viewStore: ViewStore<ImagePostViewReducer.State, ImagePostViewReducer.Action>) -> some View {
        return buildCommentsIcon(viewStore).navigateOnTap(
            isActive: viewStore.binding(
                get: \.shouldLoadCommentScrollView,
                send: ImagePostViewReducer.Action.unloadCommentScrollView
            ),
            destination: CommentScrollView(
                imagePostView: ImagePostView
                    .setter(for: \.isForCommentsScrollView)
                    .set(self, true),
                postFeedMessenger: postFeedMessenger
            )
        ) { viewStore.send(.loadCommentScrollView) }
    }

    @ViewBuilder func postViewBuilder() -> some View {
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
                    }.navigateOnTap(
                        isActive: viewStore.binding(
                            get: \.shouldLoadUserProfileView,
                            send: ImagePostViewReducer.Action.unloadUserProfileView
                        ),
                        destination: UserProfileView(
                            id: 0,
                            userPostData: creatorUserPostData,
                            userAvatarUIImage: userAvatarUIImage,
                            postFeedMessenger: postFeedMessenger
                        )
                    ) {
                        viewStore.send(.loadUserProfileView)
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
                            buildPostLikeArrowView()

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
        }
    }

    static func create(
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
