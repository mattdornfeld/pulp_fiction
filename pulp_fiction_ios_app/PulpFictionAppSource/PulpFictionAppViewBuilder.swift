//
//  PulpFictionAppViewBuilder.swift
//  build_app_source
//
//  Created by Matthew Dornfeld on 9/18/22.
//

import Foundation
import SwiftUI

public struct PulpFictionAppViewBuilder {
    let externalMessengersCreateResult: Result<ExternalMessengers, PulpFictionStartupError>

    @ViewBuilder public func buildView() -> some View {
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

public extension PulpFictionAppViewBuilder {
    init(_ externalMessengersCreateResult: Result<ExternalMessengers, PulpFictionStartupError>) {
        self.init(externalMessengersCreateResult: externalMessengersCreateResult)
    }
}
