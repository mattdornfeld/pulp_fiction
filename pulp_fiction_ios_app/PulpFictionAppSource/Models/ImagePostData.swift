//
//  ImagePostData.swift
//  build_app_source
//
//  Created by Matthew Dornfeld on 9/25/22.
//

import Foundation

/// Image post data is stored in this model. Used for rendering ImagePostView.
class ImagePostData: PostData, PostDataIdentifiable, Equatable {
    let id: PostUpdateIdentifier
    let caption: String
    let imagePostContentData: ContentData
    let postMetadata: PostMetadata
    let postInteractionAggregates: PostInteractionAggregates
    let loggedInUserPostInteractions: LoggedInUserPostInteractions

    init(id: PostUpdateIdentifier, caption: String, imagePostContentData: ContentData, postMetadata: PostMetadata, postInteractionAggregates: PostInteractionAggregates, loggedInUserPostInteractions: LoggedInUserPostInteractions) {
        self.id = id
        self.caption = caption
        self.imagePostContentData = imagePostContentData
        self.postMetadata = postMetadata
        self.postInteractionAggregates = postInteractionAggregates
        self.loggedInUserPostInteractions = loggedInUserPostInteractions
    }

    static func == (lhs: ImagePostData, rhs: ImagePostData) -> Bool {
        lhs.id == rhs.id &&
            lhs.caption == rhs.caption &&
            lhs.imagePostContentData == rhs.imagePostContentData &&
            lhs.postMetadata == rhs.postMetadata &&
            lhs.postInteractionAggregates == rhs.postInteractionAggregates &&
            lhs.loggedInUserPostInteractions == rhs.loggedInUserPostInteractions
    }

    func toPostDataOneOf() -> PostDataOneOf {
        PostDataOneOf.imagePostData(self)
    }
}

extension ImagePostData {
    convenience init(
        _ postMetadata: PostMetadata,
        _ imagePostProto: Post.ImagePost,
        _ imagePostContentData: ContentData
    ) {
        self.init(
            id: postMetadata.id,
            caption: imagePostProto.caption,
            imagePostContentData: imagePostContentData,
            postMetadata: postMetadata,
            postInteractionAggregates: imagePostProto
                .interactionAggregates
                .toPostInteractionAggregates(),
            loggedInUserPostInteractions: imagePostProto
                .loggedInUserPostInteractions
                .toLoggedInUserPostInteractions()
        )
    }

    convenience init(_ createImagePostRequestProto: CreatePostRequest.CreateImagePostRequest) {
        let postMetadata = PostMetadata(
            postUpdateIdentifier: PostUpdateIdentifier(postId: UUID(), updatedAt: Date()),
            postType: Post.PostType.image,
            postState: Post.PostState.created,
            createdAt: Date.now,
            postCreatorUserId: UUID()
        )
        self.init(
            id: postMetadata.id,
            caption: createImagePostRequestProto.caption,
            imagePostContentData: ContentData(data: createImagePostRequestProto.imageJpg, contentDataType: ContentData.ContentDataType.jpg),
            postMetadata: postMetadata,
            postInteractionAggregates: PostInteractionAggregates(numLikes: 10, numDislikes: 5, numChildComments: 3),
            loggedInUserPostInteractions: LoggedInUserPostInteractions(postLikeStatus: Post.PostLike.neutral)
        )
    }
}

extension Post.ImagePost {
    func toPostData(_ postMetadata: PostMetadata, _ imagePostContentData: ContentData) -> ImagePostData {
        ImagePostData(postMetadata, self, imagePostContentData)
    }

    func toPost(_ postMetadata: Post.PostMetadata) -> Post {
        Post.with {
            $0.metadata = postMetadata
            $0.post = Post.OneOf_Post.imagePost(self)
        }
    }
}
