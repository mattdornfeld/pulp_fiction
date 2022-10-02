//
//  PostDataMessenger.swift
//  PulpFictionApp
//
//  Created by Matthew Dornfeld on 9/8/22.
//
import Bow
import BowEffects
import Foundation

/// Retrieves PostData for a given PostProto. Manages retrieving and store post data in local cache and
/// retrieves it from remote storage if not present in cache.
public struct PostDataMessenger {
    public let postDataCache: PostDataCache
    public let imageDataSupplier: (URL) throws -> Data // try Data(url: url)

    public class UnrecognizedPostType: PulpFictionRequestError {}
    public class InvalidImageURL: PulpFictionRequestError {}

    public init(postDataCache: PostDataCache, imageDataSupplier: @escaping (URL) throws -> Data) {
        self.postDataCache = postDataCache
        self.imageDataSupplier = imageDataSupplier
    }

    private func getPostDataFromLocalCacheOrRemoteStorage(
        _ postMetadataProto: Post.PostMetadata,
        _ postDataSupplier: @escaping (PostMetadata) -> IO<PulpFictionRequestError, PostDataOneOf>
    ) -> IO<PulpFictionRequestError, PostDataOneOf> {
        let postMetadataIO = IO<PulpFictionRequestError, PostMetadata>.var()
        let postDataCacheGetIO = IO<PulpFictionRequestError, Option<PostDataOneOf>>.var()
        let postDataOneOfIO = IO<PulpFictionRequestError, PostDataOneOf>.var()

        return binding(
            postMetadataIO <- postMetadataProto.toPostMetadata().toIO(),
            postDataCacheGetIO <- postDataCache.get(postMetadataIO.get.postUpdateIdentifier),
            postDataOneOfIO <- postDataCacheGetIO
                .get
                .mapRight { postDataOneOf in IO.invoke { postDataOneOf }}
                .getOrElse {
                    postDataSupplier(postMetadataIO.get)
                        .flatMap { postDataOneOf in
                            postDataCache
                                .put(postDataOneOf.toPostData())
                                .mapRight { _ in postDataOneOf }
                        }
                },
            yield: postDataOneOfIO.get
        )^
    }

    private func getCommentPostData(
        _ postMetadataProto: Post.PostMetadata,
        _ commentPostProto: Post.Comment
    ) -> IO<PulpFictionRequestError, PostDataOneOf> {
        postMetadataProto.toPostMetadata().toIO().mapRight { postMetadata in
            commentPostProto
                .toPostData(postMetadata)
                .toPostDataOneOf()
        }
    }

    private func getImagePostData(
        _ postMetadataProto: Post.PostMetadata,
        _ imagePostProto: Post.ImagePost
    ) -> IO<PulpFictionRequestError, PostDataOneOf> {
        getPostDataFromLocalCacheOrRemoteStorage(postMetadataProto) { postMetadata in
            ContentData
                .create(imagePostProto.imageURL, imageDataSupplier)
                .mapRight { imagePostContentData in
                    imagePostProto
                        .toPostData(postMetadata, imagePostContentData)
                        .toPostDataOneOf()
                }
        }
        .logError("Error building ImagePostData")
    }

    private func getUserPostData(
        _ postMetadataProto: Post.PostMetadata,
        _ userPostProto: Post.UserPost
    ) -> IO<PulpFictionRequestError, PostDataOneOf> {
        getPostDataFromLocalCacheOrRemoteStorage(postMetadataProto) { postMetadata in
            ContentData
                .create(userPostProto.userMetadata.avatarImageURL, imageDataSupplier)
                .mapRight { userAvatarImageContentData in
                    userPostProto
                        .toPostData(postMetadata, userAvatarImageContentData)
                        .toPostDataOneOf()
                }
        }
    }

    /// Retrieves PostData for a given PostProto
    /// - Parameter postProto: PostProto returned from backend API
    /// - Returns: IO monad with PostDataOneOf as success type
    public func getPostData(_ postProto: Post) -> IO<PulpFictionRequestError, PostDataOneOf> {
        switch postProto.post {
        case let .comment(commentPostProto):
            return getCommentPostData(postProto.metadata, commentPostProto)
        case let .imagePost(imagePostProto):
            return getImagePostData(postProto.metadata, imagePostProto)
        case let .userPost(userPostProto):
            return getUserPostData(postProto.metadata, userPostProto)
        case .none:
            return Either
                .left(RequestParsingError("Post must have post property specified"))
                .toIO()
        }
    }
}
