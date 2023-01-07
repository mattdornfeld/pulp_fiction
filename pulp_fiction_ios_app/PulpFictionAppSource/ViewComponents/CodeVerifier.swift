//
//  CodeVerifier.swift
//  build_app_source
//
//  Created by Matthew Dornfeld on 1/5/23.
//

import ComposableArchitecture
import Foundation
import SwiftUI

struct CodeVerifierReducer: ReducerProtocol {
    let externalMessengers: ExternalMessengers
    let notificationBannerViewStore: NotificationnotificationBannerViewStore

    struct State: Equatable {
        var verificationCodeTextField: PulpFictionTextFieldReducer.State = .init()
    }

    enum Action: Equatable {
        case updateVerificationCodeTextField(PulpFictionTextFieldReducer.Action)
        case submitVerificationCode
    }

    var body: some ReducerProtocol<State, Action> {
        Scope(state: \.verificationCodeTextField, action: /Action.updateVerificationCodeTextField) {
            PulpFictionTextFieldReducer()
        }

        Reduce { _, action in
            switch action {
            case .updateVerificationCodeTextField:
                return .none
            case .submitVerificationCode:
                notificationBannerViewStore.send(.showNotificationBanner(
                    "Successfully verified contact info!",
                    .success
                ))
                return .none
            }
        }
    }
}

struct CodeVerifier: PulpFictionView {
    let externalMessengers: ExternalMessengers
    let notificationBannerViewStore: NotificationnotificationBannerViewStore
    let store: PulpFictionStore<CodeVerifierReducer>

    init(externalMessengers: ExternalMessengers, notificationBannerViewStore: NotificationnotificationBannerViewStore) {
        self.externalMessengers = externalMessengers
        self.notificationBannerViewStore = notificationBannerViewStore
        store = .init(
            initialState: CodeVerifierReducer.State(),
            reducer: CodeVerifierReducer(
                externalMessengers: externalMessengers,
                notificationBannerViewStore: notificationBannerViewStore
            )
        )
    }

    var body: some View {
        WithViewStore(store) { viewStore in
            VStack {
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
