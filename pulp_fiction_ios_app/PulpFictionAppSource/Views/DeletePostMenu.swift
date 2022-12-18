//
//  DeletePostMenu.swift
//  build_app_source
//
//  Created by Matthew Dornfeld on 12/18/22.
//

import Bow
import ComposableArchitecture
import Foundation
import SwiftUI

struct DeletePostMenuReducer: ReducerProtocol {
    let postMetadata: PostMetadata
    let backendMessenger: BackendMessenger
    let extraOptionsDropDownMenuViewStore: PulpFictionViewStore<ExtraOptionsDropDownMenuReducer>
    let notificationBannerViewStore: NotificationnotificationBannerViewStore

    struct State: Equatable {}

    enum Action: Equatable {
        case deletePost
        case processUpdatePostResponse(Either<PulpFictionRequestError, UpdatePostResponse>)
    }

    func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
        switch action {
        case .deletePost:
            return .task {
                let updatePostResponseEither = await backendMessenger.deletePost(postId: postMetadata.postUpdateIdentifier.postId)
                return .processUpdatePostResponse(updatePostResponseEither)
            }
        case let .processUpdatePostResponse(updatePostResponseEither):
            updatePostResponseEither.processResponseFromServer(
                notificationBannerViewStore: notificationBannerViewStore,
                state: state,
                successAction: { notificationBannerViewStore.send(.showNotificationBanner("Your post has been deleted", .info)) }
            )
            extraOptionsDropDownMenuViewStore.send(.updateShowShowDeletePostMenu(false))
            return .none
        }
    }
}

/// View for selecting whether or not to delete a post
struct DeletePostMenu: View {
    let extraOptionsDropDownMenuViewStore: PulpFictionViewStore<ExtraOptionsDropDownMenuReducer>
    private let store: PulpFictionStore<DeletePostMenuReducer>

    init(
        postMetadata: PostMetadata,
        extraOptionsDropDownMenuViewStore: PulpFictionViewStore<ExtraOptionsDropDownMenuReducer>,
        backendMessenger: BackendMessenger,
        notificationBannerViewStore: NotificationnotificationBannerViewStore
    ) {
        self.extraOptionsDropDownMenuViewStore = extraOptionsDropDownMenuViewStore
        store = .init(
            initialState: .init(),
            reducer: DeletePostMenuReducer(
                postMetadata: postMetadata,
                backendMessenger: backendMessenger,
                extraOptionsDropDownMenuViewStore: extraOptionsDropDownMenuViewStore,
                notificationBannerViewStore: notificationBannerViewStore
            )
        )
    }

    var body: some View {
        WithViewStore(store) { viewStore in
            VStack {
                MenuButton(text: "Delete", backgroundColor: .blue) {
                    viewStore.send(.deletePost)
                }
                MenuButton(text: "Cancel", backgroundColor: .orange) {
                    extraOptionsDropDownMenuViewStore.send(.updateShowShowDeletePostMenu(false))
                }
            }
        }
    }
}
