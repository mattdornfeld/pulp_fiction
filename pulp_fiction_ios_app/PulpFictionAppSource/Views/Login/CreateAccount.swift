//
//  CreateAccount.swift
//  PulpFictionApp
//
//  Created by Matthew Dornfeld on 12/31/22.
//

import ComposableArchitecture
import Foundation
import SwiftUI

enum ContactVerification: String, DropDownMenuOption {
    case Phone
    case Email
}

typealias ContactVerificationDropDownMenuReducer = ViewWithDropDownMenuReducer<ContactVerification>
typealias ContactVerificationDropDownMenuView = SymbolWithDropDownMenuView<ContactVerification>

struct CreateAccountReducer: ReducerProtocol {
    let externalMessengers: ExternalMessengers
    let notificationBannerViewStore: NotificationnotificationBannerViewStore
    var createUserBackendMessenger: CreateUserBackendMessenger { externalMessengers.backendMessenger.createUserBackendMessenger }

    struct State: Equatable {
        var contactVerification: ContactVerificationDropDownMenuReducer.State = .init(currentSelection: .Phone)
        var phone: PulpFictionTextFieldReducer.State = .init()
        var email: PulpFictionTextFieldReducer.State = .init()
        var password: PulpFictionTextFieldReducer.State = .init()
        var passwordConfirmation: PulpFictionTextFieldReducer.State = .init()
    }

    enum Action: Equatable {
        case contactVerification(ContactVerificationDropDownMenuReducer.Action)
        case phone(PulpFictionTextFieldReducer.Action)
        case email(PulpFictionTextFieldReducer.Action)
        case password(PulpFictionTextFieldReducer.Action)
        case passwordConfirmation(PulpFictionTextFieldReducer.Action)
        case createUser
        case processCreateUserResponse(PulpFictionRequestEither<CreateUserResponse>)
        case showNotificationBanner(String, NotificationBannerReducer.BannerType)
    }

    var body: some ReducerProtocol<State, Action> {
        Scope(state: \.contactVerification, action: /Action.contactVerification) {
            ContactVerificationDropDownMenuReducer()
        }
        Scope(state: \.phone, action: /Action.phone) {
            PulpFictionTextFieldReducer()
        }
        Scope(state: \.email, action: /Action.email) {
            PulpFictionTextFieldReducer()
        }
        Scope(state: \.password, action: /Action.password) {
            PulpFictionTextFieldReducer()
        }
        Scope(state: \.passwordConfirmation, action: /Action.passwordConfirmation) {
            PulpFictionTextFieldReducer()
        }

        Reduce { state, action in
            switch action {
            case .contactVerification, .phone, .email, .password, .passwordConfirmation:
                return .none

            case .createUser:
                let currentSelection = state.contactVerification.currentSelection
                let phone = state.phone.text
                let email = state.email.text
                let passwordText = state.password.text
                let passwordConfirmationText = state.passwordConfirmation.text

                return .task {
                    switch currentSelection {
                    case .Phone where !phone.isValidPhoneNumber():
                        return .showNotificationBanner("Please enter a valid phone number", .info)

                    case .Email where !email.isValidEmail():
                        return .showNotificationBanner("Please enter a valid email", .info)

                    case .Phone:
                        let createUserResponseEither = await createUserBackendMessenger.createUser(
                            phoneNumber: phone,
                            password: passwordText,
                            passwordConfirmation: passwordConfirmationText
                        )
                        return .processCreateUserResponse(createUserResponseEither)
                    case .Email:
                        let createUserResponseEither = await createUserBackendMessenger.createUser(
                            email: email,
                            password: passwordText,
                            passwordConfirmation: passwordConfirmationText
                        )
                        return .processCreateUserResponse(createUserResponseEither)
                    }
                }

            case let .processCreateUserResponse(createUserResponseEither):
                return .none

            case let .showNotificationBanner(bannerText, bannerType):
                notificationBannerViewStore.send(.showNotificationBanner(bannerText, bannerType))
                return .none
            }
        }
    }
}

private struct CaptionAndStatus: View {
    let text: String
    let statusSupplier: () -> Status

    enum Status {
        case empty
        case invalid
        case valid
    }

    var body: some View {
        HStack {
            Caption(text: text, color: .gray)
            getStatusSymbol()
        }
    }

    @ViewBuilder private func getStatusSymbol() -> some View {
        switch statusSupplier() {
        case .empty:
            EmptyView()
        case .invalid:
            Image(systemName: "x.circle")
        case .valid:
            Image(systemName: "checkmark.circle")
        }
    }
}

