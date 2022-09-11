//
//  PictureSaverApp.swift
//  PictureSaver
//
//  Created by Matthew Dornfeld on 3/26/22.
//
//

import Bow
import BowEffects
import ComposableArchitecture
import SwiftUI

struct ExternalMessengers {
    let backendMessenger: BackendMessenger
    let postDataMessenger: PostDataMessenger

    static func create() -> Result<ExternalMessengers, PulpFictionStartupError> {
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

@main
struct PulpFictionApp: App {
    private let externalMessengersCreateResult = ExternalMessengers.create()

    var body: some Scene {
        WindowGroup {
            buildView()
        }
    }

    @ViewBuilder private func buildView() -> some View {
        switch externalMessengersCreateResult {
        case let .success(externalMessengers):
            NavigationView {
                VStack {
                    NavigationLink("create", destination: PostCreatorView(externalMessengers.postDataMessenger.postDataCache))
                    Divider()
                    NavigationLink("feed", destination: ScrollingContentView(externalMessengers.postDataMessenger.postDataCache))
                }
            }
        case let .failure(pulpFictionStartupError):
            NavigationView {}
        }
    }
}
