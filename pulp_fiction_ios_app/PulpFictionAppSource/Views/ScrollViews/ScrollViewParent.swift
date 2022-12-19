//
//  ScrollViewParent.swift
//  build_app_source
//
//  Created by Matthew Dornfeld on 12/11/22.
//

import Bow
import ComposableArchitecture
import Foundation
import SwiftUI

/// Parent for a views for scrolling through posts
protocol ScrollViewParent: View {
    associatedtype A: ScrollableContentView
    var postFeedMessenger: PostFeedMessenger { get }
    var backendMessenger: BackendMessenger { get }
    var postViewEitherSupplier: (Int, Post, ContentScrollViewStore<A>) -> Either<PulpFictionRequestError, A> { get }
    var notificationBannerViewStore: NotificationnotificationBannerViewStore { get }
}

/// Parent for all views for scrolling through image posts
protocol ImagePostScrollView: ScrollViewParent {}

extension ImagePostScrollView {
    var postViewEitherSupplier: (Int, Post, ContentScrollViewStore<ImagePostView>) -> Either<PulpFictionRequestError, ImagePostView> { { postViewIndex, postProto, contentScrollViewStore in
        let imagePostDataEither = Either<PulpFictionRequestError, ImagePostData>.var()
        let userPostDataEither = Either<PulpFictionRequestError, UserPostData>.var()
        let imagePostViewEither = Either<PulpFictionRequestError, ImagePostView>.var()

        return binding(
            imagePostDataEither <- postFeedMessenger.postDataMessenger
                .getPostData(postProto)
                .unsafeRunSyncEither(on: .global(qos: .userInteractive))
                .flatMap { postDataOneOf in postDataOneOf.toImagePostData() }^,
            userPostDataEither <- postFeedMessenger.postDataMessenger
                .getPostData(postProto.imagePost.postCreatorLatestUserPost)
                .unsafeRunSyncEither(on: .global(qos: .userInteractive))
                .flatMap { postDataOneOf in postDataOneOf.toUserPostData() }^,
            imagePostViewEither <- ImagePostView.create(
                postViewIndex: postViewIndex,
                imagePostData: imagePostDataEither.get,
                userPostData: userPostDataEither.get,
                postFeedMessenger: postFeedMessenger,
                loggedInUserPostData: postFeedMessenger.loginSession.loggedInUserPostData,
                backendMessenger: backendMessenger,
                notificationBannerViewStore: notificationBannerViewStore,
                contentScrollViewStore: contentScrollViewStore
            ),
            yield: imagePostViewEither.get
        )^
    }
    }
}
