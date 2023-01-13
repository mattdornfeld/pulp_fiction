//
//  LoggedInUserProfileTopNavigationBar.swift
//  build_app_source
//
//  Created by Matthew Dornfeld on 10/23/22.
//

import ComposableArchitecture
import Foundation
import SwiftUI

struct LoggedInUserProfileTopNavigationBar: PulpFictionToolbarContent {
    let loggedInUserPostData: UserPostData
    let externalMessengers: ExternalMessengers
    let notificationBannerViewStore: NotificationnotificationBannerViewStore

    var body: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Title(loggedInUserPostData.userDisplayName)
                .foregroundColor(.gray)
        }

        ToolbarItem(placement: .navigationBarTrailing) {
            HStack {
                Symbol(
                    symbolName: "plus",
                    size: 20,
                    color: .gray
                )
                .navigateOnTap(destination: PostCreatorView(
                    loggedInUserPostData: loggedInUserPostData,
                    externalMessengers: externalMessengers,
                    notificationBannerViewStore: notificationBannerViewStore
                ))

                Symbol(
                    symbolName: "gearshape.fill",
                    size: 20,
                    color: .gray
                ).navigateOnTap(destination: EditProfile(
                    loggedInUserPostData: loggedInUserPostData,
                    externalMessengers: externalMessengers,
                    notificationBannerViewStore: notificationBannerViewStore
                ))
            }
        }
    }
}
