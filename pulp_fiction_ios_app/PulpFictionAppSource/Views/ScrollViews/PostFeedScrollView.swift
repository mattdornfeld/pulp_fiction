//
//  PostFeedScrollView.swift
//  build_app_source
//
//  Created by Matthew Dornfeld on 10/23/22.
//

import ComposableArchitecture
import Foundation
import SwiftUI

// struct PostFeedScrollReducer: ReducerProtocol {
//    struct State: Equatable {
//        var topNavigationBarState: UserProfileTopNavigationBarReducer.State
//    }
//
//    enum Action {
//        case updateTopNavigationBarState
//    }
//
//    var body: some ReducerProtocol<State, Action> {
//        Scope(
//            state: \.topNavigationBarState,
//            action: /Action.updateViewComponents
//        ) {
//            PostFeedTopNavigationBarReducer()
//        }
//
//        Reduce { state, action in
//            switch action {
//            }
//        }
//    }
// }

/// View that scrolls through a feed of posts
struct PostFeedScrollView: View {
    let postFeedMessenger: PostFeedMessenger

    var body: some View {
        TopNavigationBarView(topNavigationBarViewBuilder: { PostFeedTopNavigationBar() }) {
            ContentScrollView(postFeedMessenger: postFeedMessenger) { () -> PostViewFeedIterator<ImagePostView> in
                postFeedMessenger
                    .getGlobalPostFeed()
                    .makeIterator()
            }
        }
    }
}
