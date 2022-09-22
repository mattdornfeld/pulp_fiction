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

    private static func creatrAndPopulatePostDataCache() -> IO<PulpFictionStartupError, PostDataCache> {
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
        let createPostDataCacheResult = IO<PulpFictionStartupError, PostDataCache>.var()

        return binding(
            createPostDataCacheResult <- creatrAndPopulatePostDataCache(),
            yield: ExternalMessengers(
                pulpFictionClientProtocol: PulpFictionTestClientBuilder(numPostsInFeedResponse: PreviewAppConfigs.numPostsInFeedResponse).build(),
                postDataCache: createPostDataCacheResult.get
            )
        )^.unsafeRunSyncEither()
    }
}
