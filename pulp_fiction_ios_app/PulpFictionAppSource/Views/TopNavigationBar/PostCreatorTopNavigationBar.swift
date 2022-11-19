//
//  PostCreatorViewTopNavigationBar.swift
//  build_app_source
//
//  Created by Matthew Dornfeld on 11/8/22.
//

import ComposableArchitecture
import Foundation
import SwiftUI

/// Reducer for PostCreatorTopNavigationBar
struct PostCreatorTopNavigationBarReducer: ReducerProtocol {
    struct State: Equatable {
        /// If true will load CaptionCreatorView
        var shouldLoadCaptionCreatorView: Bool = false
    }

    enum Action {
        /// Updates shouldLoadCaptionCreatorView
        case updateShouldLoadCaptionCreatorView(Bool, () -> UIImage?)
    }

    func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
        switch action {
        /// Updates shouldLoadCaptionCreatorView. Does nothing if uiImageMaybeSupplier returns nil.
        case let .updateShouldLoadCaptionCreatorView(newShouldLoadPostCreatorView, uiImageMaybeSupplier):
            if uiImageMaybeSupplier() != nil {
                state.shouldLoadCaptionCreatorView = newShouldLoadPostCreatorView
            }

            return .none
        }
    }
}

/// Navigation bar for the PostCreatorView
struct PostCreatorTopNavigationBar: ToolbarContent {
    /// The currently selected image source type for the drop down menu
    let currentImageSourceType: ImageSourceType
    /// Supplies the currently selected image
    let uiImageMaybeSupplier: () -> UIImage?
    /// UserPostData for the currently logged in user
    let loggedInUserPostData: UserPostData
    /// The post feed messenger
    let postFeedMessenger: PostFeedMessenger
    @ObservedObject private var viewStore: ViewStore<PostCreatorTopNavigationBarReducer.State, PostCreatorTopNavigationBarReducer.Action> = {
        let store = Store(
            initialState: PostCreatorTopNavigationBarReducer.State(),
            reducer: PostCreatorTopNavigationBarReducer()
        )

        return ViewStore(store)
    }()

    var body: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Title("Create Post")
                .foregroundColor(.gray)
        }

        ToolbarItem(placement: .navigationBarTrailing) {
            HStack {
                SymbolWithDropDownMenu(
                    symbolName: "line.3.horizontal.decrease.circle",
                    symbolSize: 20,
                    symbolColor: .gray,
                    menuOptions: ImageSourceType.allCases,
                    initialMenuSelection: currentImageSourceType
                )

                Symbol(symbolName: "arrow.right", size: 20, color: .gray)
                    .navigateOnTap(
                        isActive: viewStore.binding(
                            get: { $0.shouldLoadCaptionCreatorView },
                            send: .updateShouldLoadCaptionCreatorView(false, uiImageMaybeSupplier)
                        ),
                        destination: CaptionCreatorView(
                            loggedInUserPostData: loggedInUserPostData,
                            postFeedMessenger: postFeedMessenger,
                            uiImageMaybeSupplier: uiImageMaybeSupplier
                        )
                    ) {
                        viewStore.send(.updateShouldLoadCaptionCreatorView(true, uiImageMaybeSupplier))
                    }
            }
        }
    }
}
