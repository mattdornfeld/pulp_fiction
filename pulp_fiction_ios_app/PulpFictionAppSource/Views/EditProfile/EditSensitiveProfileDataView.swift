//
//  EditSensitiveProfileDataView.swift
//  build_app_source
//
//  Created by Matthew Dornfeld on 11/18/22.
//

import ComposableArchitecture
import Foundation
import SwiftUI

struct EditSensitiveProfileDataReducer: ReducerProtocol {
    struct State: Equatable {}

    enum Action {}

    func reduce(into _: inout State, action _: Action) -> EffectTask<Action> {
        return .none
    }
}

struct EditSensitiveProfileDataView: View {
    let loggedInUserPostData: UserPostData
    let loggedInUserSensitiveMetadata: SensitiveUserMetadata = .init(
        email: "shadowfax@middleearth.com",
        phoneNumber: "867-5309",
        dateOfBirth: {
            let newFormatter = ISO8601DateFormatter()
            return newFormatter.date(from: "1990-04-20T00:00:00Z")!
        }()
    )
    private let store: ComposableArchitecture.StoreOf<EditSensitiveProfileDataReducer> = Store(
        initialState: EditSensitiveProfileDataReducer.State(),
        reducer: EditSensitiveProfileDataReducer()
    )

    var body: some View {
        WithViewStore(store) { _ in
            VStack {
                EditProfileField(
                    fieldName: "Email",
                    fieldValue: loggedInUserSensitiveMetadata.email
                )

                EditProfileField(
                    fieldName: "Phone Number",
                    fieldValue: loggedInUserSensitiveMetadata.phoneNumber
                )

                EditProfileField(
                    fieldName: "Date of Birth",
                    fieldValue: loggedInUserSensitiveMetadata.getFormattedDateOfBirth()
                )

                Spacer()
            }
            .toolbar { EditProfileTopNavigationBar() }
        }
    }
}
