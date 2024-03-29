//
//  EditProfileView.swift
//  build_app_source
//
//  Created by Matthew Dornfeld on 11/16/22.
//

import Bow
import ComposableArchitecture
import Foundation
import Logging
import SwiftUI

/// Enumerates the sections of a user profile that can be edited
enum ProfileSection: String, DropDownMenuOption {
    /// General profile options
    case General
    /// The public facing data
    case Public
    /// User's private data
    case Private
}

/// Reducer for EditProfileView
struct EditProfileReducer: PulpFictionReducerProtocol {
    let externalMessengers: ExternalMessengers
    let notificationBannerViewStore: NotificationnotificationBannerViewStore
    private let logger: Logger = .init(label: String(describing: EditProfileReducer.self))

    struct State: Equatable {
        var loggedInUserPostData: UserPostData
        var loggedInUserSensitiveMetadata: SensitiveUserMetadata = .init(
            email: "shadowfax@middleearth.com",
            phoneNumber: "867-5309",
            dateOfBirth: {
                let newFormatter = ISO8601DateFormatter()
                return newFormatter.date(from: "1990-04-20T00:00:00Z")!
            }()
        )
        /// Toggle used to trigger a UI refresh
        var toggleToRefresh: Bool = false
    }

    enum BannerMessage: String {
        case updateUserAvatarUIImage = "Avatar successfully updated"
        case updateDisplayName = "Display name successfully updated"
        case updateBio = "Bio successfully updated"
        case updateEmail = "Email successfully updated"
        case updatePhoneNumber = "Phone number successfully updated"
        case updateDateOfBirth = "Date of birth successfully updated"
    }

    enum Action: Equatable {
        /// Updates loggedInUserPostData.userAvatarUIImage
        case updateUserAvatarUIImage(UIImage)
        /// Updates loggedInUserPostData.loggedInUserPostDatadisplayName
        case updateDisplayName(String)
        /// Updates loggedInUserPostData.bio
        case updateBio(String)
        /// Updates loggedInUserSensitiveMetadata.emal
        case updateEmail(String)
        /// Updates loggedInUserSensitiveMetadata.phoneNumber
        case updatePhoneNumber(String)
        /// Updates loggedInUserSensitiveMetadata.dateOfBirth
        case updateDateOfBirth(Date)
        /// Updates loggedInUserPostData
        case updateLoggedInUserPostData(UserPostData)
        /// Updates loggedInUserSensitiveMetadata
        case updateLoggedInUserSensitiveMetadata(SensitiveUserMetadata)
        case processUpdateUserResponse(
            Either<PulpFictionRequestError, UpdateUserResponse>,
            BackendPath,
            BannerMessage,
            EquatableWrapper<(UpdateUserResponse, State) -> PulpFictionRequestEither<UserData>>
        )
    }

