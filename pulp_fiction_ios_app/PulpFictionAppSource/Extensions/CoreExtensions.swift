//
//  Extensions.swift
//  _idx_PictureSaverSource_6C36F415_ios_min15.0
//
//  Created by Matthew Dornfeld on 5/22/22.
//

import Bow
import Foundation
import Logging
import SwiftUI

public extension Data {
    class ErrorLoadingFileFromURL: PulpFictionRequestError {}

    init(url: URL) throws {
        do {
            try self.init(contentsOf: url)
        } catch {
            throw ErrorLoadingFileFromURL(error)
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

    func toEither() -> Either<Error, Wrapped> {
        toEither(EmptyOptional())
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

public extension Int64 {
    private enum Companion {
        static let thousand = 1000.0
        static let million = thousand * thousand
        static let billion = thousand * million
    }

    func formatAsStringForView() -> String {
        let doubleValue = Double(self)
        let magnitude = abs(doubleValue)
        if magnitude < Companion.thousand {
            return formatted()
        } else if magnitude < Companion.million {
            return String(format: "%.1fK", locale: Locale.current, doubleValue / Companion.thousand)
                .replacingOccurrences(of: ".0", with: "")
        } else if magnitude < Companion.billion {
            return String(format: "%.1fM", locale: Locale.current, doubleValue / Companion.million)
                .replacingOccurrences(of: ".0", with: "")
        } else {
            return String(format: "%.1fB", locale: Locale.current, doubleValue / Companion.billion)
                .replacingOccurrences(of: ".0", with: "")
        }
    }
}
