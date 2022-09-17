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
    
    func logError() -> Either<A, B> where A: Error {
        mapLeft{error in print(error)}
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
        return self.fold(
                { error in ComposableArchitecture.Effect<B, A>(error: error) },
                { value in ComposableArchitecture.Effect<B, A>(value: value) }
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
}
