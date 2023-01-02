//
//  PulpFictionTextField.swift
//  build_app_source
//
//  Created by Matthew Dornfeld on 12/24/22.
//

import ComposableArchitecture
import Foundation
import SwiftUI

struct PulpFictionTextFieldReducer: ReducerProtocol {
    struct State: Equatable {
        var text: String = ""
    }

    enum Action: Equatable {
        case updateText(String)
    }

    func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
        switch action {
        case let .updateText(newText):
            state.text = newText
            return .none
        }
    }
}

typealias PulpFictionTextFieldViewStore = PulpFictionViewStore<PulpFictionTextFieldReducer>

struct PulpFictionTextField: View {
    let prompt: String
    let textFieldType: TextFieldType
    @ObservedObject var viewStore: PulpFictionViewStore<PulpFictionTextFieldReducer>
    private let store: PulpFictionStore<PulpFictionTextFieldReducer>
    private let lightGrey: Color = .init(
        red: 239.0 / 255.0,
        green: 243.0 / 255.0,
        blue: 244.0 / 255.0,
        opacity: 1.0
    )

    enum TextFieldType {
        case insecure
        case secure
    }

    var body: some View {
        buildTextView(viewStore)
            .padding()
            .background(lightGrey)
            .cornerRadius(5.0)
            .padding(.bottom, 20)
    }

    @ViewBuilder private func buildTextView(_ viewStore: PulpFictionViewStore<PulpFictionTextFieldReducer>) -> some View {
        switch textFieldType {
        case .insecure:
            TextField(
                prompt,
                text: viewStore.binding(
                    get: \.text,
                    send: { newText in .updateText(newText) }
                )
            )
        case .secure:
            SecureField(
                prompt,
                text: viewStore.binding(
                    get: \.text,
                    send: { newText in .updateText(newText) }
                )
            )
        }
    }

    static func buildViewStore() -> PulpFictionTextFieldViewStore {
        .init(
            initialState: PulpFictionTextFieldReducer.State(),
            reducer: PulpFictionTextFieldReducer()
        )
    }
}

extension PulpFictionTextField {
    init(prompt: String, textFieldType: TextFieldType, store: PulpFictionStore<PulpFictionTextFieldReducer>) {
        self.prompt = prompt
        self.store = store
        self.textFieldType = textFieldType
        viewStore = ViewStore(store)
    }

    init(prompt: String, store: PulpFictionStore<PulpFictionTextFieldReducer>) {
        self.init(
            prompt: prompt,
            textFieldType: .insecure,
            store: store
        )
    }

    init(prompt: String, textFieldType: TextFieldType) {
        self.init(
            prompt: prompt,
            textFieldType: textFieldType,
            store: .init(
                initialState: .init(),
                reducer: PulpFictionTextFieldReducer()
            )
        )
    }

    init(prompt: String) {
        self.init(
            prompt: prompt,
            textFieldType: .insecure,
            store: .init(
                initialState: .init(),
                reducer: PulpFictionTextFieldReducer()
            )
        )
    }
}
