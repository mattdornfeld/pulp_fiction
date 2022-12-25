//
//  EditPublicProfileData.swift
//  build_app_source
//
//  Created by Matthew Dornfeld on 12/25/22.
//

import ComposableArchitecture
import Foundation
import SwiftUI

/// Edit and display publicly facing profile data
struct EditPublicProfileData: View {
    /// ViewStore for EditProfileView
    @ObservedObject var viewStore: PulpFictionViewStore<EditProfileReducer>

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
