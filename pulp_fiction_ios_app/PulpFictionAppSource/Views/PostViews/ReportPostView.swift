//
//  ReportPostView.swift
//  build_app_source
//
//  Created by Matthew Dornfeld on 11/15/22.
//

import ComposableArchitecture
import Foundation
import SwiftUI

/// Reducer for ReportPostView
struct ReportPostReducer: ReducerProtocol {
    let postMetadata: PostMetadata
    private let maxReportReasonSize: Int = 100

    struct State: Equatable {
        /// Caption being created
        var reportReason: String = ""
    }

    enum Action {
        /// Updates the report reason as new characters are typed
        case updateReportReason(String)
        case reportPost(() -> Void)
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

            print(postMetadata)
            print(state.reportReason)
            reportPostAction()
            return .none
        }
    }
}

/// View for reporting a post
struct ReportPostView: View {
    private let store: ComposableArchitecture.StoreOf<ReportPostReducer>
    @FocusState private var isInputFieldFocused: Bool
    @Environment(\.presentationMode) private var presentationMode: Binding<PresentationMode>

    init(postMetadata: PostMetadata) {
        store = Store(
            initialState: ReportPostReducer.State(),
            reducer: ReportPostReducer(postMetadata: postMetadata)
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
                    viewStore.send(.reportPost { self.presentationMode.wrappedValue.dismiss() })
                }
            }
        }
    }
}