    func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
        switch action {
        case let .updateUserAvatarUIImage(newUserAvatarUIImage):
            return .task {
                let updateUserResponseEither = await backendMessenger
                    .updateUserBackendMessenger
                    .updateUserAvatarUIImage(avatarUIImage: newUserAvatarUIImage)

                return .processUpdateUserResponse(
                    updateUserResponseEither,
                    UpdateUserBackendMessenger.BackendPath.updateUserAvatarUIImage.rawValue,
                    BannerMessage.updateUserAvatarUIImage,
                    EquatableWrapper(
                        { _, state in
                            newUserAvatarUIImage
                                .toContentData()
                                .mapRight { newUserPostContentData in
                                    let newLoggedInUserPostData1 = UserPostData
                                        .setter(for: \.userPostContentData)
                                        .set(state.loggedInUserPostData, newUserPostContentData)

                                    return UserPostData
                                        .setter(for: \.userAvatarUIImage)
                                        .set(newLoggedInUserPostData1, newUserAvatarUIImage)
                                }
                        }
                    )
                )
            }

        case let .updateDisplayName(newDisplayName):
            return .task {
                let updateUserResponseEither = await backendMessenger
                    .updateUserBackendMessenger
                    .updateDisplayName(newDisplayName: newDisplayName)

                return .processUpdateUserResponse(
                    updateUserResponseEither,
                    UpdateUserBackendMessenger.BackendPath.updateDisplayName.rawValue,
                    BannerMessage.updateDisplayName,
                    EquatableWrapper(
                        { _, state in
                            let newLoggedInUserPostData = UserPostData
                                .setter(for: \.userDisplayName)
                                .set(state.loggedInUserPostData, newDisplayName)
                            return .right(newLoggedInUserPostData)
                        }
                    )
                )
            }

        case let .updateBio(newBio):
            return .task {
                let updateUserResponseEither = await backendMessenger
                    .updateUserBackendMessenger
                    .updateBio(newBio: newBio)

                return .processUpdateUserResponse(
                    updateUserResponseEither,
                    UpdateUserBackendMessenger.BackendPath.updateBio.rawValue,
                    BannerMessage.updateBio,
                    EquatableWrapper(
                        { _, state in
                            let newLoggedInUserPostData = UserPostData
                                .setter(for: \.bio)
                                .set(state.loggedInUserPostData, newBio)
                            return .right(newLoggedInUserPostData)
                        }
                    )
                )
            }

        case let .updateEmail(newEmail):
            return .task {
                let updateUserResponseEither = await backendMessenger
                    .updateUserBackendMessenger
                    .updateEmail(newEmail: newEmail)

                return .processUpdateUserResponse(
                    updateUserResponseEither,
                    UpdateUserBackendMessenger.BackendPath.updateEmail.rawValue,
                    BannerMessage.updateEmail,
                    EquatableWrapper(
                        { _, state in
                            let newLoggedInUserSensitiveMetadata = SensitiveUserMetadata
                                .setter(for: \.email)
                                .set(state.loggedInUserSensitiveMetadata, newEmail)
                            return .right(newLoggedInUserSensitiveMetadata)
                        }
                    )
                )
            }

        case let .updatePhoneNumber(newPhoneNumber):
            return .task {
                let updateUserResponseEither = await backendMessenger
                    .updateUserBackendMessenger
                    .updatePhoneNumber(newPhoneNumber: newPhoneNumber)

                return .processUpdateUserResponse(
                    updateUserResponseEither,
                    UpdateUserBackendMessenger.BackendPath.updatePhoneNumber.rawValue,
                    BannerMessage.updatePhoneNumber,
                    EquatableWrapper(
                        { _, state in
                            let newLoggedInUserSensitiveMetadata = SensitiveUserMetadata
                                .setter(for: \.phoneNumber)
                                .set(state.loggedInUserSensitiveMetadata, newPhoneNumber)
                            return .right(newLoggedInUserSensitiveMetadata)
                        }
                    )
                )
            }

        case let .updateDateOfBirth(newDateOfBirth):
            return .task {
                let updateUserResponseEither = await backendMessenger
                    .updateUserBackendMessenger
                    .updateDateOfBirth(newDateOfBirth: newDateOfBirth)

                return .processUpdateUserResponse(
                    updateUserResponseEither,
                    UpdateUserBackendMessenger.BackendPath.updateDateOfBirth.rawValue,
                    BannerMessage.updateDateOfBirth,
                    EquatableWrapper(
                        { _, state in
                            let newLoggedInUserSensitiveMetadata = SensitiveUserMetadata
                                .setter(for: \.dateOfBirth)
                                .set(state.loggedInUserSensitiveMetadata, newDateOfBirth)
                            return .right(newLoggedInUserSensitiveMetadata)
                        }
                    )
                )
            }

        case let .updateLoggedInUserPostData(newLoggedInUserPostData):
            state.loggedInUserPostData = newLoggedInUserPostData
            state.toggleToRefresh.toggle()
            return .none

        case let .updateLoggedInUserSensitiveMetadata(newLoggedInUserSensitiveMetadata):
            state.loggedInUserSensitiveMetadata = newLoggedInUserSensitiveMetadata
            return .none

        case let .processUpdateUserResponse(updateUserResponseEither, backendPath, bannerMessage, userPostDataUpdateAction):
            let _state = state
            let newLoggedInUserPostaDataEither = updateUserResponseEither.processResponseFromServer(
                notificationBannerViewStore: notificationBannerViewStore,
                state: _state,
                path: backendPath
            ).flatMap { updateUserResponse in userPostDataUpdateAction.wrapped(updateUserResponse, _state) }^

            switch newLoggedInUserPostaDataEither.toEnum() {
            case .left:
                return .none
            case let .right(newLoggedInUserPostaData as UserPostData):
                notificationBannerViewStore.send(.showNotificationBanner(bannerMessage.rawValue, .info))
                return .task { .updateLoggedInUserPostData(newLoggedInUserPostaData) }
            case let .right(newLoggedInSensitiveUserMetadata as SensitiveUserMetadata):
                notificationBannerViewStore.send(.showNotificationBanner(bannerMessage.rawValue, .info))
                return .task { .updateLoggedInUserSensitiveMetadata(newLoggedInSensitiveUserMetadata) }
            case let .right(userData):
                logger.error(
                    "newLoggedInUserPostaDataEither has unsupported type",
                    metadata: [
                        "userData": "\(userData)",
                    ]
                )
                return .none
            }
        }
    }
}

