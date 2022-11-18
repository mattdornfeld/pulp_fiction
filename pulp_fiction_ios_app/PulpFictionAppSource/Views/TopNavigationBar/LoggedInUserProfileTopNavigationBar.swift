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
                    postFeedMessenger: postFeedMessenger
                ))

                Symbol(
                    symbolName: "gearshape.fill",
                    size: 20,
                    color: .gray
                ).navigateOnTap(destination: EditProfileView(
                    loggedInUserPostData: loggedInUserPostData
                ))
            }
        }
    }
}
