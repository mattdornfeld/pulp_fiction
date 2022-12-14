//
//  UserProfileTopNavigationBar.swift
//  build_app_source
//
//  Created by Matthew Dornfeld on 11/15/22.
//

import Foundation
import SwiftUI

struct UserProfileTopNavigationBar: ToolbarContent {
    let userProfileOwnerPostData: UserPostData
    let postFeedMessenger: PostFeedMessenger

    var body: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Title(userProfileOwnerPostData.userDisplayName)
                .foregroundColor(.gray)
        }
    }
}
