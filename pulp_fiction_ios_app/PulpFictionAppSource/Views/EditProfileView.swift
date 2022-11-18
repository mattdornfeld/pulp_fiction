//
//  EditProfileView.swift
//  build_app_source
//
//  Created by Matthew Dornfeld on 11/16/22.
//

import ComposableArchitecture
import Foundation
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
    struct State: Equatable {
        /// The currently selected profile section to edit
        var currentProfileSection: ProfileSection
    }

    enum Action {
        /// Updates currentProfileSection
        case updateCurrentProfileSection(ProfileSection)
    }

    func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
        switch action {
        case let .updateCurrentProfileSection(newCurrentProfileSection):
            state.currentProfileSection = newCurrentProfileSection
            return .none
        }
    }
}

/// Top navigation bar for EditProfileView
struct EditProfileTopNavigationBar: ToolbarContent {
    let currentProfileSection: ProfileSection
    let viewStore: ViewStore<EditProfileReducer.State, EditProfileReducer.Action>

    var body: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Title("Edit Profile")
                .foregroundColor(.gray)
        }

        ToolbarItem(placement: .navigationBarTrailing) {
            SymbolWithDropDownMenu(
                symbolName: "line.3.horizontal.decrease.circle",
                symbolSize: 20,
                symbolColor: .gray,
                menuOptions: ProfileSection.allCases,
                initialMenuSelection: currentProfileSection
            ) { profileSection in
                viewStore.send(.updateCurrentProfileSection(profileSection))
            }
        }
    }
}

/// View that shows a profile field name and value
struct ProfileField: View {
    let fieldName: String
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

/// Edit and display publicly facing profile data
struct EditPublicProfileDataView: View {
    let loggedInUserPostData: UserPostData

    var body: some View {
        VStack {
            CircularImage(
                uiImage: loggedInUserPostData.userAvatarUIImage,
                radius: 40,
                borderColor: .red,
                borderWidth: 1
            )
            .padding([.leading, .top], 5)
            Caption(
                text: "Edit Profile Picture",
                color: .gray
            )
        }

        ProfileField(
            fieldName: "Display Name",
            fieldValue: loggedInUserPostData.userDisplayName
        )

        ProfileField(
            fieldName: "Bio",
            fieldValue: loggedInUserPostData.bio
        )

        Spacer()
    }
}

/// Edit and display private profile data
struct EditPrivateProfileDataView: View {
    let loggedInUserSensitiveMetadata: SensitiveUserMetadata = .init(
        email: "shadowfax@middleearth.com",
        phoneNumber: "867-5309",
        dateOfBirth: {
            let newFormatter = ISO8601DateFormatter()
            return newFormatter.date(from: "1990-04-20T00:00:00Z")!
        }()
    )

    var body: some View {
        VStack {
            Caption(
                text: "This data is private and will not be shared with other users",
                alignment: .center,
                color: .gray
            ).padding()

            ProfileField(
                fieldName: "Email",
                fieldValue: loggedInUserSensitiveMetadata.email
            )

            ProfileField(
                fieldName: "Phone Number",
                fieldValue: loggedInUserSensitiveMetadata.phoneNumber
            )

            ProfileField(
                fieldName: "Date of Birth",
                fieldValue: loggedInUserSensitiveMetadata.getFormattedDateOfBirth()
            )

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
    let loggedInUserPostData: UserPostData
    private let store: ComposableArchitecture.StoreOf<EditProfileReducer> = Store(
        initialState: EditProfileReducer.State(currentProfileSection: .Public),
        reducer: EditProfileReducer()
    )

    var body: some View {
        WithViewStore(store) { viewStore in
            VStack {
                switch viewStore.currentProfileSection {
                case .Public:
                    EditPublicProfileDataView(loggedInUserPostData: loggedInUserPostData)
                case .Private:
                    EditPrivateProfileDataView()
                }
            }
            .toolbar { EditProfileTopNavigationBar(
                currentProfileSection: viewStore.currentProfileSection,
                viewStore: viewStore
            ) }
        }
    }
}
