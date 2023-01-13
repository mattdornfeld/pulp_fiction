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
        externalMessengers: ExternalMessengers,
        postUIImage: UIImage,
        creatorUserPostData: UserPostData,
        id: Int,
        imagePostData: ImagePostData,
        loggedInUserPostData: UserPostData,
        notificationBannerViewStore: NotificationnotificationBannerViewStore,
        contentScrollViewStore: ContentScrollViewStore<ImagePostView>
    ) {
        self.externalMessengers = externalMessengers
        self.postUIImage = postUIImage
        self.creatorUserPostData = creatorUserPostData
        self.id = id
        self.imagePostData = imagePostData
        self.loggedInUserPostData = loggedInUserPostData
        self.notificationBannerViewStore = notificationBannerViewStore
        self.contentScrollViewStore = contentScrollViewStore
        store = Store(
            initialState: ImagePostViewReducer.State(),
            reducer: ImagePostViewReducer()
        )
        swipablePostStore = ImagePostView.buildStore(
            externalMessengers: externalMessengers,
            postMetadata: imagePostData.postMetadata,
            postInteractionAggregates: imagePostData.postInteractionAggregates,
            loggedInUserPostInteractions: imagePostData.loggedInUserPostInteractions,
            notificationBannerViewStore: notificationBannerViewStore
        )
    }
}

/// Renders an image post
struct ImagePostView: PostLikeOnSwipeView, AutoSetter {
    let creatorUserPostData: UserPostData
    let id: Int
    let imagePostData: ImagePostData
    let externalMessengers: ExternalMessengers
    let postUIImage: UIImage
    let loggedInUserPostData: UserPostData
    let notificationBannerViewStore: NotificationnotificationBannerViewStore
    let contentScrollViewStore: ContentScrollViewStore<ImagePostView>
    var postMetadata: PostMetadata { imagePostData.postMetadata }
    private var isForCommentsScrollView: Bool = false
    private let store: ComposableArchitecture.StoreOf<ImagePostViewReducer>
    internal let swipablePostStore: ComposableArchitecture.StoreOf<PostLikeOnSwipeReducer>
    private static let logger = Logger(label: String(describing: ImagePostView.self))

    static func == (lhs: ImagePostView, rhs: ImagePostView) -> Bool {
        lhs.postUIImage == rhs.postUIImage
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

    private func buildCommentsIconWithNavigation(
        _ viewStore: ViewStore<ImagePostViewReducer.State, ImagePostViewReducer.Action>
    ) -> some View {
        return buildCommentsIcon(viewStore).navigateOnTap(
            isActive: viewStore.binding(
                get: \.shouldLoadCommentScrollView,
                send: ImagePostViewReducer.Action.unloadCommentScrollView
            ),
            destination: CommentsPageScrollView(
                imagePostView: ImagePostView
                    .setter(for: \.isForCommentsScrollView)
                    .set(self, true),
                externalMessengers: externalMessengers,
                notificationBannerViewStore: notificationBannerViewStore
            )
        ) { viewStore.send(.loadCommentScrollView) }
    }

    @ViewBuilder func postViewBuilder() -> some View {
        WithViewStore(store) { viewStore in
            VStack {
                HStack(alignment: .bottom) {
                    UserPostView(
                        userPostData: creatorUserPostData,
                        externalMessengers: externalMessengers,
                        loggedInUserPostData: loggedInUserPostData,
                        notificationBannerViewStore: notificationBannerViewStore
                    )
                    Spacer()
                    ExtraOptionsDropDownMenuView(
                        postMetadata: imagePostData.postMetadata,
                        externalMessengers: externalMessengers,
                        notificationBannerViewStore: notificationBannerViewStore,
                        contentScrollViewStore: contentScrollViewStore
                    )
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
                        Caption(
                            text: imagePostData.postMetadata.createdAt.formatAsStringForView(),
                            color: .gray
                        )
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
        externalMessengers: ExternalMessengers,
        loggedInUserPostData: UserPostData,
        notificationBannerViewStore: NotificationnotificationBannerViewStore,
        contentScrollViewStore: ContentScrollViewStore<ImagePostView>
    ) -> Either<PulpFictionRequestError, ImagePostView> {
        let createPostUIImageEither = Either<PulpFictionRequestError, UIImage>.var()

        return binding(
            createPostUIImageEither <- imagePostData.imagePostContentData.toUIImage(),
            yield: ImagePostView(
                externalMessengers: externalMessengers,
                postUIImage: createPostUIImageEither.get,
                creatorUserPostData: userPostData,
                id: postViewIndex,
                imagePostData: imagePostData,
                loggedInUserPostData: loggedInUserPostData,
                notificationBannerViewStore: notificationBannerViewStore,
                contentScrollViewStore: contentScrollViewStore
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

    static func getPostViewEitherSupplier(
        externalMessengers: ExternalMessengers,
        notificationBannerViewStore: NotificationnotificationBannerViewStore
    ) -> PostViewEitherSupplier<ImagePostView> {
        { postViewIndex, postProto, contentScrollViewStore in
            let imagePostDataEither = Either<PulpFictionRequestError, ImagePostData>.var()
            let userPostDataEither = Either<PulpFictionRequestError, UserPostData>.var()
            let imagePostViewEither = Either<PulpFictionRequestError, ImagePostView>.var()

            return binding(
                imagePostDataEither <- externalMessengers.postDataMessenger
                    .getPostData(postProto)
                    .unsafeRunSyncEither(on: .global(qos: .userInteractive))
                    .flatMap { postDataOneOf in postDataOneOf.toImagePostData() }^,
                userPostDataEither <- externalMessengers.postDataMessenger
                    .getPostData(postProto.imagePost.postCreatorLatestUserPost)
                    .unsafeRunSyncEither(on: .global(qos: .userInteractive))
                    .flatMap { postDataOneOf in postDataOneOf.toUserPostData() }^,
                imagePostViewEither <- ImagePostView.create(
                    postViewIndex: postViewIndex,
                    imagePostData: imagePostDataEither.get,
                    userPostData: userPostDataEither.get,
                    externalMessengers: externalMessengers,
                    loggedInUserPostData: externalMessengers.loginSession.loggedInUserPostData,
                    notificationBannerViewStore: notificationBannerViewStore,
                    contentScrollViewStore: contentScrollViewStore
                ),
                yield: imagePostViewEither.get
            )^
        }
    }
}
