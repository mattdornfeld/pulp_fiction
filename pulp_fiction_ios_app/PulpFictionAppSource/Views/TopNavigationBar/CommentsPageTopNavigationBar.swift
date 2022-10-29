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

struct CommentsPageTopNavigationBar: NavigationBarContents {
    private let store: ComposableArchitecture.StoreOf<CommentsPageTopNavigationBarReducer> = Store(
        initialState: CommentsPageTopNavigationBarReducer.State(),
        reducer: CommentsPageTopNavigationBarReducer()
    )

    var body: some View {
        WithViewStore(store) { viewStore in
            HStack {
                Title("Comments")
                    .foregroundColor(.gray)
                    .padding(.leading, 7.5)
                Spacer()
                Symbol(symbolName: "plus", size: 25, color: .gray).navigateOnTap(
                    isActive: viewStore.binding(
                        get: \.shouldLoadCommentCreatorView,
                        send: CommentsPageTopNavigationBarReducer.Action.updateShouldLoadCommentCreatorView(false)
                    ),
                    destination: CommentCreatorView()
                ) { viewStore.send(.updateShouldLoadCommentCreatorView(true)) }
            }
        }
    }
}
