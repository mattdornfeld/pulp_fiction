//
//  BowExtensions.swift
//  build_app_source
//
//  Created by Matthew Dornfeld on 9/17/22.
//

import Bow
import BowEffects
import ComposableArchitecture
import Foundation
import Logging
import SwiftUI

private struct BowExtensionLogger {
    static let logger: Logger = .init(label: String(describing: BowExtensionLogger.self))
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
        return unsafeRunSyncEither()
            .fold(
                { error in ComposableArchitecture.Effect(error: error) },
                { value in ComposableArchitecture.Effect(value: value) }
            )
    }

    @discardableResult
    func onSuccess(_ f: @escaping (A) -> Void) -> IO<E, A> {
        map { a in
            f(a)
            return a
        }^
    }

    func getOrThrow() throws -> A {
        return try unsafeRunSyncEither()
            .getOrThrow()
    }

    func logError(_ msg: String) -> IO<E, A> {
        mapError { cause in
            BowExtensionLogger.logger.error(
                Logger.Message(stringLiteral: msg),
                metadata: [
                    "cause": "\(cause)",
                ]
            )
            return cause
        }
        return self
    }

    func logSuccess(_ msgSupplier: @escaping (A) -> String) -> IO<E, A> {
        mapRight { a in
            BowExtensionLogger.logger.info(
                Logger.Message(stringLiteral: msgSupplier(a))
            )
        }
        return self
    }
}

public extension Either {
    struct LeftValueNotError: Error {}

    enum EitherEnum<A, B> {
        case left(A)
        case right(B)
    }

    @discardableResult
    func mapRight<C>(_ f: (B) -> C) -> Either<A, C> {
        return bimap({ a in a }, f)
    }

    @discardableResult
    func onError(_ f: (A) -> Void) -> Either<A, B> {
        mapLeft { a in f(a) }
        return self
    }

    @discardableResult
    func onSuccess(_ f: (B) -> Void) -> Either<A, B> {
        mapRight { b in f(b) }
        return self
    }

    func getOrThrow() throws -> B {
        if isRight {
            return rightValue
        }

        switch leftValue {
        case let a as Error:
            throw a
        default:
            throw LeftValueNotError()
        }
    }

    func logSuccess(_ msgSupplier: (B) -> String) -> Either<A, B> where A: Error {
        mapRight { b in
            BowExtensionLogger.logger.info(
                Logger.Message(stringLiteral: msgSupplier(b))
            )
        }
        return self
    }

    @discardableResult
    func logError(_ msg: String) -> Either<A, B> where A: Error {
        mapLeft { cause in
            BowExtensionLogger.logger.error(
                Logger.Message(stringLiteral: msg),
                metadata: [
                    "cause": "\(cause)",
                ]
            )
        }
        return self
    }

    func toEnum() -> EitherEnum<A, B> {
        if isLeft {
            return EitherEnum.left(leftValue)
        }
        return EitherEnum.right(rightValue)
    }

    func toEitherView() -> EitherView<A, B> where A: View, B: View {
        EitherView(state: self)
    }

    func toEffect() -> ComposableArchitecture.Effect<B, A> where A: Error {
        return fold(
            { error in ComposableArchitecture.Effect<B, A>(error: error) },
            { value in ComposableArchitecture.Effect<B, A>(value: value) }
        )
    }

    func toIO() -> IO<A, B> where A: Error {
        IO.invoke { try self.getOrThrow() }
    }

    func toResult() -> Swift.Result<B, A> where A: Error {
        return fold(
            { error in Swift.Result.failure(error) },
            { value in Swift.Result.success(value) }
        )
    }
}

public extension Option {
    struct EmptyOptional: Error {}

    func getOrThrow() throws -> A {
        guard let value = toOptional() else {
            throw EmptyOptional()
        }

        return value
    }

    func toEither<E: Error>(_ error: E) -> Either<E, A> {
        return map { success in Either<E, A>.right(success) }^
            .getOrElse(Either<E, A>.left(error))
    }

    func toEither() -> Either<Error, A> {
        toEither(EmptyOptional())
    }

    @discardableResult
    func mapRight<B>(_ f: @escaping (A) -> B) -> Option<B> {
        map { f($0) }^
    }

    @discardableResult
    func ifEmpty(_ f: @escaping () -> Void) -> Option<A> {
        f()
        return self
    }
}
