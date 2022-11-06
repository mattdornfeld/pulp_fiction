//
//  CommentsPageTopNavigationBar.swift
//  build_app_source
//
//  Created by Matthew Dornfeld on 10/28/22.
//

import ComposableArchitecture
import Foundation
import SwiftUI

struct CommentsPageTopNavigationBarReducer: ReducerProtocol {
    struct State: Equatable {
        var shouldLoadCommentCreatorView: Bool = false
    }

    enum Action {
        case updateShouldLoadCommentCreatorView(Bool)
    }

    func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
        switch action {
        case let .updateShouldLoadCommentCreatorView(newShouldLoadCommentCreatorView):
            state.shouldLoadCommentCreatorView = newShouldLoadCommentCreatorView
            return .none
        }
    }
}

struct CommentsPageTopNavigationBar: ToolbarContent {
    @ObservedObject private var viewStore: ViewStore<CommentsPageTopNavigationBarReducer.State, CommentsPageTopNavigationBarReducer.Action> = {
        let store = Store(
            initialState: CommentsPageTopNavigationBarReducer.State(),
            reducer: CommentsPageTopNavigationBarReducer()
        )
        
        return ViewStore(store)
    }()
    @Environment(\.presentationMode) private var presentationMode: Binding<PresentationMode>


    var body: some ToolbarContent {        
        ToolbarItem(placement: .navigationBarLeading) {
            Title("Comments")
                .foregroundColor(.gray)
        }
        
        ToolbarItem(placement: .navigationBarTrailing) {
            Symbol(
                symbolName: "plus",
                size: 20,
                color: .gray
            ).navigateOnTap(
                isActive: viewStore.binding(
                    get: \.shouldLoadCommentCreatorView,
                    send: CommentsPageTopNavigationBarReducer.Action.updateShouldLoadCommentCreatorView(false)
                ),
                destination: CommentCreatorView()
            ) { viewStore.send(.updateShouldLoadCommentCreatorView(true)) }
        }
    }
}
