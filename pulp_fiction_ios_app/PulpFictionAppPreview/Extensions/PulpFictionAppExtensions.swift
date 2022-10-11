//
//  PulpFictionAppExtensions.swift
//  build_app
//
//  Created by Matthew Dornfeld on 10/8/22.
//

import Bow
import BowEffects
import Foundation
import PulpFictionAppSource

public extension ExternalMessengers {
    /// Create the ExternalMessengers for tests and running the preview app
    static func createForTests(numPostsInFeedResponse: Int) -> Either<PulpFictionStartupError, ExternalMessengers> {
        let createPostDataCacheIO = IO<PulpFictionStartupError, PostDataCache>.var()
        let fakeImageDataSupplierIO = IO<PulpFictionStartupError, FakeImageDataSupplier>.var()

        let pulpFictionClientProtocol = PulpFictionTestClientWithFakeData(
            numPostsInFeedResponse: numPostsInFeedResponse
        )
        let backendMessenger = BackendMessenger(pulpFictionClientProtocol: pulpFictionClientProtocol)

        return binding(
            createPostDataCacheIO <- PostDataCache.create(),
            fakeImageDataSupplierIO <- FakeImageDataSupplier.create(),
            yield: {
                let postDataMessenger = PostDataMessenger(
                    postDataCache: createPostDataCacheIO.get,
                    imageDataSupplier: fakeImageDataSupplierIO.get.imageDataSupplier
                )

                let postFeedMessenger = PostFeedMessenger(
                    pulpFictionClientProtocol: pulpFictionClientProtocol,
                    postDataMessenger: postDataMessenger
                )

                return ExternalMessengers(
                    backendMessenger: backendMessenger,
                    postDataMessenger: postDataMessenger,
                    postFeedMessenger: postFeedMessenger
                )
            }()
        )^.unsafeRunSyncEither()
    }
}
