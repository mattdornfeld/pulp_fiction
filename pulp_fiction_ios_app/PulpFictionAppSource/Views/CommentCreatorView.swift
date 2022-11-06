//
//  CommentCreatorView.swift
//  build_app_source
//
//  Created by Matthew Dornfeld on 10/28/22.
//

import ComposableArchitecture
import Foundation
import SwiftUI

/// Reducer for CommentCreatorView
struct CommentCreatorReducer: ReducerProtocol {
    struct State: Equatable {
        /// Comment being created
        var comment: String = ""
    }

    enum Action {
        /// Updates the comment as new characters are typed
        case updateComment(String)
        /// Posts the comment
        case postComment
    }

    func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
        switch action {
        case let .updateComment(newComment):
            state.comment = newComment
            return .none

        case .postComment:
            print(state.comment)
            return .none
        }
    }
}

/// View for creating and posting comments
struct CommentCreatorView: View {
    private let store: ComposableArchitecture.StoreOf<CommentCreatorReducer> = Store(
        initialState: CommentCreatorReducer.State(),
        reducer: CommentCreatorReducer()
    )
    @FocusState private var isInputCommentFieldFocused: Bool

    var body: some View {
        WithViewStore(store) { viewStore in
            VStack {
                TextField(
                    "",
                    text: viewStore.binding(
                        get: \.comment,
                        send: { newComment in .updateComment(newComment) }
                    ),
                    prompt: Text("Write a comment")
                )
                .foregroundColor(.gray)
                .focused($isInputCommentFieldFocused)
                Spacer()
            }
            .onAppear {
                isInputCommentFieldFocused = true
            }
            .toolbar {
                CommentCreatorTopNavigationBar(tapPostButtonAction: { viewStore.send(.postComment) })
            }
        }
    }
}
