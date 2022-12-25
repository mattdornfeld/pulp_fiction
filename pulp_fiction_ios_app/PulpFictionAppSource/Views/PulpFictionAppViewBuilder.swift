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
    let externalMessengersEither: Either<PulpFictionStartupError, ExternalMessengers>
    private let notificationBanner: NotificationBanner = .init()

    @ViewBuilder public func buildView() -> some View {
        NavigationView {
            externalMessengersEither
                .mapLeft { _ in EmptyView() }
                .mapRight { externalMessengers in
                    Login(
                        externalMessengers: externalMessengers,
                        notificationBannerViewStore: notificationBanner.viewStore
                    )
                }
                .toEitherView()
        }
        .overlay {
            notificationBanner
        }
    }
}

public extension PulpFictionAppViewBuilder {
    init(_ externalMessengersEither: Either<PulpFictionStartupError, ExternalMessengers>) {
        self.init(externalMessengersEither: externalMessengersEither)
    }
}
