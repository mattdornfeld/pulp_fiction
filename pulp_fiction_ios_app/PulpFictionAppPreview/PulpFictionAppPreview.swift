//
//  PulpFictionAppPreview.swift
//  PulpFictionApp
//
//  Created by Matthew Dornfeld on 9/14/22.
//

import Bow
import BowEffects
import Foundation
import PulpFictionAppSource
import SwiftUI

@main
struct PulpFictionAppPreview: App {
    private let pulpFictionAppViewBuilder = PulpFictionAppViewBuilder(createExternalMessengers())

    public var body: some Scene {
        WindowGroup {
            pulpFictionAppViewBuilder.buildView()
        }
    }

    private static func createAndPopulatePostDataCache() -> IO<PulpFictionStartupError, PostDataCache> {
        PostDataCache.create().mapRight { postDataCache in
            ImagePostData.generate().map { imagePostData in
                postDataCache
                    .put(imagePostData)
                    .unsafeRunSyncEither()
            }

            ImagePostData.generate().map { imagePostData in
                postDataCache
                    .put(imagePostData)
                    .unsafeRunSyncEither()
            }

            return postDataCache
        }
    }

    private static func createExternalMessengers() -> Either<PulpFictionStartupError, ExternalMessengers> {
        let createPostDataCacheIO = IO<PulpFictionStartupError, PostDataCache>.var()
        let fakeImageDataSupplierIO = IO<PulpFictionStartupError, FakeImageDataSupplier>.var()

        let pulpFictionClientProtocol = PulpFictionTestClientBuilder(
            numPostsInFeedResponse: PreviewAppConfigs.numPostsInFeedResponse
        ).build()
        let backendMessenger = BackendMessenger(pulpFictionClientProtocol: pulpFictionClientProtocol)

        return binding(
            createPostDataCacheIO <- createAndPopulatePostDataCache(),
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
