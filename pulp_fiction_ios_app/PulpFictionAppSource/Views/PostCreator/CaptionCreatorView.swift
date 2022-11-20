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
    @ObservedObject private var emptyNavigationLink: EmptyNavigationLink<BottomNavigationBarView>

    init(
        loggedInUserPostData: UserPostData,
        postFeedMessenger: PostFeedMessenger,
        uiImageMaybeSupplier: @escaping () -> UIImage?
    ) {
        self.uiImageMaybeSupplier = uiImageMaybeSupplier
        emptyNavigationLink = EmptyNavigationLink(
            destination: BottomNavigationBarView(
                loggedInUserPostData: loggedInUserPostData,
                postFeedMessenger: postFeedMessenger,
                currentMainView: .loggedInUserProfileView
            )
        )
    }

    var body: some View {
        emptyNavigationLink.view

        EditTextView(
            prompt: "Write a caption",
            createButtonLabel: "Post",
            createButtonAction: { caption in
                if caption.count == 0 {
                    return
                }

                if let uiImage = uiImageMaybeSupplier() {
                    print("Creating post")
                    print("caption: \(caption)")
                    print("image: \(uiImage)")
                }
                self.emptyNavigationLink.viewStore.send(.updateShouldLoadDestionationView(true))
            }
        )
    }
}
