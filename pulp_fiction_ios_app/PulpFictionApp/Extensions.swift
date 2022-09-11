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
import UIKit

struct UIImageCompanion {
    static let logger: Logger = .init(label: String(describing: UIImageCompanion.self))
}

extension UIImage {
    func serializeImage() -> Data? {
        guard let imageData = pngData() else {
            UIImageCompanion.logger.error("Error converting \(self) to pngData")
            return nil
        }

        return imageData.base64EncodedData()
    }
}

extension Data {
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

    func toResult<T: Error>(_ error: T) -> Swift.Result<Wrapped, T> {
        return map { success in Swift.Result.success(success) }
            .getOrElse(Swift.Result.failure(error))
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

public extension IO {
    func mapRight<B>(_ f: @escaping (A) -> B) -> IO<E, B> {
        return map(f).map { b in b }^
    }
    
    static func invokeAndConvertError<E: PulpFictionError, A>(_ errorSupplier: @escaping (Error) -> E, _ f: @escaping () throws -> A) -> IO<E, A> {
        IO<E, A>.invoke {
            do {
                return try f()
            } catch {
                throw errorSupplier(error)
            }
        }
    }
    
    func toEffect() -> ComposableArchitecture.Effect<A, E> {
        return self
            .unsafeRunSyncEither()
            .fold(
                {error in ComposableArchitecture.Effect(error: error)},
                {value in ComposableArchitecture.Effect(value: value)}
            )
    }
}

public extension Either {
    public struct LeftValueNotError: Error {
        
    }
    
    func mapRight<C>(_ f: (B) -> C) -> Either<A, C> {
        return bimap({ a in a }, f)
    }
    
    func onError(_ f: (A) -> Void) -> Either<A, B> {
        self.mapLeft{a in f(a)}
        return self
    }
    
    func getOrThrow() throws -> B {
        if self.isRight {
            return self.rightValue
        }
        
        switch self.leftValue {
        case let a as Error:
            throw a
        default:
            throw LeftValueNotError()
        }
        
    }
}

public extension Option {
    struct EmptyOptional: Error {}
    
    func getOrThrow() throws -> A {
        guard let value = self.toOptional() else {
            throw EmptyOptional()
        }
        
        return value
    }
}

public extension Post.PostMetadata {
    func toPostMetadata() -> Either<PulpFictionRequestError, PostMetadata> {
        PostMetadata.create(self)
    }
}

public extension Post.ImagePost {
    func toPostData(_ postMetadataProto: Post.PostMetadata) -> Either<PulpFictionRequestError, ImagePostData> {
        ImagePostData.create(postMetadataProto, self)
    }
}

public extension CreatePostRequest {
    static func createImagePostRequest(_ caption: String, _ imageJpg: Data) -> CreatePostRequest {
        CreatePostRequest.with{
            $0.createImagePostRequest = CreatePostRequest.CreateImagePostRequest.with{
                $0.caption = caption
                $0.imageJpg = imageJpg
            }
        }
    }
}

public extension Post.Comment {
    func toPostData(_ postMetadataProto: Post.PostMetadata) -> Either<PulpFictionRequestError, CommentPostData> {
        CommentPostData.create(postMetadataProto, self)
    }
}

public extension Post.UserPost {
    func toPostData(_ postMetadataProto: Post.PostMetadata) -> Either<PulpFictionRequestError, UserPostData> {
        UserPostData.create(postMetadataProto, self)
    }
}

public extension Array {
    func flattenOption<A>() -> [A] where Element == Option<A> {
        self
            .map{aMaybe in aMaybe.orNil}
            .compactMap{$0}
    }
    
    func flattenError<E: Error, A>() -> [A] where Element == Either<E, A> {
        self
            .map{either in either.orNil}
            .compactMap{$0}
    }
    
    func mapAndFilterEmpties<A>(_ transform: (Element) -> Option<A>) -> [A] {
        self
            .map(transform)
            .flattenOption()
    }
    
    func mapAndFilterErrors<E: Error, A>(_ transform: (Element) -> Either<E, A>) -> [A] {
        self
            .map(transform)
            .flattenError()
    }
}
