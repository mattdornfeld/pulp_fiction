//
//  EditTextView.swift
//  build_app_source
//
//  Created by Matthew Dornfeld on 11/18/22.
//

import ComposableArchitecture
import Foundation
import SwiftUI

struct EditTextReducer: ReducerProtocol {
    let maxTextSize: Int

    struct State: Equatable {
        var text: String = ""
        var showInvalidInputAlert: Bool = false
    }

    enum Action {
        case updateText(String)
        case updateShowInvalidInputAlert(Bool)
    }

    func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
        switch action {
        case let .updateText(newText):
            state.text = String(newText.prefix(maxTextSize))
            return .none
        case let .updateShowInvalidInputAlert(newShowInvalidInputAlert):
            state.showInvalidInputAlert = newShowInvalidInputAlert
            return .none
        }
    }
}

struct EditTextView: View {
    let prompt: String
    let createButtonLabel: String
    let keyboardType: UIKeyboardType
    let createButtonAction: (String) -> Void
    let validateTextAction: (String) -> Bool
    private let store: ComposableArchitecture.StoreOf<EditTextReducer>
    @FocusState private var isInputTextFieldFocused: Bool

    init(
        prompt: String,
        createButtonLabel: String,
        keyboardType: UIKeyboardType,
        maxTextSize: Int = 10000,
        createButtonAction: @escaping (String) -> Void,
        validateTextAction: @escaping (String) -> Bool
    ) {
        self.prompt = prompt
        self.createButtonLabel = createButtonLabel
        self.keyboardType = keyboardType
        self.createButtonAction = createButtonAction
        self.validateTextAction = validateTextAction
        store = Store(
            initialState: EditTextReducer.State(),
            reducer: EditTextReducer(maxTextSize: maxTextSize)
        )
    }

    var body: some View {
        WithViewStore(store) { viewStore in
            VStack {
                TextField(
                    prompt,
                    text: viewStore.binding(
                        get: \.text,
                        send: { newText in .updateText(newText) }
                    ),
                    prompt: Text(prompt)
                )
                .keyboardType(keyboardType)
                .foregroundColor(.gray)
                .focused($isInputTextFieldFocused)
                Spacer()
            }
            .onAppear {
                isInputTextFieldFocused = true
            }
            .toolbar {
                TextCreatorTopNavigationBar(createButtonLabel: createButtonLabel) {
                    if validateTextAction(viewStore.text) {
                        createButtonAction(viewStore.text)
                    } else {
                        viewStore.send(.updateShowInvalidInputAlert(true))
                    }
                }
            }
            .alert("Please input a valid option", isPresented: viewStore.binding(
                get: \.showInvalidInputAlert,
                send: .updateShowInvalidInputAlert(false)
            )) {}
        }
    }
}

extension EditTextView {
    init(prompt: String, createButtonLabel: String, createButtonAction: @escaping (String) -> Void) {
        self.init(
            prompt: prompt,
            createButtonLabel: createButtonLabel,
            keyboardType: .default,
            createButtonAction: createButtonAction,
            validateTextAction: { _ in true }
        )
    }
}
