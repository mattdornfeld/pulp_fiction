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

    func toContentData() -> Either<PulpFictionRequestError, ContentData> {
        serializeImage().mapRight { data in
            ContentData(
                data: data,
                contentDataType: ContentData.ContentDataType.jpg
            )
        }
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

public extension View {
    /// Navigates to destination when View is tapped
    /// - Parameters:
    ///   - isActive: binding that signifies whether NavigationLink is active
    ///   - destination: destionation View
    ///   - perform: a function to be executed when View is tapped
    /// - Returns: a NavigationLink that executes the navigation when View is tapped
    func navigateOnTap<A: View>(
        isActive: Binding<Bool>,
        destination: A,
        perform: @escaping () -> Void
    ) -> some View {
        NavigationLink(
            destination: destination,
            isActive: isActive,
            label: { self.onTapGesture(perform: perform) }
        )
    }
}
