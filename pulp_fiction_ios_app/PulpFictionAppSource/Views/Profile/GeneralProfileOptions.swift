//
//  GeneralProfileOptions.swift
//  build_app_source
//
//  Created by Matthew Dornfeld on 12/25/22.
//

import Bow
import ComposableArchitecture
import Foundation
import SwiftUI

struct GeneralProfileOptionsReducer: PulpFictionReducerProtocol {
    let externalMessengers: ExternalMessengers
    let notificationBannerViewStore: NotificationnotificationBannerViewStore
    let landingNavigationLinkViewStore: EmptyNavigationLinkViewStore

    struct State: Equatable {}

    enum BannerMessage: String {
        case logout = "Successfully logged out"
    }

    enum Action: Equatable {
        case logout
        case processUpdateLoginSessionResponse(
            Either<PulpFictionRequestError, UpdateLoginSessionResponse>,
            BackendPath,
            BannerMessage,
            EquatableWrapper<(UpdateLoginSessionResponse, State) -> Void>
        )
    }

    func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
        switch action {
        case .logout:
            return .task {
                let updateLoginSessionResponseEither = await backendMessenger.updateLoginSessionBackendMessenger.logout()
                return .processUpdateLoginSessionResponse(
                    updateLoginSessionResponseEither,
                    UpdateLogginSessionBackendMessenger.BackendPath.logout.rawValue,
                    .logout,
                    EquatableWrapper { _, _ in
                        landingNavigationLinkViewStore.send(.navigateToDestionationView())
                    }
                )
            }

        case let .processUpdateLoginSessionResponse(
            updateLoginSessionResponseEither,
            backendPath,
            bannerMessage,
            successfulResponseAction
        ):
            updateLoginSessionResponseEither
                .processResponseFromServer(
                    notificationBannerViewStore: notificationBannerViewStore,
                    state: state,
                    path: backendPath
                )

            switch updateLoginSessionResponseEither.toEnum() {
            case .left:
                return .none
            case let .right(updateLoginSessionResponse):
                notificationBannerViewStore.send(.showNotificationBanner(bannerMessage.rawValue, .info))
                successfulResponseAction.wrapped(updateLoginSessionResponse, state)
                return .none
            }
        }
    }
}

/// Edit and display private profile data
struct GeneralProfileOptions: PulpFictionView {
    let externalMessengers: ExternalMessengers
    let notificationBannerViewStore: NotificationnotificationBannerViewStore
    private let landingNavigationLink: EmptyNavigationLink<Landing>
    @ObservedObject private var viewStore: PulpFictionViewStore<GeneralProfileOptionsReducer>

    init(
        externalMessengers: ExternalMessengers,
        notificationBannerViewStore: NotificationnotificationBannerViewStore
    ) {
        self.externalMessengers = externalMessengers
        self.notificationBannerViewStore = notificationBannerViewStore
        landingNavigationLink = .init(hideBackButton: true) {
            .init(
                externalMessengers: externalMessengers,
                notificationBannerViewStore: notificationBannerViewStore
            )
        }
        viewStore = .init(
            initialState: .init(),
            reducer: GeneralProfileOptionsReducer(
                externalMessengers: externalMessengers,
                notificationBannerViewStore: notificationBannerViewStore,
                landingNavigationLinkViewStore: landingNavigationLink.viewStore
            )
        )
    }

    var body: some View {
        VStack {
            landingNavigationLink.view
            Spacer()
            Button("Logout") {
                viewStore.send(.logout)
            }
            .padding()
            .foregroundColor(.white)
            .background(.blue)

            Button("Change Password") {
                print("Change Password")
            }
            .padding()
            .foregroundColor(.white)
            .background(.blue)
            Spacer()
        }
    }
}
