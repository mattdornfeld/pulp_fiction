//
//  Extensions.swift
//  _idx_PictureSaverSource_6C36F415_ios_min15.0
//
//  Created by Matthew Dornfeld on 5/22/22.
//

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
