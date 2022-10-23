//
//  UserConnectionView.swift
//  build_app_source
//
//  Created by Matthew Dornfeld on 10/22/22.
//

import Foundation
import SwiftUI

/// Constructs a view that shows a users connection with another user (e.g. a follower or a followee)
struct UserConnectionView: ScrollableContentView {
    let id: Int
    let userPostData: UserPostData
    let postFeedMessenger: PostFeedMessenger

    static func == (lhs: UserConnectionView, rhs: UserConnectionView) -> Bool {
        lhs.id == rhs.id
            && lhs.userPostData == rhs.userPostData
    }

    var body: some View {
        HStack {
            UserPostView(
                userPostData: userPostData,
                postFeedMessenger: postFeedMessenger
            )
            Spacer()
            Caption("Following")
                .padding()
                .foregroundColor(.white)
                .background(.orange)
        }
    }
}
