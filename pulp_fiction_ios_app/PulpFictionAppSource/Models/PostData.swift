//
//  PostData.swift
//  PulpFictionApp
//
//  Created by Matthew Dornfeld on 9/7/22.
//

import Bow
import Foundation

/// Base protocol implemented by all data models which contain post data
protocol PostData: Codable {
    var postMetadata: PostMetadata { get }

    /// - Returns: PostData wrapped in a PostDataOneOf
    func toPostDataOneOf() -> PostDataOneOf
}

/// Enum wrapper for post data models. All models must be wrapped in this structure before being stored in the cache.
/// Also useful for identifying what type of PostData is being used.
enum PostDataOneOf: Codable, Equatable {
    case unregonizedPostData(UnrecognizedPostData)
    case imagePostData(ImagePostData)
    case commentPostData(CommentPostData)
    case userPostData(UserPostData)

    class ErrorConvertingToImagePostData: PulpFictionRequestError {}
    class ErrorConvertingToUserPostData: PulpFictionRequestError {}

    func toPostData() -> PostData {
        switch self {
        case let .unregonizedPostData(unrecognizedPostData):
            return unrecognizedPostData
        case let .imagePostData(imagePostData):
            return imagePostData
        case let .commentPostData(commentPostData):
            return commentPostData
        case let .userPostData(userPostData):
            return userPostData
        }
    }

    func toImagePostData() -> Either<PulpFictionRequestError, ImagePostData> {
        switch self {
        case let .imagePostData(imagePostData):
            return Either.right(imagePostData)
        default:
            return Either.left(ErrorConvertingToImagePostData("PostDataOneOf \(self) could not be converted to ImagePostData"))
        }
    }

    func toCommentPostData() -> Either<PulpFictionRequestError, CommentPostData> {
        switch self {
        case let .commentPostData(commentPostData):
            return Either.right(commentPostData)
        default:
            return Either.left(ErrorConvertingToImagePostData("PostDataOneOf \(self) could not be converted to CommentPostData"))
        }
    }

    func toUserPostData() -> Either<PulpFictionRequestError, UserPostData> {
        switch self {
        case let .userPostData(userPostData):
            return Either.right(userPostData)
        default:
            return Either.left(ErrorConvertingToUserPostData("PostDataOneOf \(self) could not be converted to UserPostData"))
        }
    }
}
