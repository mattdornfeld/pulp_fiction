//
//  EditProfileView.swift
//  build_app_source
//
//  Created by Matthew Dornfeld on 11/16/22.
//

import ComposableArchitecture
import Foundation
import Logging
import SwiftUI

/// Enumerates the sections of a user profile that can be edited
enum ProfileSection: String, DropDownMenuOption {
    /// The public facing data
    case Public
    /// User's private data
    case Private
}

/// Reducer for EditProfileView
struct EditProfileReducer: ReducerProtocol {
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
    }

    enum Action {
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
    }

    func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
        switch action {
        case let .updateUserAvatarUIImage(newUserAvatarUIImage):
            newUserAvatarUIImage
                .toContentData()
                .mapRight { newUserPostContentData in
                    let newLoggedInUserPostData1 = UserPostData
                        .setter(for: \.userPostContentData)
                        .set(state.loggedInUserPostData, newUserPostContentData)

                    let newLoggedInUserPostData2 = UserPostData
                        .setter(for: \.userAvatarUIImage)
                        .set(newLoggedInUserPostData1, newUserAvatarUIImage)

                    state.loggedInUserPostData = newLoggedInUserPostData2
                }
                .onError { _ in
                    logger.error("Error serializing image")
                }
            return .none

        case let .updateDisplayName(newDisplayName):
            let newLoggedInUserPostData = UserPostData
                .setter(for: \.userDisplayName)
                .set(state.loggedInUserPostData, newDisplayName)
            return .task { .updateLoggedInUserPostData(newLoggedInUserPostData) }

        case let .updateBio(newBio):
            let newLoggedInUserPostData = UserPostData
                .setter(for: \.bio)
                .set(state.loggedInUserPostData, newBio)
            return .task { .updateLoggedInUserPostData(newLoggedInUserPostData) }

        case let .updateEmail(newEmail):
            let newLoggedInUserSensitiveMetadata = SensitiveUserMetadata
                .setter(for: \.email)
                .set(state.loggedInUserSensitiveMetadata, newEmail)
            return .task { .updateLoggedInUserSensitiveMetadata(newLoggedInUserSensitiveMetadata) }

        case let .updatePhoneNumber(newPhoneNumber):
            let newLoggedInUserSensitiveMetadata = SensitiveUserMetadata
                .setter(for: \.phoneNumber)
                .set(state.loggedInUserSensitiveMetadata, newPhoneNumber)
            return .task { .updateLoggedInUserSensitiveMetadata(newLoggedInUserSensitiveMetadata) }

        case let .updateDateOfBirth(newDateOfBirth):
            let newLoggedInUserSensitiveMetadata = SensitiveUserMetadata
                .setter(for: \.dateOfBirth)
                .set(state.loggedInUserSensitiveMetadata, newDateOfBirth)
            return .task { .updateLoggedInUserSensitiveMetadata(newLoggedInUserSensitiveMetadata) }

        case let .updateLoggedInUserPostData(newLoggedInUserPostData):
            state.loggedInUserPostData = newLoggedInUserPostData
            print(newLoggedInUserPostData)
            return .none

        case let .updateLoggedInUserSensitiveMetadata(newLoggedInUserSensitiveMetadata):
            state.loggedInUserSensitiveMetadata = newLoggedInUserSensitiveMetadata
            print(newLoggedInUserSensitiveMetadata)
            return .none
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
        EditTextView(
            prompt: prompt,
            createButtonLabel: "Update",
            keyboardType: keyboardType,
            createButtonAction: { newText in
                updateButtonAction(newText)
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

/// Edit and display publicly facing profile data
struct EditPublicProfileDataView: View {
    /// ViewStore for EditProfileView
    let viewStore: ViewStore<EditProfileReducer.State, EditProfileReducer.Action>

    var body: some View {
        VStack {
            CircularImage(
                uiImage: viewStore.loggedInUserPostData.userAvatarUIImage,
                radius: 40,
                borderColor: .red,
                borderWidth: 1
            )
            .padding([.leading, .top], 5)
            Caption(
                text: "Edit Profile Picture",
                color: .gray
            )
        }.navigateOnTap(destination: AvatarSelectorView(updateButtonAction: { uiImage in
            viewStore.send(.updateUserAvatarUIImage(uiImage))
        }))

        ProfileField(
            fieldName: "Display Name",
            fieldValue: viewStore.loggedInUserPostData.userDisplayName
        ).navigateOnTap(
            destination: EditProfileField(
                prompt: viewStore.loggedInUserPostData.userDisplayName,
                updateButtonAction: { viewStore.send(.updateDisplayName($0)) }
            )
        )

        ProfileField(
            fieldName: "Bio",
            fieldValue: viewStore.loggedInUserPostData.bio
        ).navigateOnTap(
            destination: EditProfileField(
                prompt: viewStore.loggedInUserPostData.bio,
                updateButtonAction: { viewStore.send(.updateBio($0)) }
            )
        )

        Spacer()
    }
}

/// Edit and display private profile data
struct EditPrivateProfileDataView: View {
    /// ViewStore for EditProfileView
    let viewStore: ViewStore<EditProfileReducer.State, EditProfileReducer.Action>

    var body: some View {
        VStack {
            Caption(
                text: "This data is private and will not be shared with anyone",
                alignment: .center,
                color: .gray
            ).padding()

            ProfileField(
                fieldName: "Email",
                fieldValue: viewStore.loggedInUserSensitiveMetadata.email
            ).navigateOnTap(
                destination: EditProfileField(
                    prompt: viewStore.loggedInUserSensitiveMetadata.email,
                    keyboardType: .emailAddress,
                    updateButtonAction: { viewStore.send(.updateEmail($0)) },
                    validateTextAction: { $0.isValidEmail() }
                )
            )

            ProfileField(
                fieldName: "Phone Number",
                fieldValue: viewStore.loggedInUserSensitiveMetadata.phoneNumber
            ).navigateOnTap(
                destination: EditProfileField(
                    prompt: viewStore.loggedInUserSensitiveMetadata.phoneNumber,
                    keyboardType: .phonePad,
                    updateButtonAction: { viewStore.send(.updatePhoneNumber($0)) },
                    validateTextAction: { $0.isValidPhoneNumber() }
                )
            )

            ProfileField(
                fieldName: "Date of Birth",
                fieldValue: viewStore.loggedInUserSensitiveMetadata.getFormattedDateOfBirth()
            ).sheetOnTap {
                DatePicker(
                    "Date of Birth",
                    selection: viewStore.binding(
                        get: \.loggedInUserSensitiveMetadata.dateOfBirth,
                        send: { newDateOfBirth in .updateDateOfBirth(newDateOfBirth) }
                    ),
                    displayedComponents: [.date]
                ).datePickerStyle(.graphical)
            }

            Button("Change Password") {
                print("Change Password")
            }
            .padding()
            .foregroundColor(.white)
            .background(.orange)

            Spacer()
        }
    }
}

/// Display and edit profile data
struct EditProfileView: View {
    @ObservedObject private var symbolWithDropDownMenu: SymbolWithDropDownMenu<ProfileSection> = .init(
        symbolName: "line.3.horizontal.decrease.circle",
        symbolSize: 20,
        symbolColor: .gray,
        menuOptions: ProfileSection.allCases,
        initialMenuSelection: .Public
    )
    private var store: StoreOf<EditProfileReducer>

    /// Inits a EditProfileView
    /// - Parameter loggedInUserPostData: UserPostData for the logged in user
    init(loggedInUserPostData: UserPostData) {
        self.store = Store(
            initialState: EditProfileReducer.State(
                loggedInUserPostData: loggedInUserPostData
            ),
            reducer: EditProfileReducer()
        )
    }

    var body: some View {
        WithViewStore(store) { viewStore in
            VStack {
                switch symbolWithDropDownMenu.currentSelection {
                case .Public:
                    EditPublicProfileDataView(viewStore: viewStore)
                case .Private:
                    EditPrivateProfileDataView(viewStore: viewStore)
                }
            }
            .toolbar { EditProfileTopNavigationBar(
                symbolWithDropDownMenu: symbolWithDropDownMenu
            ) }
        }
    }
}
