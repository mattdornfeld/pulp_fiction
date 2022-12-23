//
//  EditText.swift
//  build_app_source
//
//  Created by Matthew Dornfeld on 11/18/22.
//

import ComposableArchitecture
import Foundation
import Logging
import SwiftUI

struct EditTextReducer: ReducerProtocol {
    let maxTextSize: Int
    let createButtonAction: (EditTextReducer.State) async -> Void
    let validateTextAction: (String) -> Bool
    private let logger: Logger = .init(label: String(describing: EditTextReducer.self))

    init(
        maxTextSize: Int,
        createButtonAction: @escaping (EditTextReducer.State) async -> Void = { _ in },
        validateTextAction: @escaping (String) -> Bool = { _ in true }
    ) {
        self.maxTextSize = maxTextSize
        self.createButtonAction = createButtonAction
        self.validateTextAction = validateTextAction
    }

    struct State: Equatable {
        var text: String = ""
        var showInvalidInputAlert: Bool = false
    }

    enum Action: Equatable {
        case updateText(String)
        case submitText
        case processSuccessfulButtonPush
        case updateShowInvalidInputAlert(Bool)
    }

    func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
        switch action {
        case let .updateText(newText):
            state.text = String(newText.prefix(maxTextSize))
            return .none

        case .submitText:
            let _state = state
            return .task {
                if validateTextAction(_state.text) {
                    await createButtonAction(_state)
                    return .processSuccessfulButtonPush
                } else {
                    return .updateShowInvalidInputAlert(true)
                }
            }

        case .processSuccessfulButtonPush:
            logger.debug("Button successfully pushed")
            return .none

        case let .updateShowInvalidInputAlert(newShowInvalidInputAlert):
            state.showInvalidInputAlert = newShowInvalidInputAlert
            return .none
        }
    }
}

struct EditText: View {
    let prompt: String
    let createButtonLabel: String
    let keyboardType: UIKeyboardType
    let reducer: EditTextReducer
    @ObservedObject var viewStore: PulpFictionViewStore<EditTextReducer>
    @FocusState private var isInputTextFieldFocused: Bool

    init(
        prompt: String,
        createButtonLabel: String,
        keyboardType: UIKeyboardType,
        maxTextSize: Int = 10000,
        createButtonAction: @escaping (EditTextReducer.State) async -> Void = { _ in },
        validateTextAction: @escaping (String) -> Bool = { _ in true }
    ) {
        let reducer = EditTextReducer(
            maxTextSize: maxTextSize,
            createButtonAction: createButtonAction,
            validateTextAction: validateTextAction
        )

        self.prompt = prompt
        self.createButtonLabel = createButtonLabel
        self.keyboardType = keyboardType
        self.reducer = reducer
        viewStore = {
            let store = Store(
                initialState: EditTextReducer.State(),
                reducer: reducer
            )
            return ViewStore(store)
        }()
    }

    var body: some View {
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
                viewStore.send(.submitText)
            }
        }
        .alert("Please input a valid option", isPresented: viewStore.binding(
            get: \.showInvalidInputAlert,
            send: .updateShowInvalidInputAlert(false)
        )) {}
    }
}

extension EditText {
    init(prompt: String, createButtonLabel: String, createButtonAction: @escaping (EditTextReducer.State) async -> Void) {
        self.init(
            prompt: prompt,
            createButtonLabel: createButtonLabel,
            keyboardType: .default,
            createButtonAction: createButtonAction,
            validateTextAction: { _ in true }
        )
    }
}
