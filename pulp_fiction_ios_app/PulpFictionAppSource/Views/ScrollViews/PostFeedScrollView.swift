//
//  PostFeedScrollView.swift
//  build_app_source
//
//  Created by Matthew Dornfeld on 10/23/22.
//

import ComposableArchitecture
import Foundation
import SwiftUI

enum PostFeedFilter: String, DropDownMenuOption {
    case Global
    case Following
}

struct PostFeedScrollReducer: ReducerProtocol {
    struct State: Equatable {
        var currentPostFeedFilter: PostFeedFilter = .Global
    }

    enum Action {
        case updateCurrentPostFeedFilter(PostFeedFilter)
    }

    func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
        switch action {
        case let .updateCurrentPostFeedFilter(newPostFeedFilter):
            state.currentPostFeedFilter = newPostFeedFilter
            return .none
        }
    }
}

/// View that scrolls through a feed of posts
struct PostFeedScrollView: View {
    let loggedInUserPostData: UserPostData
    let postFeedMessenger: PostFeedMessenger
    private let store: ComposableArchitecture.StoreOf<PostFeedScrollReducer> = Store(
        initialState: PostFeedScrollReducer.State(),
        reducer: PostFeedScrollReducer()
    )

//    var body: some View {
//        WithViewStore(store) { viewStore in
//            TopNavigationBarView(topNavigationBarViewBuilder: { PostFeedTopNavigationBar(
//                postFeedFilter: viewStore.state.currentPostFeedFilter)
//            { newPostFeedFilter in
//                viewStore.send(.updateCurrentPostFeedFilter(newPostFeedFilter))
//            }
//            }) {
//                ContentScrollView(postFeedMessenger: postFeedMessenger) { () -> PostViewFeedIterator<ImagePostView> in
//                    getPostFeed(viewStore.state.currentPostFeedFilter)
//                        .makeIterator()
//                }
//            }
//        }
//    }
    
    var body: some View {
        WithViewStore(store) { viewStore in
            ContentScrollView(postFeedMessenger: postFeedMessenger) { () -> PostViewFeedIterator<ImagePostView> in
                getPostFeed(viewStore.state.currentPostFeedFilter)
                    .makeIterator()
            }
            .toolbar{
                PostFeedTopNavigationBar(
                    postFeedFilter: viewStore.state.currentPostFeedFilter,
                    dropDownMenuSelectionAction: { newPostFeedFilter in
                        viewStore.send(.updateCurrentPostFeedFilter(newPostFeedFilter))
                    }
                )
            }
        }
    }

    func getPostFeed(_ postFeedFilter: PostFeedFilter) -> PostViewFeed<ImagePostView> {
        switch postFeedFilter {
        case .Global:
            return postFeedMessenger
                .getGlobalPostFeed()
        case .Following:
            return postFeedMessenger
                .getFollowingPostFeed(userId: loggedInUserPostData.userId)
        }
    }
}
