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
}

struct EitherCompanion {
    static let logger: Logger = .init(label: String(describing: EitherCompanion.self))
}

public extension Either {
    struct LeftValueNotError: Error {}

    enum EitherEnum<A, B> {
        case left(A)
        case right(B)
    }

    func mapRight<C>(_ f: (B) -> C) -> Either<A, C> {
        return bimap({ a in a }, f)
    }

    func onError(_ f: (A) -> Void) -> Either<A, B> {
        mapLeft { a in f(a) }
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

    func logError(_ msg: String) -> Either<A, B> where A: Error {
        mapLeft { cause in
            EitherCompanion.logger.error(
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

    func mapRight<B>(_ f: @escaping (A) -> B) -> Option<B> {
        map { f($0) }^
    }
}
