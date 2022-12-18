//
//  ExtraOptionsDropDownMenuView.swift
//  build_app_source
//
//  Created by Matthew Dornfeld on 11/16/22.
//

import ComposableArchitecture
import Foundation
import SwiftUI

/// Reducer for ExtraOptionsDropDownMenuView
struct ExtraOptionsDropDownMenuReducer: ReducerProtocol {
    struct State: Equatable {
        /// If true will show the delete post menu
        var showShowDeletePostMenu: Bool = false
        /// If true will show the report post view
        var shouldNavigateToReportPostView: Bool = false
    }

    enum Action {
        /// Update showShowDeletePostMenu
        case updateShowShowDeletePostMenu(Bool)
        /// Update shouldNavigateToReportPostView
        case updateShouldNavigateToReportPostView(Bool)
    }

    func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
        switch action {
        case let .updateShowShowDeletePostMenu(newShouldShowDeletePostMenu):
            state.showShowDeletePostMenu = newShouldShowDeletePostMenu
            return .none

        case let .updateShouldNavigateToReportPostView(newShouldNavigateToReportPostView):
            state.shouldNavigateToReportPostView = newShouldNavigateToReportPostView
            return .none
        }
    }
}

/// View that shows the extra options for post actions
struct ExtraOptionsDropDownMenuView: View {
    let postMetadata: PostMetadata
    let backendMessenger: BackendMessenger
    let notificationBannerViewStore: NotificationnotificationBannerViewStore
    @ObservedObject private var viewStore: PulpFictionViewStore<ExtraOptionsDropDownMenuReducer>

    /// Enumeration of the extra post action
    enum ExtraOptions: String, NavigationDropDownMenuOption {
        /// Delete a post
        case Delete
        /// Report a post
        case Report

        var isNavigationOption: Bool {
            switch self {
            case .Delete:
                return false
            case .Report:
                return false
            }
        }

        @ViewBuilder func destinationViewBuilder(postMetadata: PostMetadata) -> some View {
            switch self {
            case .Delete:
                EmptyView()
            case .Report:
                ReportPostView(postMetadata: postMetadata)
            }
        }

        func getNavigationAction(viewStore: PulpFictionViewStore<ExtraOptionsDropDownMenuReducer>) -> (Binding<Bool>, () -> Void) {
            switch self {
            case .Delete:
                return (
                    viewStore.binding(
                        get: \.showShowDeletePostMenu,
                        send: .updateShowShowDeletePostMenu(false)
                    ),
                    { viewStore.send(.updateShowShowDeletePostMenu(true)) }
                )

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

    init(
        postMetadata: PostMetadata,
        backendMessenger: BackendMessenger,
        notificationBannerViewStore: NotificationnotificationBannerViewStore
    ) {
        self.postMetadata = postMetadata
        self.backendMessenger = backendMessenger
        self.notificationBannerViewStore = notificationBannerViewStore
        viewStore = ExtraOptionsDropDownMenuView.buildViewStore()
    }

    static func buildViewStore() -> PulpFictionViewStore<ExtraOptionsDropDownMenuReducer> {
        let store = Store(
            initialState: ExtraOptionsDropDownMenuReducer.State(),
            reducer: ExtraOptionsDropDownMenuReducer()
        )
        return ViewStore(store)
    }

    var body: some View {
        LabelWithDropDownNavigationMenu(
            label: Symbol(symbolName: "ellipsis")
                .padding(.trailing, 10)
                .padding(.bottom, 4),
            menuOptions: ExtraOptions.allCases,
            destinationSupplier: { menuOption in
                menuOption.destinationViewBuilder(postMetadata: postMetadata)
            }
        ) { menuOption in
            menuOption.getNavigationAction(viewStore: viewStore)
        }.sheet(isPresented: viewStore.binding(
            get: \.showShowDeletePostMenu,
            send: .updateShowShowDeletePostMenu(false)
        )) {
            DeletePostMenu(
                postMetadata: postMetadata,
                extraOptionsDropDownMenuViewStore: viewStore,
                backendMessenger: backendMessenger,
                notificationBannerViewStore: notificationBannerViewStore
            )
        }
    }
}
