//
//  Login.swift
//  build_app_source
//
//  Created by Matthew Dornfeld on 12/24/22.
//

import ComposableArchitecture
import Foundation
import SwiftUI

struct LoginReducer: ReducerProtocol {
    let externalMessengers: ExternalMessengers
    let emailOrPhoneTextFieldViewStore: PulpFictionViewStore<PulpFictionTextFieldReducer>
    let passwordTextFieldViewStore: PulpFictionViewStore<PulpFictionTextFieldReducer>
    let notificationBannerViewStore: NotificationnotificationBannerViewStore
    let bottomNavigationBarNavigationLinkViewStore: EmptyNavigationLinkViewStore
    var backendMessenger: BackendMessenger { externalMessengers.backendMessenger }

    struct State: Equatable {}
    enum Action: Equatable {
        case createLoginSession
        case processCreateLoginSessionResponse(PulpFictionRequestEither<CreateLoginSessionResponse>)
    }

    func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
        switch action {
        case .createLoginSession:
            if emailOrPhoneTextFieldViewStore.text.contains("@") {
                return .task {
                    let createLoginSessionResponseEither = await backendMessenger.createLoginSessionBackendMessenger.createLoginSession(
                        email: emailOrPhoneTextFieldViewStore.text,
                        password: passwordTextFieldViewStore.text
                    )
                    return .processCreateLoginSessionResponse(createLoginSessionResponseEither)
                }
            } else {
                return .task {
                    let createLoginSessionResponseEither = await backendMessenger.createLoginSessionBackendMessenger.createLoginSession(
                        phoneNumber: emailOrPhoneTextFieldViewStore.text,
                        password: passwordTextFieldViewStore.text
                    )
                    return .processCreateLoginSessionResponse(createLoginSessionResponseEither)
                }
            }

        case let .processCreateLoginSessionResponse(createLoginSessionResponseEither):
            createLoginSessionResponseEither
                .processResponseFromServer(
                    notificationBannerViewStore: notificationBannerViewStore,
                    state: state,
                    path: CreateLogginSessionBackendMessenger.BackendPath.createLoginSession.rawValue
                )

            switch createLoginSessionResponseEither.toEnum() {
            case .left:
                return .none
            case .right:
                notificationBannerViewStore.send(.showNotificationBanner("Successfully logged in!", .success))
                bottomNavigationBarNavigationLinkViewStore.send(.navigateToDestionationView())
            }
            return .none
        }
    }
}

struct Login: View {
    let externalMessengers: ExternalMessengers
    let notificationBannerViewStore: NotificationnotificationBannerViewStore

    private let emailOrPhoneTextField: PulpFictionTextField = .init(prompt: "Email or Phone")
    private let passwordTextField: PulpFictionTextField = .init(
        prompt: "Password",
        textFieldType: .secure
    )

    var reducer: LoginReducer {
        .init(
            externalMessengers: externalMessengers,
            emailOrPhoneTextFieldViewStore: emailOrPhoneTextField.viewStore,
            passwordTextFieldViewStore: passwordTextField.viewStore,
            notificationBannerViewStore: notificationBannerViewStore,
            bottomNavigationBarNavigationLinkViewStore: bottomNavigationBarNavigationLink.viewStore
        )
    }

    @ObservedObject private var bottomNavigationBarNavigationLink: EmptyNavigationLink<BottomNavigationBarView>
    private var store: PulpFictionStore<LoginReducer> {
        .init(
            initialState: .init(),
            reducer: reducer
        )
    }

    init(
        externalMessengers: ExternalMessengers,
        notificationBannerViewStore: NotificationnotificationBannerViewStore
    ) {
        self.externalMessengers = externalMessengers
        self.notificationBannerViewStore = notificationBannerViewStore
        bottomNavigationBarNavigationLink = .init {
            .init(
                loggedInUserPostData: externalMessengers.loginSession.loggedInUserPostData,
                postFeedMessenger: externalMessengers.postFeedMessenger,
                backendMessenger: externalMessengers.backendMessenger,
                notificationBannerViewStore: notificationBannerViewStore
            )
        }
    }

    var body: some View {
        WithViewStore(store) { viewStore in
            VStack {
                bottomNavigationBarNavigationLink.view
                VStack {
                    emailOrPhoneTextField
                    passwordTextField
                }
                Button(action: { viewStore.send(.createLoginSession) }) {
                    HeadlineText(
                        text: "LOGIN",
                        alignment: .center,
                        color: .white
                    )
                    .padding()
                    .frame(width: 220, height: 60)
                    .background(.orange)
                    .cornerRadius(15.0)
                }
            }
            .padding()
        }
    }
}
