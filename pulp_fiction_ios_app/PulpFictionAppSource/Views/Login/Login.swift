//
//  Login.swift
//  build_app_source
//
//  Created by Matthew Dornfeld on 12/24/22.
//

import ComposableArchitecture
import Foundation
import SwiftUI

struct LoginReducer: ReducerProtocol {
    let emailOrPhoneTextFieldViewStore: PulpFictionViewStore<PulpFictionTextFieldReducer>
    let passwordTextFieldViewStore: PulpFictionViewStore<PulpFictionTextFieldReducer>

    struct State: Equatable {}
    enum Action: Equatable {
        case login
    }

    func reduce(into _: inout State, action: Action) -> EffectTask<Action> {
        switch action {
        case .login:
            return .none
        }
    }
}

struct Login: View {
    private let emailOrPhoneTextField: PulpFictionTextField = .init(prompt: "Email or Phone")
    private let passwordTextField: PulpFictionTextField = .init(
        prompt: "Password",
        textFieldType: .secure
    )
    var reducer: LoginReducer {
        .init(
            emailOrPhoneTextFieldViewStore: emailOrPhoneTextField.viewStore,
            passwordTextFieldViewStore: passwordTextField.viewStore
        )
    }

    private var store: PulpFictionStore<LoginReducer> {
        .init(
            initialState: .init(),
            reducer: reducer
        )
    }

    var body: some View {
        WithViewStore(store) { viewStore in
            VStack {
                VStack {
                    emailOrPhoneTextField
                    passwordTextField
                }
                Button(action: { viewStore.send(.login) }) {
                    Text("LOGIN")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(width: 220, height: 60)
                        .background(.orange)
                        .cornerRadius(15.0)
                }
            }
            .padding()
        }
    }
}
