//
//  PhoneNumberField.swift
//  build_app_source
//
//  Created by Matthew Dornfeld on 1/3/23.
//

import ComposableArchitecture
import Foundation
import iPhoneNumberField
import SwiftUI

struct PhoneNumberFieldReducer: ReducerProtocol {
    struct State: Equatable {
        var phoneNumber: String = ""
    }

    enum Action: Equatable {
        case updatePhoneNumber(String)
    }

    func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
        switch action {
        case let .updatePhoneNumber(newPhoneNumber):
            state.phoneNumber = newPhoneNumber
            return .none
        }
    }
}

struct PhoneNumberField: View {
    let store: PulpFictionStore<PhoneNumberFieldReducer>
    @State private var isEditing: Bool = false

    var body: some View {
        WithViewStore(store) { viewStore in
            iPhoneNumberField(
                "(000) 000-0000",
                text: viewStore.binding(
                    get: \.phoneNumber,
                    send: { .updatePhoneNumber($0) }
                ),
                isEditing: $isEditing
            )
            .flagHidden(false)
            .flagSelectable(true)
            .font(UIFont(size: 30, weight: .light, design: .monospaced))
            .maximumDigits(10)
            .foregroundColor(Color.black)
            .clearButtonMode(.whileEditing)
            .onClear { _ in isEditing.toggle() }
            .accentColor(Color.orange)
            .padding()
            .background(PulpFictionColors.lightGrey)
            .cornerRadius(10)
            .padding()
        }
    }
}

extension PhoneNumberField {
    init() {
        store = .init(
            initialState: .init(),
            reducer: PhoneNumberFieldReducer()
        )
    }
}
