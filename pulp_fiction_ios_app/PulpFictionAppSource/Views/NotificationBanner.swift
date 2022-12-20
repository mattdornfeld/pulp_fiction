//
//  Banner.swift
//  build_app_source
//
//  Created by Matthew Dornfeld on 12/17/22.
//

import ComposableArchitecture
import Foundation
import Logging
import SwiftUI

/// Reducer for NotifcationBanner
struct NotificationBannerReducer: ReducerProtocol {
    private let logger: Logger = .init(label: String(describing: NotificationBannerReducer.self))
    struct State: Equatable {
        /// If true will show NotificationBanner
        var shouldShowNotification: Bool = false
        /// Text displayed in NotficationBanner
        var notificationTextMaybe: String? = nil
        /// The BannerType
        var bannerTypeMaybe: BannerType? = nil

        /// Gets the bannerType or default if not specified
        func getBannerTypeOrDefault() -> BannerType {
            bannerTypeMaybe.getOrElse(.info)
        }

        /// Gets the notificationText or default if not specified
        func getNotificationTextOrDefault() -> String {
            notificationTextMaybe.getOrElse("")
        }
    }

    enum Action: Equatable {
        /// Shows  with the specified notificationText and BannerType
        case showNotificationBanner(String, BannerType)
        /// Hides the NotificationBanner
        case hideNotificationBanner
    }

    func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
        switch action {
        case let .showNotificationBanner(newAlertText, bannerType):
            state.shouldShowNotification = true
            state.notificationTextMaybe = newAlertText
            state.bannerTypeMaybe = bannerType

            logger.debug(
                "Showing NotificationBanner",
                metadata: [
                    "state": "\(state)",
                ]
            )

            return .none

        case .hideNotificationBanner:
            state.shouldShowNotification = false
            state.notificationTextMaybe = nil
            state.bannerTypeMaybe = nil

            logger.debug(
                "Hiding NotificationBanner",
                metadata: [
                    "state": "\(state)",
                ]
            )

            return .none
        }
    }

    enum BannerType: String, CaseIterable {
        /// Banner type for displaying information notifications
        case info
        /// Banner type for displaying success notifications
        case success
        /// Banner type for displaying error notifications
        case error

        var tintColor: Color {
            switch self {
            case .info:
                return .blue
            case .success:
                return .orange
            case .error:
                return .blue
            }
        }

        var sfSymbol: String {
            switch self {
            case .info:
                return "info.circle.fill"
            case .success:
                return "checkmark.seal"
            case .error:
                return "xmark.octagon"
            }
        }
    }
}

/// ViewStore for NotificationBanner
typealias NotificationnotificationBannerViewStore = ViewStore<NotificationBannerReducer.State, NotificationBannerReducer.Action>

/// Banner for displaying notifcations
struct NotificationBanner: View {
    /// ViewStore for NotificationBanner. Is passed down to child views so they can trigger notifications.
    @ObservedObject var viewStore: NotificationnotificationBannerViewStore = NotificationBanner.buildViewStore()

    var body: some View {
        if viewStore.shouldShowNotification {
            buildBanner()
        } else {
            EmptyView()
        }
    }

    /// Builds a NotificationnotificationBannerViewStore
    static func buildViewStore() -> NotificationnotificationBannerViewStore {
        let store = Store(
            initialState: NotificationBannerReducer.State(),
            reducer: NotificationBannerReducer()
        )
        return ViewStore(store)
    }

    @ViewBuilder
    private func buildBanner() -> some View {
        VStack {
            HStack {
                Image(systemName: viewStore.state.getBannerTypeOrDefault().sfSymbol)
                VStack(alignment: .leading, spacing: 2) {
                    Text(viewStore.state.getNotificationTextOrDefault()).bold()
                }
                Spacer()
            }
            .foregroundColor(Color.white)
            .padding(12)
            .background(viewStore.state.getBannerTypeOrDefault().tintColor)
            .cornerRadius(8)
            Spacer()
        }
        .padding()
        .animation(.easeInOut)
        .transition(AnyTransition.opacity)
        .onTapGesture {
            withAnimation {
                self.viewStore.send(.hideNotificationBanner)
                return ()
            }
        }.onAppear(perform: {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation {
                    self.viewStore.send(.hideNotificationBanner)
                    return ()
                }
            }
        })
    }
}
