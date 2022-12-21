//
//  CaptionCreatorView.swift
//  build_app_source
//
//  Created by Matthew Dornfeld on 11/14/22.
//

import ComposableArchitecture
import Foundation
import SwiftUI

/// View for creating and posting images + captions
struct CaptionCreator: View {
    let backendMessenger: BackendMessenger
    let uiImageMaybeSupplier: () -> UIImage?
    let notificationBannerViewStore: NotificationnotificationBannerViewStore
    @ObservedObject private var emptyNavigationLink: EmptyNavigationLink<BottomNavigationBarView>

    var editTextView: EditText {
        EditText(
            prompt: "Write a caption",
            createButtonLabel: "Post",
            createButtonAction: { state in
                if state.text.count == 0 {
                    return
                }

                await backendMessenger.createPostBackendMessenger.createImagePost(
                    uiImageMaybe: uiImageMaybeSupplier(),
                    caption: state.text
                ).processResponseFromServer(
                    notificationBannerViewStore: notificationBannerViewStore,
                    state: state,
                    path: "createImagePost"
                ).onSuccess { _ in
                    notificationBannerViewStore.send(.showNotificationBanner("Your post has been created!", .success))
                }

                self.emptyNavigationLink.viewStore.send(.navigateToDestionationView {})
            }
        )
    }

    init(
        loggedInUserPostData: UserPostData,
        postFeedMessenger: PostFeedMessenger,
        backendMessenger: BackendMessenger,
        notificationBannerViewStore: NotificationnotificationBannerViewStore,
        uiImageMaybeSupplier: @escaping () -> UIImage?
    ) {
        self.backendMessenger = backendMessenger
        self.notificationBannerViewStore = notificationBannerViewStore
        self.uiImageMaybeSupplier = uiImageMaybeSupplier
        emptyNavigationLink = EmptyNavigationLink(
            destination: BottomNavigationBarView(
                loggedInUserPostData: loggedInUserPostData,
                postFeedMessenger: postFeedMessenger,
                backendMessenger: backendMessenger,
                currentMainView: .loggedInUserProfileView
            )
        )
    }

    var body: some View {
        emptyNavigationLink.view
        editTextView
    }
}
