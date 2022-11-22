//
//  ExtraOptionsDropDownMenuView.swift
//  build_app_source
//
//  Created by Matthew Dornfeld on 11/16/22.
//

import ComposableArchitecture
import Foundation
import SwiftUI

struct ExtraOptionsDropDownMenuReducer: ReducerProtocol {
    struct State: Equatable {
        var shouldNavigateToReportPostView: Bool = false
    }

    enum Action {
        case updateShouldNavigateToReportPostView(Bool)
    }

    func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
        switch action {
        case let .updateShouldNavigateToReportPostView(newShouldNavigateToReportPostView):
            state.shouldNavigateToReportPostView = newShouldNavigateToReportPostView
            return .none
        }
    }
}

enum ExtraOptions: String, DropDownMenuOption {
    case Report
}

struct ExtraOptionsDropDownMenuView: View {
    let postMetadata: PostMetadata
    private let store: ComposableArchitecture.StoreOf<ExtraOptionsDropDownMenuReducer>

    init(postMetadata: PostMetadata) {
        self.postMetadata = postMetadata
        store = Store(
            initialState: ExtraOptionsDropDownMenuReducer.State(),
            reducer: ExtraOptionsDropDownMenuReducer()
        )
    }

    var body: some View {
        WithViewStore(store) { viewStore in
            LabelWithDropDownNavigationMenu(
                label: Symbol(symbolName: "ellipsis")
                    .padding(.trailing, 10)
                    .padding(.bottom, 4),
                menuOptions: ExtraOptions.allCases,
                destinationSupplier: { menuOption in
                    switch menuOption {
                    case .Report:
                        ReportPostView(postMetadata: postMetadata)
                    }
                }
            ) { menuOption in
                switch menuOption {
                case .Report:
                    return (
                        viewStore.binding(
                            get: \.shouldNavigateToReportPostView,
                            send: .updateShouldNavigateToReportPostView(false)
                        ),
                        { viewStore.send(.updateShouldNavigateToReportPostView(true)) }
                    )
                }
            }
        }
    }
}
