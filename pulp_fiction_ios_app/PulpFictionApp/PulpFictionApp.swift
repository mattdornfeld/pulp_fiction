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
    let localImageStore: LocalImageStore
    let backendMessenger: BackendMessenger
    let postDataMessenger: PostDataMessenger

    static func create() -> Result<ExternalMessengers, PulpFictionStartupError> {
        let backendMessengerIO = IO<PulpFictionStartupError, BackendMessenger>.var()
        let postDataMessengerIO = IO<PulpFictionStartupError, PostDataMessenger>.var()

        return binding(
            backendMessengerIO <- BackendMessenger.create(),
            postDataMessengerIO <- PostDataMessenger.create(),
            yield: ExternalMessengers(
                localImageStore: LocalImageStore()!,
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
                    NavigationLink("create", destination: PostCreatorView(localImageStore: externalMessengers.localImageStore))
                    Divider()
                    NavigationLink("feed", destination: ScrollingContentView(localImageStore: externalMessengers.localImageStore))
                }
            }
        case let .failure(pulpFictionStartupError):
            NavigationView {}
        }
    }
}
