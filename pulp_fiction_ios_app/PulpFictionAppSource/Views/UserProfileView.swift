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

// struct UserProfileViewReducer: ReducerProtocol {
//    struct State: Equatable {
//
//    }
//
//    enum Action {
//
//    }
//
//    func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
//        <#code#>
//    }
// }

struct UserProfileView: View {
    let userPostData: UserPostData
    let postFeedMessenger: PostFeedMessenger

    static func == (lhs: UserProfileView, rhs: UserProfileView) -> Bool {
        lhs.userPostData == rhs.userPostData
    }

    var body: some View {
        UserProfileScrollView(
            userId: userPostData.userId,
            postFeedMessenger: postFeedMessenger
        ) {
            VStack {
                HStack {
                    CircularImage(
                        uiImage: userPostData.userAvatarUIImage,
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
                Caption(text: userPostData.bio, alignment: .center)
                    .foregroundColor(.gray)
                    .padding()
            }
        }
    }
}
