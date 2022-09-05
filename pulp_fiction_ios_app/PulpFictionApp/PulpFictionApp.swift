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

struct ExternalConnections {
    let localImageStore: LocalImageStore
    let backendMessenger: BackendMessenger

    static func create() -> Result<ExternalConnections, PulpFictionStartupError> {
        let pulpFictionClientProtocolIO = IO<PulpFictionStartupError, PulpFictionClientProtocol>.var()

        return binding(
            pulpFictionClientProtocolIO <- GrpcUtils.buildTestPulpFictionClientProtocol(),
            yield: ExternalConnections(
                localImageStore: LocalImageStore()!,
                backendMessenger: BackendMessenger(pulpFictionClientProtocol: pulpFictionClientProtocolIO.get)
            )
        )^
            .unsafeRunSyncEither()
            .toResult()
    }
}

@main
struct PulpFictionApp: App {
    let externalConnectionsResult = ExternalConnections.create()

    var body: some Scene {
        WindowGroup {
            buildView()
        }
    }

    @ViewBuilder private func buildView() -> some View {
        switch externalConnectionsResult {
        case let .success(externalConnections):
            NavigationView {
                VStack {
                    NavigationLink("create", destination: PostCreatorView(localImageStore: externalConnections.localImageStore))
                    Divider()
                    NavigationLink("feed", destination: ScrollingContentView(localImageStore: externalConnections.localImageStore))
                }
            }
        case let .failure(pulpFictionStartupError):
            NavigationView {}
        }
    }
}
