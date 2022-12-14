//
//  CommentsPageScrollView.swift
//  build_app_source
//
//  Created by Matthew Dornfeld on 10/23/22.
//
import Bow
import Foundation
import SwiftUI

/// Navigation bar for CommentsPageScrollView
struct CommentsPageTopNavigationBar: ToolbarContent {
    var body: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Title("Comments")
                .foregroundColor(.gray)
        }

        ToolbarItem(placement: .navigationBarTrailing) {
            Symbol(
                symbolName: "plus",
                size: 20,
                color: .gray
            ).navigateOnTap(destination: CommentCreatorView())
        }
    }
}

/// View that scrolls through the comments page for a post
struct CommentsPageScrollView: ScrollViewParent {
    let imagePostView: ImagePostView
    let postFeedMessenger: PostFeedMessenger
    let backendMessenger: BackendMessenger
    let postViewEitherSupplier: (Int, Post) -> Either<PulpFictionRequestError, CommentView>

    init(
        imagePostView: ImagePostView,
        postFeedMessenger: PostFeedMessenger,
        backendMessenger: BackendMessenger
    ) {
        self.imagePostView = imagePostView
        self.postFeedMessenger = postFeedMessenger
        self.backendMessenger = backendMessenger
        postViewEitherSupplier = { postViewIndex, postProto in
            let commentPostDataEither = Either<PulpFictionRequestError, CommentPostData>.var()
            let userPostDataEither = Either<PulpFictionRequestError, UserPostData>.var()
            let commentViewEither = Either<PulpFictionRequestError, CommentView>.var()

            return binding(
                commentPostDataEither <- postFeedMessenger.postDataMessenger
                    .getPostData(postProto)
                    .unsafeRunSyncEither(on: .global(qos: .userInteractive))
                    .flatMap { postDataOneOf in postDataOneOf.toCommentPostData() }^,
                userPostDataEither <- postFeedMessenger.postDataMessenger
                    .getPostData(postProto.comment.postCreatorLatestUserPost)
                    .unsafeRunSyncEither(on: .global(qos: .userInteractive))
                    .flatMap { postDataOneOf in postDataOneOf.toUserPostData() }^,
                commentViewEither <- CommentView.create(
                    postViewIndex: postViewIndex,
                    commentPostData: commentPostDataEither.get,
                    userPostData: userPostDataEither.get,
                    postFeedMessenger: postFeedMessenger,
                    backendMessenger: backendMessenger,
                    loggedInUserPostData: postFeedMessenger.loginSession.loggedInUserPostData
                ),
                yield: commentViewEither.get
            )^
        }
    }

    var body: some View {
        ContentScrollView(postViewEitherSupplier: postViewEitherSupplier) { viewStore in
            postFeedMessenger
                .getCommentFeed(
                    postId: imagePostView.imagePostData.postMetadata.postUpdateIdentifier.postId,
                    viewStore: viewStore
                )
        }.toolbar {
            CommentsPageTopNavigationBar()
        }
    }
}
