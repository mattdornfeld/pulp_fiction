//
//  PulpFictionAppViewBuilder.swift
//  build_app_source
//
//  Created by Matthew Dornfeld on 9/18/22.
//

import Bow
import Foundation
import SwiftUI

/// Build the primary view for the app
public struct PulpFictionAppViewBuilder {
    let externalMessengersCreateResult: Either<PulpFictionStartupError, ExternalMessengers>

    @ViewBuilder public func buildView() -> some View {
        switch externalMessengersCreateResult.toResult() {
        case let .success(externalMessengers):
            BottomNavigationBarView(
                loggedInUserPostData: externalMessengers.loginSession.loggedInUserPostData,
                postFeedMessenger: externalMessengers.postFeedMessenger,
                backendMessenger: externalMessengers.backendMessenger
            )
        case .failure:
            NavigationView {}
        }
    }
}

public extension PulpFictionAppViewBuilder {
    init(_ externalMessengersCreateResult: Either<PulpFictionStartupError, ExternalMessengers>) {
        self.init(externalMessengersCreateResult: externalMessengersCreateResult)
    }
}
