//
//  TextCreatorView.swift
//  build_app_source
//
//  Created by Matthew Dornfeld on 11/16/22.
//

import ComposableArchitecture
import Foundation
import SwiftUI

struct TextCreatorReducer: ReducerProtocol {
    let maxtTextSize: Int

    struct State: Equatable {
        /// Caption being created
        var text: String = ""
    }

    enum Action {
        /// Updates the text as new characters are typed
        case updateText(String)
        case submitText(() -> Void)
    }

    func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
        switch action {
        case let .updateText(newText):
            state.text = String(newText.prefix(maxtTextSize))
            return .none
        case let .submitText(submitTextAction):
            if state.text.count == 0 {
                return .none
            }

            print(state.text)
            submitTextAction()
            return .none
        }
    }
}

struct TextCreatorView: View {
    let prompt: String
    let submitButtonLabel: String
    private let store: ComposableArchitecture.StoreOf<TextCreatorReducer>
    @FocusState private var isInputFieldFocused: Bool
    @Environment(\.presentationMode) private var presentationMode: Binding<PresentationMode>

    init(prompt: String, submitButtonLabel: String, maxTextSize: Int) {
        self.prompt = prompt
        self.submitButtonLabel = submitButtonLabel
        store = Store(
            initialState: TextCreatorReducer.State(),
            reducer: TextCreatorReducer(maxtTextSize: maxTextSize)
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
                .foregroundColor(.gray)
                .focused($isInputFieldFocused)
                Spacer()
            }
            .onAppear {
                isInputFieldFocused = true
            }
            .toolbar {
                TextCreatorTopNavigationBar(createButtonLabel: submitButtonLabel) {
                    viewStore.send(.submitText { self.presentationMode.wrappedValue.dismiss() })
                }
            }
        }
    }
}
