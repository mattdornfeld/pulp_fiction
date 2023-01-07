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
        var navigateToVerifyContact: EmptyNavigationLinkViewReducer.State = .init()
        var contactVerification: ContactVerificationDropDownMenuReducer.State = .init(currentSelection: .Phone)
        var phone: PhoneNumberFieldReducer.State = .init()
        var email: PulpFictionTextFieldReducer.State = .init()
        var password: PulpFictionTextFieldReducer.State = .init()
        var passwordConfirmation: PulpFictionTextFieldReducer.State = .init()
    }

    enum Action: Equatable {
        case navigateToVerifyContact(EmptyNavigationLinkViewReducer.Action)
        case contactVerification(ContactVerificationDropDownMenuReducer.Action)
        case phone(PhoneNumberFieldReducer.Action)
        case email(PulpFictionTextFieldReducer.Action)
        case password(PulpFictionTextFieldReducer.Action)
        case passwordConfirmation(PulpFictionTextFieldReducer.Action)
        case createUser
        case processCreateUserResponse(PulpFictionRequestEither<CreateUserResponse>)
        case showNotificationBanner(String, NotificationBannerReducer.BannerType)
    }

    var body: some ReducerProtocol<State, Action> {
        Scope(state: \.navigateToVerifyContact, action: /Action.navigateToVerifyContact) {
            EmptyNavigationLinkViewReducer()
        }
        Scope(state: \.contactVerification, action: /Action.contactVerification) {
            ContactVerificationDropDownMenuReducer()
        }
        Scope(state: \.phone, action: /Action.phone) {
            PhoneNumberFieldReducer()
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
            case .navigateToVerifyContact, .contactVerification, .phone, .email, .password, .passwordConfirmation:
                return .none

            case .createUser:
                let currentSelection = state.contactVerification.currentSelection
                let phone = state.phone.phoneNumber
                let email = state.email.text
                let passwordText = state.password.text
                let passwordConfirmationText = state.passwordConfirmation.text
                state.navigateToVerifyContact.shouldLoadDestionationView = true

                return .task {
                    if !passwordText.isValidPassword() {
                        return .showNotificationBanner("Please enter a valid password", .info)
                    }

                    if passwordText != passwordConfirmationText {
                        return .showNotificationBanner("Confirmation password must match password", .info)
                    }

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
                createUserResponseEither.processResponseFromServer(
                    notificationBannerViewStore: notificationBannerViewStore,
                    state: state,
                    path: CreateUserBackendMessenger.BackendPath.createUser.rawValue
                ).onSuccess { _ in
                    notificationBannerViewStore.send(.showNotificationBanner("Account successfully created!", .success))
                    state.navigateToVerifyContact.shouldLoadDestionationView = true
                }
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

struct CreateAccount: PulpFictionView {
    let externalMessengers: ExternalMessengers
    let notifictionBannerViewStore: NotificationnotificationBannerViewStore
    let createAccountReducer: CreateAccountReducer
    private var store: PulpFictionStore<CreateAccountReducer>

    init(
        externalMessengers: ExternalMessengers,
        notificationBannerViewStore: NotificationnotificationBannerViewStore
    ) {
        self.externalMessengers = externalMessengers
        notifictionBannerViewStore = notificationBannerViewStore
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
                EmptyNavigationLinkView(
                    store: store.scope(
                        state: \.navigateToVerifyContact,
                        action: CreateAccountReducer.Action.navigateToVerifyContact
                    )
                ) {
                    CodeVerifier(
                        externalMessengers: externalMessengers,
                        notificationBannerViewStore: notifictionBannerViewStore
                    )
                }

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
                    textContentType: .password,
                    store: store.scope(
                        state: \.password,
                        action: CreateAccountReducer.Action.password
                    )
                )

                PulpFictionTextField(
                    prompt: "Confirm Password",
                    textFieldType: .secure,
                    textContentType: .password,
                    store: store.scope(
                        state: \.passwordConfirmation,
                        action: CreateAccountReducer.Action.passwordConfirmation
                    )
                )

                PulpFictionButton(
                    text: "CREATE ACCOUNT",
                    backgroundColor: .orange
                ) { viewStore.send(.createUser) }

                buildContactVerificationCaptionAndStatus(viewStore)

                Group {
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

                    CaptionAndStatus(text: "Passwords match") {
                        let passwordText = viewStore.password.text
                        let passwordConfirmationText = viewStore.passwordConfirmation.text
                        if passwordText.count == 0 || passwordConfirmationText.count == 0 {
                            return .empty
                        } else if passwordText == passwordConfirmationText {
                            return .valid
                        } else {
                            return .invalid
                        }
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
            PhoneNumberField(
                store: store.scope(
                    state: \.phone,
                    action: CreateAccountReducer.Action.phone
                )
            )
        case .Email:
            PulpFictionTextField(
                prompt: "Email",
                textContentType: .emailAddress,
                store: store.scope(
                    state: \.email,
                    action: CreateAccountReducer.Action.email
                )
            )
        }
    }

    @ViewBuilder
    private func buildContactVerificationCaptionAndStatus(_ viewStore: PulpFictionViewStore<CreateAccountReducer>) -> some View {
        switch viewStore.state.contactVerification.currentSelection {
        case .Phone:
            CaptionAndStatus(text: "Valid phone number") {
                let text = viewStore.phone.phoneNumber
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