struct CreateAccountTopNavigationBar: ToolbarContent {
    let store: PulpFictionStore<CreateAccountReducer>

    var body: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            HStack {
                ContactVerificationDropDownMenuView(
                    symbolName: "line.3.horizontal.decrease.circle",
                    symbolSize: 20,
                    symbolColor: .gray,
                    menuOptions: ContactVerification.allCases,
                    store: store.scope(
                        state: \.contactVerification,
                        action: CreateAccountReducer.Action.contactVerification
                    )
                )
            }
        }
    }
}

struct CreateAccount: View {
    let createAccountReducer: CreateAccountReducer
    private var store: PulpFictionStore<CreateAccountReducer>

    init(
        externalMessengers: ExternalMessengers,
        notificationBannerViewStore: NotificationnotificationBannerViewStore
    ) {
        createAccountReducer = .init(
            externalMessengers: externalMessengers,
            notificationBannerViewStore: notificationBannerViewStore
        )
        store = .init(
            initialState: .init(),
            reducer: createAccountReducer
        )
    }

    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            VStack {
                BoldCaption(
                    text: "We need your contact info. Tap the top right menu to switch between using your phone or email.",
                    alignment: .center,
                    color: .gray
                )
                .frame(width: 225, height: 100)

                buildContactVerificationInput(viewStore)

                PulpFictionTextField(
                    prompt: "Password",
                    textFieldType: .secure,
                    store: store.scope(
                        state: \.password,
                        action: CreateAccountReducer.Action.password
                    )
                ).padding([.horizontal])

                PulpFictionTextField(
                    prompt: "Confirm Password",
                    textFieldType: .secure,
                    store: store.scope(
                        state: \.passwordConfirmation,
                        action: CreateAccountReducer.Action.passwordConfirmation
                    )
                ).padding([.horizontal])

                PulpFictionButton(
                    text: "CREATE ACCOUNT",
                    backgroundColor: .orange
                ) { viewStore.send(.createUser) }

                buildContactVerificationCaptionAndStatus(viewStore)

                CaptionAndStatus(text: "Password has at least one upper case character") {
                    let text = viewStore.password.text
                    if text.count == 0 {
                        return .empty
                    } else if text.hasAtLeastOneUpperCaseCharacter() {
                        return .valid
                    } else {
                        return .invalid
                    }
                }

                CaptionAndStatus(text: "Password has at least one lower case character") {
                    let text = viewStore.password.text
                    if text.count == 0 {
                        return .empty
                    } else if text.hasAtLeastOneLowerCaseCharacter() {
                        return .valid
                    } else {
                        return .invalid
                    }
                }

                CaptionAndStatus(text: "Password has at least one special character") {
                    let text = viewStore.password.text
                    if text.count == 0 {
                        return .empty
                    } else if text.hasAtLeastOneSpecialCharacter() {
                        return .valid
                    } else {
                        return .invalid
                    }
                }

                CaptionAndStatus(text: "Password has at least 8 characters") {
                    let text = viewStore.password.text
                    if text.count == 0 {
                        return .empty
                    } else if text.hasAtLeastNCharacters(8) {
                        return .valid
                    } else {
                        return .invalid
                    }
                }
            }
        }
        .toolbar { CreateAccountTopNavigationBar(store: store) }
    }

    @ViewBuilder
    private func buildContactVerificationInput(_ viewStore: PulpFictionViewStore<CreateAccountReducer>) -> some View {
        switch viewStore.state.contactVerification.currentSelection {
        case .Phone:
            PulpFictionTextField(
                prompt: "Phone",
                store: store.scope(
                    state: \.phone,
                    action: CreateAccountReducer.Action.phone
                )
            ).padding([.horizontal])

        case .Email:
            PulpFictionTextField(
                prompt: "Email",
                store: store.scope(
                    state: \.email,
                    action: CreateAccountReducer.Action.email
                )
            ).padding([.horizontal])
        }
    }

    @ViewBuilder
    private func buildContactVerificationCaptionAndStatus(_ viewStore: PulpFictionViewStore<CreateAccountReducer>) -> some View {
        switch viewStore.state.contactVerification.currentSelection {
        case .Phone:
            CaptionAndStatus(text: "Valid phone number") {
                let text = viewStore.phone.text
                if text.count == 0 {
                    return .empty
                } else if text.isValidPhoneNumber() {
                    return .valid
                } else {
                    return .invalid
                }
            }

        case .Email:
            CaptionAndStatus(text: "Valid email") {
                let text = viewStore.email.text
                if text.count == 0 {
                    return .empty
                } else if text.isValidEmail() {
                    return .valid
                } else {
                    return .invalid
                }
            }
        }
    }
}
