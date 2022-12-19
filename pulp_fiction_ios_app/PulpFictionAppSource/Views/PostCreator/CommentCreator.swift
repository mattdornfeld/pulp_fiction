//
//  CommentCreatorView.swift
//  build_app_source
//
//  Created by Matthew Dornfeld on 10/28/22.
//

import ComposableArchitecture
import Foundation
import SwiftUI

/// View for creating and posting comments
struct CommentCreator: View {
    let postMetadata: PostMetadata
    let backendMessenger: BackendMessenger
    let notificationnotificationBannerViewStore: NotificationnotificationBannerViewStore
    @Environment(\.presentationMode) private var presentationMode: Binding<PresentationMode>

    var body: some View {
        EditTextView(
            prompt: "Write a comment",
            createButtonLabel: "Comment",
            createButtonAction: { state in
                if state.text.count == 0 {
                    return
                }

                await backendMessenger.commentOnPost(
                    postId: postMetadata.postId,
                    commentBody: state.text
                ).processResponseFromServer(
                    notificationBannerViewStore: notificationnotificationBannerViewStore,
                    state: state,
                    successAction: {
                        notificationnotificationBannerViewStore.send(.showNotificationBanner("Your comment has been created!", .success))
                    }
                )

                self.presentationMode.wrappedValue.dismiss()
            }
        )
    }
}
