//
//  ImageDataSupplierBuilder.swift
//  PulpFictionApp
//
//  Created by Matthew Dornfeld on 9/27/22.
//

import Bow
import BowEffects
import Foundation
import UIKit

/// FakeImageDataSupplier provides a JPG image in Data form for a given URL
public class FakeImageDataSupplier {
    /// Function that returns a JPG image in Data form when passed a URL
    public let imageDataSupplier: (URL) throws -> Data

    /// FakeImageDataSupplier constructor
    /// - Parameter urlToImageData: mapping from URL JPG image in Data form
    public init(urlToImageData: [URL: Data]) {
        imageDataSupplier = { url in
            try urlToImageData[url].getOrThrow()
        }
    }

    /// Creates a FakeImageDataSupplier and handles errors
    public static func create() -> IO<PulpFictionStartupError, FakeImageDataSupplier> {
        let imagePostDataIO = IO<PulpFictionRequestError, ImagePostData>.var()
        let userPostDataIO = IO<PulpFictionRequestError, UserPostData>.var()
        return binding(
            imagePostDataIO <- ImagePostData.generate(),
            userPostDataIO <- UserPostData.generate(),
            yield: [
                FakeData.imagePostJpgUrl: imagePostDataIO.get.imagePostContentData.data,
                FakeData.userAvatarJpgUrl: userPostDataIO.get.userPostContentData.data,
            ]
        )^
            .mapError { pulpFictionRequestError in PulpFictionStartupError(pulpFictionRequestError) }
            .mapRight { urlToImageData in
                FakeImageDataSupplier(urlToImageData: urlToImageData)
            }
    }
}
