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
struct CaptionCreatorView: View {
    private let uiImageMaybeSupplier: () -> UIImage?
    private let displayBannerNotificationCallback: () -> Void
    @ObservedObject private var emptyNavigationLink: EmptyNavigationLink<BottomNavigationBarView>

    init(
        loggedInUserPostData: UserPostData,
        postFeedMessenger: PostFeedMessenger,
        backendMessenger: BackendMessenger,
        notificationBannerViewStore: NotificationnotificationBannerViewStore,
        uiImageMaybeSupplier: @escaping () -> UIImage?
    ) {
        self.uiImageMaybeSupplier = uiImageMaybeSupplier
        displayBannerNotificationCallback = {
            notificationBannerViewStore.send(.showNotificationBanner("Your post has been created!", .success))
        }
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

        EditText(
            prompt: "Write a caption",
            createButtonLabel: "Post",
            createButtonAction: { state in
                if state.text.count == 0 {
                    return
                }

                self.emptyNavigationLink.viewStore.send(.navigateToDestionationView(displayBannerNotificationCallback))
            }
        )
    }
}
