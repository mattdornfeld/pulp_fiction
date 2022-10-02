//
//  PulpFictionApp.swift
//
//  Created by Matthew Dornfeld on 9/15/22.
//
//

import Bow
import BowEffects
import PulpFictionAppSource
import SwiftUI

@main
struct PulpFictionApp: App {
    let pulpFictionAppViewBuilder = PulpFictionAppViewBuilder(createExternalMessengers())

    public var body: some Scene {
        WindowGroup {
            pulpFictionAppViewBuilder.buildView()
        }
    }

    private static func createExternalMessengers() -> Either<PulpFictionStartupError, ExternalMessengers> {
        let createPulpFictionClientProtocolIO = IO<PulpFictionStartupError, PulpFictionClientProtocol>.var()
        let createPostDataCacheIO = IO<PulpFictionStartupError, PostDataCache>.var()

        return binding(
            createPulpFictionClientProtocolIO <- GrpcUtils.buildPulpFictionClientProtocol(),
            createPostDataCacheIO <- PostDataCache.create(),
            yield: ExternalMessengers(
                backendMessenger: BackendMessenger(pulpFictionClientProtocol: createPulpFictionClientProtocolIO.get),
                postDataMessenger: PostDataMessenger(
                    postDataCache: createPostDataCacheIO.get,
                    imageDataSupplier: { url in try Data(url: url) }
                )
            )
        )^.unsafeRunSyncEither()
    }
}
