//
//  PulpFictionAppViewBuilder.swift
//  build_app_source
//
//  Created by Matthew Dornfeld on 9/18/22.
//

import Bow
import Foundation
import SwiftUI

public struct PulpFictionAppViewBuilder {
    let externalMessengersCreateResult: Either<PulpFictionStartupError, ExternalMessengers>

    @ViewBuilder public func buildView() -> some View {
        switch externalMessengersCreateResult.toResult() {
        case let .success(externalMessengers):
            NavigationView {
                VStack {
                    NavigationLink("create", destination: PostCreatorView(externalMessengers.postDataMessenger.postDataCache))
                    Divider()
                    NavigationLink("feed", destination: ScrollingContentView(
                        postFeedMessenger: externalMessengers.postFeedMessenger
                    ))
                }
            }
        case let .failure(pulpFictionStartupError):
            NavigationView {}
        }
    }
}

public extension PulpFictionAppViewBuilder {
    init(_ externalMessengersCreateResult: Either<PulpFictionStartupError, ExternalMessengers>) {
        self.init(externalMessengersCreateResult: externalMessengersCreateResult)
    }
}
