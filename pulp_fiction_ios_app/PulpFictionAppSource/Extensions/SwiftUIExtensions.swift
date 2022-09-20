//
//  SwiftUIExtensions.swift
//  build_app_source
//
//  Created by Matthew Dornfeld on 9/19/22.
//

import Bow
import Foundation
import Logging
import SwiftUI

public extension UIImage {
    private struct Companion {
        static let logger: Logger = .init(label: String(describing: Companion.self))
    }

    class ErrorSerializingImage: PulpFictionRequestError {}

    func serializeImage() -> Either<PulpFictionRequestError, Data> {
        guard let imageData = pngData() else {
            Companion.logger.error("Error converting \(self) to pngData")
            return Either.left(ErrorSerializingImage())
        }

        return Either.right(imageData.base64EncodedData())
    }

    func toImage() -> Image {
        Image(uiImage: self)
    }

    static func fromBundleFile(named: String) -> Option<UIImage> {
        ResourceConfigs.resourceBundleFileIdentifier.map { resourceBundleFileIdentifier in
            let bundle = Bundle(identifier: resourceBundleFileIdentifier)
            return UIImage(named: named, in: bundle, with: nil)
        }^
            .getOrElse(UIImage(named: named))
            .toOption()
    }
}
