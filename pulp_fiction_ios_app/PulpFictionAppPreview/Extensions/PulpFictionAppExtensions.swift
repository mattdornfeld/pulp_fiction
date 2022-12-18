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

extension ExternalMessengers {
    /// Create the ExternalMessengers for tests and running the preview app
    static func createForTests() -> Either<PulpFictionStartupError, ExternalMessengers> {
        let createPostDataCacheIO = IO<PulpFictionStartupError, PostDataCache>.var()
        let fakeImageDataSupplierIO = IO<PulpFictionStartupError, FakeImageDataSupplier>.var()
        let loggedInUserUserPostDataIO = IO<PulpFictionStartupError, UserPostData>.var()

        let pulpFictionClientProtocol = PulpFictionTestClientWithFakeData()

        return binding(
            createPostDataCacheIO <- PostDataCache.create(),
            fakeImageDataSupplierIO <- FakeImageDataSupplier.create(),
            loggedInUserUserPostDataIO <- UserPostData.generate()
                .logError("Error generating UserPostData")
                .mapError { PulpFictionStartupError($0) },
            yield: {
                let postDataMessenger = PostDataMessenger(
                    postDataCache: createPostDataCacheIO.get,
                    imageDataSupplier: fakeImageDataSupplierIO.get.imageDataSupplier
                )

                let loginSession = LoginSession(loggedInUserPostData: loggedInUserUserPostDataIO.get)

                let postFeedMessenger = PostFeedMessenger(
                    pulpFictionClientProtocol: pulpFictionClientProtocol,
                    postDataMessenger: postDataMessenger,
                    loginSession: loginSession
                )

                let backendMessenger = BackendMessenger(
                    pulpFictionClientProtocol: pulpFictionClientProtocol,
                    loginSession: loginSession
                )

                return ExternalMessengers(
                    backendMessenger: backendMessenger,
                    postDataMessenger: postDataMessenger,
                    postFeedMessenger: postFeedMessenger,
                    loginSession: loginSession
                )
            }()
        )^.unsafeRunSyncEither()
    }
}
