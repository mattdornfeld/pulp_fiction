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
    private let maxCommentSize: Int = 100
    
    struct State: Equatable {
        /// Comment being created
        var comment: String = ""
    }

    enum Action {
        /// Updates the comment as new characters are typed
        case updateComment(String)
        /// Posts the comment
        case postComment(() -> ())
    }

    func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
        switch action {
        case let .updateComment(newComment):
            state.comment = String(newComment.prefix(maxCommentSize))
            return .none

        case .postComment(let backAction):
            if (state.comment.count == 0) {
                return .none
            }
            
            print(state.comment)
            backAction()
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
    @Environment(\.presentationMode) private var presentationMode: Binding<PresentationMode>

    var body: some View {
        WithViewStore(store) { viewStore in
            VStack {
                TextField(
                    "Write a comment",
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
                CommentCreatorTopNavigationBar(tapPostButtonAction: {
                    viewStore.send(.postComment{ self.presentationMode.wrappedValue.dismiss() })
                })
            }
        }
    }
}
