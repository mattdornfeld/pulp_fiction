//
//  Extensions.swift
//  _idx_PictureSaverSource_6C36F415_ios_min15.0
//
//  Created by Matthew Dornfeld on 5/22/22.
//

import Bow
import BowEffects
import ComposableArchitecture
import Foundation
import Logging
import SwiftUI
import UIKit

struct UIImageCompanion {
    static let logger: Logger = .init(label: String(describing: UIImageCompanion.self))
}

public extension UIImage {
    class ErrorSerializingImage:PulpFictionRequestError {}
    
    func serializeImage() -> Either<PulpFictionRequestError, Data> {
        guard let imageData = pngData() else {
            UIImageCompanion.logger.error("Error converting \(self) to pngData")
            return Either.left(ErrorSerializingImage())
        }

        return Either.right(imageData.base64EncodedData())
    }
    
    func toImage() -> Image {
        Image(uiImage: self)
    }
    
    static func fromBundleFile(named: String) -> Option<UIImage> {
        ResourceConfigs.resourceBundleFileIdentifier.map{ resourceBundleFileIdentifier in
            let bundle = Bundle(identifier: resourceBundleFileIdentifier)
            return UIImage(named: named, in: bundle, with: nil)
        }^
        .getOrElse(UIImage(named: named))
        .toOption()
    }
}

extension Data {
    public class ErrorDeserializingImage: PulpFictionRequestError {}
    func toUIImage() -> Either<PulpFictionRequestError, UIImage> {
        guard let imageData = Data(
            base64Encoded: self,
            options: Data.Base64DecodingOptions.ignoreUnknownCharacters
        ) else {
            return Either.left(ErrorDeserializingImage())
        }

        if let uiImage = UIImage(data: imageData) {
            return Either.right(uiImage)
        } else {
            return Either.left(ErrorDeserializingImage())
        }
    }
}

extension String {
    public class ErrorParsingUUID: PulpFictionRequestError {}

    func toUUID() -> Either<PulpFictionRequestError, UUID> {
        guard let uuid = UUID(uuidString: self) else {
            return Either.left(ErrorParsingUUID())
        }
        return Either.right(uuid)
    }
}

public extension Optional {
    struct EmptyOptional: Error {}

    func getOrThrow() throws -> Wrapped {
        return try getOrThrow(EmptyOptional())
    }

    func getOrThrow(
        _ errorSupplier: @autoclosure () -> Error
    ) throws -> Wrapped {
        guard let value = self else {
            throw errorSupplier()
        }

        return value
    }

    func getOrElse(_ defaultValue: Wrapped) -> Wrapped {
        guard let value = self else {
            return defaultValue
        }

        return value
    }

    func toResult<E: Error>(_ error: E) -> Swift.Result<Wrapped, E> {
        return map { success in Swift.Result.success(success) }
            .getOrElse(Swift.Result.failure(error))
    }
    
    func toEither<E: Error>(_ error: E) -> Either<E, Wrapped> {
        return map { success in Either.right(success) }
            .getOrElse(Either.left(error))
    }
}

public extension Result {
    @discardableResult
    func onSuccess(_ handler: (Success) -> Void) -> Self {
        guard case let .success(value) = self else { return self }
        handler(value)
        return self
    }

    @discardableResult
    func onFailure(_ handler: (Failure) -> Void) -> Self {
        guard case let .failure(error) = self else { return self }
        handler(error)
        return self
    }

    func isSuccess() -> Bool {
        switch self {
        case .success:
            return true
        case .failure:
            return false
        }
    }

    func isFailure() -> Bool {
        switch self {
        case .success:
            return false
        case .failure:
            return true
        }
    }

    func toOption() -> Success? {
        switch self {
        case let .success(success):
            return success
        case .failure:
            return nil
        }
    }

    func getOrElse(_ defaultValue: Success) -> Success {
        switch self {
        case let .success(success):
            return success
        case .failure:
            return defaultValue
        }
    }
}

public extension Post.PostMetadata {
    func toPostMetadata(_ avatarImageJpg: Data) -> Either<PulpFictionRequestError, PostMetadata> {
        PostMetadata.create(self, avatarImageJpg)
    }
}

public extension Post.ImagePost {
    func toPostData(_ postMetadata: PostMetadata, _ imageJpg: Data) -> ImagePostData {
        ImagePostData(postMetadata, self, imageJpg)
    }
}

public extension CreatePostRequest {
    static func createImagePostRequest(_ caption: String, _ imageJpg: Data) -> CreatePostRequest {
        CreatePostRequest.with {
            $0.createImagePostRequest = CreatePostRequest.CreateImagePostRequest.with {
                $0.caption = caption
                $0.imageJpg = imageJpg
            }
        }
    }
}

public extension Post.Comment {
    func toPostData(_ postMetadata: PostMetadata) -> CommentPostData {
        CommentPostData(postMetadata)
    }
}

public extension Post.UserPost {
    func toPostData(_ postMetadata: PostMetadata, _ avatarImageJpg: Data) -> UserPostData {
        UserPostData(postMetadata)
    }
}

public extension Array {
    func flattenOption<A>() -> [A] where Element == Option<A> {
        map { aMaybe in aMaybe.orNil }
            .compactMap { $0 }
    }

    func flattenError<E: Error, A>() -> [A] where Element == Either<E, A> {
        map { either in either.orNil }
            .compactMap { $0 }
    }

    func mapAndFilterEmpties<A>(_ transform: (Element) -> Option<A>) -> [A] {
        map(transform)
            .flattenOption()
    }

    func mapAndFilterErrors<E: Error, A>(_ transform: (Element) -> Either<E, A>) -> [A] {
        map(transform)
            .flattenError()
    }
}
