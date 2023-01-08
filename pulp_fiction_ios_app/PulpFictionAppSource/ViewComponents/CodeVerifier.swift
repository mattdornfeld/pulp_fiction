//
//  CodeVerifier.swift
//  build_app_source
//
//  Created by Matthew Dornfeld on 1/5/23.
//

import ComposableArchitecture
import Foundation
import SwiftUI

struct CodeVerifierReducer: PulpFictionReducerProtocol {
    let externalMessengers: ExternalMessengers
    let notificationBannerViewStore: NotificationnotificationBannerViewStore
    let contactVerificationProto: ContactVerificationProto

    struct State: Equatable {
        var navigateToLogin: EmptyNavigationLinkViewReducer.State = .init()
        var verificationCodeTextField: PulpFictionTextFieldReducer.State = .init()
    }

    enum Action: Equatable {
        case navigateToLogin(EmptyNavigationLinkViewReducer.Action)
        case updateVerificationCodeTextField(PulpFictionTextFieldReducer.Action)
        case showNotificationBanner(String, NotificationBannerReducer.BannerType)
        case submitVerificationCode
        case processUpdateUserResponse(PulpFictionRequestEither<UpdateUserResponse>)
    }

    var body: some ReducerProtocol<State, Action> {
        Scope(state: \.navigateToLogin, action: /Action.navigateToLogin) {
            EmptyNavigationLinkViewReducer()
        }

        Scope(state: \.verificationCodeTextField, action: /Action.updateVerificationCodeTextField) {
            PulpFictionTextFieldReducer()
        }

        Reduce { state, action in
            switch action {
            case .navigateToLogin, .updateVerificationCodeTextField:
                return .none

            case let .showNotificationBanner(bannerText, bannerType):
                notificationBannerViewStore.send(.showNotificationBanner(bannerText, bannerType))
                return .none

            case .submitVerificationCode:
                guard let verificationCode = Int32(state.verificationCodeTextField.text) else {
                    return .task { .showNotificationBanner("Please enter a valid verification code", .info) }
                }

                return .task {
                    let updateUserResponseEither = await backendMessenger.updateUserBackendMessenger.verifyContactInformation(
                        verificationCode: verificationCode,
                        contactVerificationProto: contactVerificationProto
                    )

                    return .processUpdateUserResponse(updateUserResponseEither)
                }

            case let .processUpdateUserResponse(updateUserResponseEither):
                updateUserResponseEither.processResponseFromServer(
                    notificationBannerViewStore: notificationBannerViewStore,
                    state: state,
                    path: UpdateUserBackendMessenger.BackendPath.verifyContactInformation.rawValue
                )

                switch updateUserResponseEither.toEnum() {
                case .left:
                    return .task { .showNotificationBanner("Sorry we do not recognize this code", .info) }
                case .right:
                    state.navigateToLogin.shouldLoadDestionationView = true
                    return .task {
                        .showNotificationBanner("Successfully verified contact info!", .success)
                    }
                }
            }
        }
    }
}

struct CodeVerifier: PulpFictionView {
    let externalMessengers: ExternalMessengers
    let notificationBannerViewStore: NotificationnotificationBannerViewStore
    let store: PulpFictionStore<CodeVerifierReducer>

    init(
        externalMessengers: ExternalMessengers,
        notificationBannerViewStore: NotificationnotificationBannerViewStore,
        contactVerificationProto: ContactVerificationProto
    ) {
        self.externalMessengers = externalMessengers
        self.notificationBannerViewStore = notificationBannerViewStore
        store = .init(
            initialState: CodeVerifierReducer.State(),
            reducer: CodeVerifierReducer(
                externalMessengers: externalMessengers,
                notificationBannerViewStore: notificationBannerViewStore,
                contactVerificationProto: contactVerificationProto
            )
        )
    }

    var body: some View {
        WithViewStore(store) { viewStore in
            VStack {
                EmptyNavigationLinkView(
                    store: store.scope(
                        state: \.navigateToLogin,
                        action: CodeVerifierReducer.Action.navigateToLogin
                    ),
                    hideBackButton: true
                ) {
                    Landing(
                        externalMessengers: externalMessengers,
                        notificationBannerViewStore: notificationBannerViewStore
                    )
                }

                BoldCaption(
                    text: "Please enter the verification code we sent to your phone or email.",
                    alignment: .center,
                    color: .gray
                )
                .frame(width: 225, height: 100)

                PulpFictionTextField(
                    prompt: "Verification Code",
                    textContentType: .oneTimeCode,
                    shouldLoadKeyboardOnAppear: true,
                    store: store.scope(
                        state: \.verificationCodeTextField,
                        action: CodeVerifierReducer.Action.updateVerificationCodeTextField
                    )
                )

                PulpFictionButton(
                    text: "SUBMIT CODE",
                    backgroundColor: .orange
                ) { viewStore.send(.submitVerificationCode) }
            }
        }
    }
}
