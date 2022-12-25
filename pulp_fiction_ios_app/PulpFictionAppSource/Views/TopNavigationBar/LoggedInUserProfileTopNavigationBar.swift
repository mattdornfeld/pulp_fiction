//
//  LoggedInUserProfileTopNavigationBar.swift
//  build_app_source
//
//  Created by Matthew Dornfeld on 10/23/22.
//

import ComposableArchitecture
import Foundation
import SwiftUI

struct LoggedInUserProfileTopNavigationBar: ToolbarContent {
    let loggedInUserPostData: UserPostData
    let postFeedMessenger: PostFeedMessenger
    let backendMessenger: BackendMessenger
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
                    postFeedMessenger: postFeedMessenger,
                    backendMessenger: backendMessenger,
                    notificationBannerViewStore: notificationBannerViewStore
                ))

                Symbol(
                    symbolName: "gearshape.fill",
                    size: 20,
                    color: .gray
                ).navigateOnTap(destination: EditProfile(
                    loggedInUserPostData: loggedInUserPostData,
                    backendMessenger: backendMessenger,
                    notificationBannerViewStore: notificationBannerViewStore
                ))
            }
        }
    }
}
