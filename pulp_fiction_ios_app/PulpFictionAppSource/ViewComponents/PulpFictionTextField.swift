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
    let textContentType: UITextContentType?
    let shouldLoadKeyboardOnAppear: Bool
    @ObservedObject var viewStore: PulpFictionViewStore<PulpFictionTextFieldReducer>
    private let store: PulpFictionStore<PulpFictionTextFieldReducer>
    private var keyBoardType: UIKeyboardType? {
        switch textContentType {
        case .some(.oneTimeCode):
            return .numberPad
        case .some(.emailAddress):
            return .emailAddress
        default:
            return nil
        }
    }

    @FocusState private var focusedField: Bool

    enum TextFieldType {
        case insecure
        case secure
    }

    var body: some View {
        buildTextView(viewStore)
            .padding()
            .background(PulpFictionColors.lightGrey)
            .cornerRadius(5.0)
            .padding(.bottom, 20)
            .padding([.horizontal])
            .focused($focusedField)
            .onAppear {
                focusedField = shouldLoadKeyboardOnAppear
            }
    }

    @ViewBuilder private func buildTextView(_ viewStore: PulpFictionViewStore<PulpFictionTextFieldReducer>) -> some View {
        switch textFieldType {
        case .insecure:
            let textField = TextField(
                prompt,
                text: viewStore.binding(
                    get: \.text,
                    send: { newText in .updateText(newText) }
                )
            )
            .textContentType(textContentType)

            switch keyBoardType {
            case let .some(keyboardType):
                textField.keyboardType(keyboardType)
            case .none:
                textField
            }
        case .secure:
            let secureField = SecureField(
                prompt,
                text: viewStore.binding(
                    get: \.text,
                    send: { newText in .updateText(newText) }
                )
            ).textContentType(textContentType)

            switch keyBoardType {
            case let .some(keyboardType):
                secureField.keyboardType(keyboardType)
            case .none:
                secureField
            }
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
    init(
        prompt: String,
        textFieldType: TextFieldType = .insecure,
        textContentType: UITextContentType? = nil,
        shouldLoadKeyboardOnAppear: Bool = false,
        store: PulpFictionStore<PulpFictionTextFieldReducer> = .init(
            initialState: .init(),
            reducer: PulpFictionTextFieldReducer()
        )
    ) {
        self.prompt = prompt
        self.store = store
        self.textFieldType = textFieldType
        self.textContentType = textContentType
        self.shouldLoadKeyboardOnAppear = shouldLoadKeyboardOnAppear
        viewStore = ViewStore(store)
    }
}
