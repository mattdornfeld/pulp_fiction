//
//  ReportPost.swift
//  build_app_source
//
//  Created by Matthew Dornfeld on 11/15/22.
//

import Bow
import ComposableArchitecture
import Foundation
import SwiftUI

/// Reducer for ReportPostView
struct ReportPostReducer: ReducerProtocol {
    let postMetadata: PostMetadata
    let backendMessenger: BackendMessenger
    let notificationBannerViewStore: NotificationnotificationBannerViewStore
    private let maxReportReasonSize: Int = 200

    struct State: Equatable {
        /// Caption being created
        var reportReason: String = ""
    }

    enum Action: Equatable {
        /// Updates the report reason as new characters are typed
        case updateReportReason(String)
        case reportPost(EquatableClosure0<Void>)
        case processUpdatePostResponse(Either<PulpFictionRequestError, UpdatePostResponse>, EquatableClosure0<Void>)
    }

    func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
        switch action {
        case let .updateReportReason(newReportReason):
            state.reportReason = String(newReportReason.prefix(maxReportReasonSize))
            return .none

        case let .reportPost(reportPostAction):
            if state.reportReason.count == 0 {
                return .none
            }

            reportPostAction()
            let reportReason = state.reportReason
            return .task {
                let updatePostResponseEither = await backendMessenger.reportPost(
                    postId: postMetadata.postUpdateIdentifier.postId,
                    reportReason: reportReason
                )
                return .processUpdatePostResponse(updatePostResponseEither, reportPostAction)
            }

        case let .processUpdatePostResponse(updatePostResponseEither, reportPostAction):
            updatePostResponseEither.processResponseFromServer(
                notificationBannerViewStore: notificationBannerViewStore,
                state: state,
                successAction: { notificationBannerViewStore.send(.showNotificationBanner("Post has been reported", .info)) }
            )
            reportPostAction()
            return .none
        }
    }
}

/// View for reporting a post
struct ReportPost: View {
    private let store: ComposableArchitecture.StoreOf<ReportPostReducer>
    @FocusState private var isInputFieldFocused: Bool
    @Environment(\.presentationMode) private var presentationMode: Binding<PresentationMode>

    init(postMetadata: PostMetadata,
         backendMessenger: BackendMessenger,
         notificationBannerViewStore: NotificationnotificationBannerViewStore)
    {
        store = Store(
            initialState: ReportPostReducer.State(),
            reducer: ReportPostReducer(
                postMetadata: postMetadata,
                backendMessenger: backendMessenger,
                notificationBannerViewStore: notificationBannerViewStore
            )
        )
    }

    var body: some View {
        WithViewStore(store) { viewStore in
            VStack {
                TextField(
                    "Reason for reporting this?",
                    text: viewStore.binding(
                        get: \.reportReason,
                        send: { reportReason in .updateReportReason(reportReason) }
                    ),
                    prompt: Text("Reason for reporting this?")
                )
                .foregroundColor(.gray)
                .focused($isInputFieldFocused)
                Spacer()
            }
            .onAppear {
                isInputFieldFocused = true
            }
            .toolbar {
                TextCreatorTopNavigationBar(createButtonLabel: "Report") {
                    viewStore.send(.reportPost(EquatableClosure0 { self.presentationMode.wrappedValue.dismiss() }))
                }
            }
        }
    }
}
