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
    let loggedInUserPostData: UserPostData
    let postFeedMessenger: PostFeedMessenger

    var body: some View {
        UserProfileScrollView(
            userPostData: loggedInUserPostData,
            postFeedMessenger: postFeedMessenger
        ) {
            VStack {
                HStack {
                    CircularImage(
                        uiImage: loggedInUserPostData.userAvatarUIImage,
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
                Caption(text: loggedInUserPostData.bio, alignment: .center)
                    .foregroundColor(.gray)
                    .padding()
            }
        }
    }
}
