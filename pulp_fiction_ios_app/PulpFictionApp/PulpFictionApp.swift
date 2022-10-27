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
        let loggedInUserUserPostDataIO = IO<PulpFictionStartupError, UserPostData>.var()

        return binding(
            createPulpFictionClientProtocolIO <- GrpcUtils.buildPulpFictionClientProtocol(),
            createPostDataCacheIO <- PostDataCache.create(),
            loggedInUserUserPostDataIO <- UserPostData.generate()
                .mapError { PulpFictionStartupError($0) },
            yield: {
                let postDataMessenger = PostDataMessenger(
                    postDataCache: createPostDataCacheIO.get,
                    imageDataSupplier: { url in try Data(url: url) }
                )

                let loginSession = LoginSession(loggedInUserPostData: loggedInUserUserPostDataIO.get)

                let postFeedMessenger = PostFeedMessenger(
                    pulpFictionClientProtocol: createPulpFictionClientProtocolIO.get,
                    postDataMessenger: postDataMessenger,
                    loginSession: loginSession
                )

                return ExternalMessengers(
                    backendMessenger: BackendMessenger(
                        pulpFictionClientProtocol: createPulpFictionClientProtocolIO.get,
                        loginSession: loginSession
                    ),
                    postDataMessenger: postDataMessenger,
                    postFeedMessenger: postFeedMessenger,
                    loginSession: loginSession
                )

            }()
        )^.unsafeRunSyncEither()
    }
}
