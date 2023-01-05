//
//  Login.swift
//  build_app_source
//
//  Created by Matthew Dornfeld on 12/24/22.
//

import Bow
import ComposableArchitecture
import Foundation
import SwiftUI

struct LoginReducer: ReducerProtocol {
    let externalMessengers: ExternalMessengers
    let emailOrPhoneTextFieldViewStore: PulpFictionTextFieldViewStore
    let passwordTextFieldViewStore: PulpFictionTextFieldViewStore
    let notificationBannerViewStore: NotificationnotificationBannerViewStore
    let bottomNavigationBarNavigationLinkViewStore: EmptyNavigationLinkViewStore
    var backendMessenger: BackendMessenger { externalMessengers.backendMessenger }

    struct State: Equatable {}
    enum Action: Equatable {
        case createLoginSession
        case processCreateLoginSessionResponse(PulpFictionRequestEither<CreateLoginSessionResponse>)
    }

    class UnrecognizedCreateLoginSessionResponse: PulpFictionRequestError {}

    func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
        switch action {
        case .createLoginSession:
            if emailOrPhoneTextFieldViewStore.text.isValidEmail() {
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
                .flatMap { (createLoginSessionResponse: CreateLoginSessionResponse) -> Either<PulpFictionRequestError, CreateLoginSessionResponse> in
                    switch createLoginSessionResponse.createLoginSessionResponse {
                    case .loginSession:
                        notificationBannerViewStore.send(.showNotificationBanner("Successfully logged in!", .success))
                        bottomNavigationBarNavigationLinkViewStore.send(.navigateToDestionationView())
                        return .right(createLoginSessionResponse)
                    case .invalidEmail:
                        notificationBannerViewStore.send(.showNotificationBanner("Invalid email", .error))
                        return .right(createLoginSessionResponse)
                    case .invalidPhoneNumber:
                        notificationBannerViewStore.send(.showNotificationBanner("Invalid phone number", .error))
                        return .right(createLoginSessionResponse)
                    case .invalidPassword:
                        notificationBannerViewStore.send(.showNotificationBanner("Invalid password", .error))
                        return .right(createLoginSessionResponse)
                    case .none:
                        return .left(UnrecognizedCreateLoginSessionResponse())
                    }
                }^
                .processResponseFromServer(
                    notificationBannerViewStore: notificationBannerViewStore,
                    state: state,
                    path: CreateLogginSessionBackendMessenger.BackendPath.createLoginSession.rawValue
                )

            return .none
        }
    }
}

struct Login: PulpFictionView {
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
                externalMessengers: externalMessengers,
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
                PulpFictionButton(
                    text: "LOGIN",
                    backgroundColor: .orange
                ) { viewStore.send(.createLoginSession) }
            }
            .padding()
        }
    }
}
