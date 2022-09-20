//
//  ExternalMessengers.swift
//
//  Created by Matthew Dornfeld on 9/18/22.
//
//

import Bow
import BowEffects
import ComposableArchitecture

public struct ExternalMessengers {
    public let backendMessenger: BackendMessenger
    public let postDataMessenger: PostDataMessenger

    public static func create() -> Result<ExternalMessengers, PulpFictionStartupError> {
        let backendMessengerIO = IO<PulpFictionStartupError, BackendMessenger>.var()
        let postDataMessengerIO = IO<PulpFictionStartupError, PostDataMessenger>.var()

        return binding(
            backendMessengerIO <- BackendMessenger.create(),
            postDataMessengerIO <- PostDataMessenger.create(),
            yield: ExternalMessengers(
                backendMessenger: backendMessengerIO.get,
                postDataMessenger: postDataMessengerIO.get
            )
        )^
            .unsafeRunSyncEither()
            .toResult()
    }
}