/// Top navigation bar for EditProfileView
struct EditProfileTopNavigationBar: ToolbarContent {
    let symbolWithDropDownMenu: SymbolWithDropDownMenu<ProfileSection>

    var body: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Title("Edit Profile")
                .foregroundColor(.gray)
        }

        ToolbarItem(placement: .navigationBarTrailing) {
            symbolWithDropDownMenu.view
        }
    }
}

/// View that shows a profile field name and value
struct ProfileField: View {
    /// The profile field name
    let fieldName: String
    /// The profile field value
    let fieldValue: String
    var body: some View {
        VStack {
            BoldCaption(fieldName)
            Caption(
                text: fieldValue,
                color: .gray
            )
        }
        .padding([.leading, .trailing], 10)
        .padding([.bottom, .top], 2)
    }
}

/// View for editing a profile field
struct EditProfileField: View {
    /// The prompt shown in the edit text field
    let prompt: String
    /// The keyboard type
    let keyboardType: UIKeyboardType
    /// Action executed when the update button is tapped
    let updateButtonAction: (String) -> Void
    /// Action that's executed when the update button is tapped to ensure text is valid
    let validateTextAction: (String) -> Bool
    @Environment(\.presentationMode) private var presentationMode: Binding<PresentationMode>

    var body: some View {
        EditText(
            prompt: prompt,
            createButtonLabel: "Update",
            keyboardType: keyboardType,
            createButtonAction: { state in
                updateButtonAction(state.text)
                self.presentationMode.wrappedValue.dismiss()
            },
            validateTextAction: validateTextAction
        )
    }
}

extension EditProfileField {
    /// Inits an EditProfileField
    /// - Parameters:
    ///   - prompt: The prompt shown in the edit text field
    ///   - updateButtonAction: Action executed when the update button is tapped
    init(
        prompt: String,
        updateButtonAction: @escaping (String) -> Void
    ) {
        self.init(
            prompt: prompt,
            keyboardType: .default,
            updateButtonAction: updateButtonAction,
            validateTextAction: { _ in true }
        )
    }
}

/// Display and edit profile data
struct EditProfile: PulpFictionView {
    let externalMessengers: ExternalMessengers
    let notificationBannerViewStore: NotificationnotificationBannerViewStore
    @ObservedObject private var symbolWithDropDownMenu: SymbolWithDropDownMenu<ProfileSection> = .init(
        symbolName: "line.3.horizontal.decrease.circle",
        symbolSize: 20,
        symbolColor: .gray,
        menuOptions: ProfileSection.allCases,
        initialMenuSelection: .General
    )
    private var store: ComposableArchitecture.StoreOf<EditProfileReducer>

    init(
        loggedInUserPostData: UserPostData,
        externalMessengers: ExternalMessengers,
        notificationBannerViewStore: NotificationnotificationBannerViewStore
    ) {
        self.externalMessengers = externalMessengers
        self.notificationBannerViewStore = notificationBannerViewStore
        store = Store(
            initialState: EditProfileReducer.State(
                loggedInUserPostData: loggedInUserPostData
            ),
            reducer: EditProfileReducer(
                externalMessengers: externalMessengers,
                notificationBannerViewStore: notificationBannerViewStore
            )
        )
    }

    var body: some View {
        WithViewStore(store) { viewStore in
            VStack {
                switch symbolWithDropDownMenu.currentSelection {
                case .General:
                    GeneralProfileOptions(
                        externalMessengers: externalMessengers,
                        notificationBannerViewStore: notificationBannerViewStore
                    )
                case .Public:
                    EditPublicProfileData(viewStore: viewStore)
                case .Private:
                    EditPrivateProfileData(viewStore: viewStore)
                }
            }
            .toolbar { EditProfileTopNavigationBar(
                symbolWithDropDownMenu: symbolWithDropDownMenu
            ) }
        }
    }
}
