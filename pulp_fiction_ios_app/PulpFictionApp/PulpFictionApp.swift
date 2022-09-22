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
        let createPulpFictionClientProtocolResult = IO<PulpFictionStartupError, PulpFictionClientProtocol>.var()
        let createPostDataCacheResult = IO<PulpFictionStartupError, PostDataCache>.var()

        return binding(
            createPulpFictionClientProtocolResult <- GrpcUtils.buildTestPulpFictionClientProtocol(),
            createPostDataCacheResult <- PostDataCache.create(),
            yield: ExternalMessengers(
                pulpFictionClientProtocol: createPulpFictionClientProtocolResult.get,
                postDataCache: createPostDataCacheResult.get
            )
        )^.unsafeRunSyncEither()
    }
}
