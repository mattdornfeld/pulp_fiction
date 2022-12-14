//
//  UserPostView.swift
//  PulpFictionApp
//
//  Created by Matthew Dornfeld on 10/19/22.
//

import Bow
import ComposableArchitecture
import Foundation
import SwiftUI

/// Constructs a view for a users profile
struct UserProfileView: View {
    let userProfileOwnerPostData: UserPostData
    let loggedInUserPostData: UserPostData
    let postFeedMessenger: PostFeedMessenger
    let backendMessenger: BackendMessenger

    var body: some View {
        if userProfileOwnerPostData == loggedInUserPostData {
            LoggedInUserProfileScrollView(
                loggedInUserPostData: loggedInUserPostData,
                postFeedMessenger: postFeedMessenger,
                backendMessenger: backendMessenger
            ) { userProfileViewBuilder() }
        } else {
            UserProfileScrollView(
                userProfileOwnerPostData: userProfileOwnerPostData,
                postFeedMessenger: postFeedMessenger,
                backendMessenger: backendMessenger
            ) { userProfileViewBuilder() }
        }
    }

    @ViewBuilder private func userProfileViewBuilder() -> some View {
        VStack {
            HStack {
                CircularImage(
                    uiImage: userProfileOwnerPostData.userAvatarUIImage,
                    radius: 35,
                    borderColor: .gray,
                    borderWidth: 1
                ).padding(.leading, 5)
                Spacer()
                BoldCaption(text: "5\nPosts", alignment: .center)
                    .foregroundColor(.gray)
                    .padding(5)
                BoldCaption(text: "15\nComments", alignment: .center)
                    .foregroundColor(.gray)
                    .padding(5)
                BoldCaption(text: "1000\nReputation", alignment: .center)
                    .foregroundColor(.gray)
                    .padding(5)
            }
            Caption(
                text: loggedInUserPostData.bio,
                alignment: .center,
                color: .gray
            )
            .padding()
        }
    }
}
