//
//  CaptionCreatorView.swift
//  build_app_source
//
//  Created by Matthew Dornfeld on 11/14/22.
//

import ComposableArchitecture
import Foundation
import SwiftUI

/// Reducer for CaptionCreatorView
struct CaptionCreatorReducer: ReducerProtocol {
    let uiImageMaybeSupplier: () -> UIImage?
    private let maxCaptionSize: Int = 100

    struct State: Equatable {
        /// Caption being created
        var caption: String = ""
        /// Set to true when post is created and will navigate to logged in UserProfileView
        var shouldLoadLoggedInUserProfileView: Bool = false
    }

    enum Action {
        /// Updates the comment as new characters are typed
        case updateCaption(String)
        /// Posts the image + caption
        case createPost
        case updateShouldLoadLoggedInUserProfileView(Bool)
    }

    func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
        switch action {
        case let .updateCaption(newComment):
            state.caption = String(newComment.prefix(maxCaptionSize))
            return .none

        case .createPost:
            if state.caption.count == 0 {
                return .none
            }

            if let uiImage = uiImageMaybeSupplier() {
                print("Creating post")
                print("caption: \(state.caption)")
                print("image: \(uiImage)")
            }

            return .task { .updateShouldLoadLoggedInUserProfileView(true) }

        case let .updateShouldLoadLoggedInUserProfileView(newShouldLoadLoggedInUserProfileView):
            state.shouldLoadLoggedInUserProfileView = newShouldLoadLoggedInUserProfileView
            return .none
        }
    }
}

/// View for creating and posting images + captions
struct CaptionCreatorView: View {
    let loggedInUserPostData: UserPostData
    let postFeedMessenger: PostFeedMessenger
    private let store: ComposableArchitecture.StoreOf<CaptionCreatorReducer>
    @FocusState private var isInputCaptionFieldFocused: Bool

    init(
        loggedInUserPostData: UserPostData,
        postFeedMessenger: PostFeedMessenger,
        uiImageMaybeSupplier: @escaping () -> UIImage?
    ) {
        self.loggedInUserPostData = loggedInUserPostData
        self.postFeedMessenger = postFeedMessenger
        store = Store(
            initialState: CaptionCreatorReducer.State(),
            reducer: CaptionCreatorReducer(uiImageMaybeSupplier: uiImageMaybeSupplier)
        )
    }

    var body: some View {
        WithViewStore(store) { viewStore in
            VStack {
                TextField(
                    "Write a caption",
                    text: viewStore.binding(
                        get: \.caption,
                        send: { newCaption in .updateCaption(newCaption) }
                    ),
                    prompt: Text("Write a caption")
                )
                .foregroundColor(.gray)
                .focused($isInputCaptionFieldFocused)
                Spacer()
                NavigationLink(
                    destination:
                    BottomNavigationBarView(
                        loggedInUserPostData: loggedInUserPostData,
                        postFeedMessenger: postFeedMessenger,
                        currentMainView: .loggedInUserProfileView
                    ).navigationBarBackButtonHidden(true),
                    isActive: viewStore.binding(
                        get: \.shouldLoadLoggedInUserProfileView,
                        send: .updateShouldLoadLoggedInUserProfileView(false)
                    )
                ) { EmptyView() }
            }
            .onAppear {
                isInputCaptionFieldFocused = true
            }
            .toolbar {
                TextCreatorTopNavigationBar(tapPostButtonAction: {
                    viewStore.send(.createPost)
                })
            }
        }
    }
}
