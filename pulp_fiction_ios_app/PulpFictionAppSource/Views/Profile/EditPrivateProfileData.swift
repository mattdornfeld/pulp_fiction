//
//  EditPrivateProfileData.swift
//  build_app_source
//
//  Created by Matthew Dornfeld on 12/25/22.
//

import ComposableArchitecture
import Foundation
import SwiftUI

/// Edit and display private profile data
struct EditPrivateProfileData: View {
    /// ViewStore for EditProfileView
    @ObservedObject var viewStore: ViewStore<EditProfileReducer.State, EditProfileReducer.Action>

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
            Spacer()
        }
    }
}
