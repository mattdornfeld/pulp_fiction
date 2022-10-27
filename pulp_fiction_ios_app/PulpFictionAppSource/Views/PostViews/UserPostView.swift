//
//  UserPostView.swift
//  build_app_source
//
//  Created by Matthew Dornfeld on 10/22/22.
//

import ComposableArchitecture
import Foundation
import SwiftUI

struct UserPostViewReducer: ReducerProtocol {
    struct State: Equatable {
        var shouldLoadUserProfileView: Bool = false
    }

    enum Action {
        case updateShouldLoadUserProfileView(Bool)
    }

    func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
        switch action {
        case let .updateShouldLoadUserProfileView(newShouldLoadUserProfileView):
            state.shouldLoadUserProfileView = newShouldLoadUserProfileView
            return .none
        }
    }
}

struct UserPostView: View {
    let userPostData: UserPostData
    let postFeedMessenger: PostFeedMessenger
    private let store: ComposableArchitecture.StoreOf<UserPostViewReducer> = Store(
        initialState: UserPostViewReducer.State(),
        reducer: UserPostViewReducer()
    )

    static func == (lhs: UserPostView, rhs: UserPostView) -> Bool {
        lhs.userPostData == rhs.userPostData
    }

    var body: some View {
        WithViewStore(store) { viewStore in
            HStack {
                CircularImage(
                    uiImage: userPostData.userAvatarUIImage,
                    radius: 15,
                    borderColor: .red,
                    borderWidth: 1
                ).padding(.leading, 5)
                BoldCaption(userPostData.userDisplayName)
                    .foregroundColor(.black)
            }
            .navigateOnTap(
                isActive: viewStore.binding(
                    get: \.shouldLoadUserProfileView,
                    send: .updateShouldLoadUserProfileView(false)
                ),
                destination: UserProfileView(
                    loggedInUserPostData: userPostData,
                    postFeedMessenger: postFeedMessenger
                )
            ) {
                viewStore.send(.updateShouldLoadUserProfileView(true))
            }
        }
    }
}
