//
//  Landing.swift
//  build_app_source
//
//  Created by Matthew Dornfeld on 12/31/22.
//

import Foundation
import SwiftUI

/// Landing page view
struct Landing: PulpFictionView {
    let externalMessengers: ExternalMessengers
    let notificationBannerViewStore: NotificationnotificationBannerViewStore

    var body: some View {
        VStack {
            Spacer()
            PulpFictionNavigationButton(
                text: "CREATE ACCOUNT",
                backgroundColor: .orange
            ) {
                CreateAccount(
                    externalMessengers: externalMessengers,
                    notificationBannerViewStore: notificationBannerViewStore
                )
            }
            .padding(.bottom)
            PulpFictionNavigationButton(
                text: "LOGIN",
                backgroundColor: .orange
            ) {
                Login(
                    externalMessengers: externalMessengers,
                    notificationBannerViewStore: notificationBannerViewStore
                )
            }
            Spacer()
        }
    }
}
