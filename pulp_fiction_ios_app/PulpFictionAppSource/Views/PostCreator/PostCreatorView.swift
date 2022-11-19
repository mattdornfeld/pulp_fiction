//
//  PostCreatorView.swift
//  build_app
//
//  Created by Matthew Dornfeld on 11/8/22.
//

import Foundation
import SwiftUI

/// View for creating posts
struct PostCreatorView: View {
    let loggedInUserPostData: UserPostData
    let postFeedMessenger: PostFeedMessenger

    var body: some View {
        ImageSelectorView(
            topNavigationBarSupplier: { viewStore in
                PostCreatorTopNavigationBar(
                    currentImageSourceType: ImageSourceType.Album,
                    uiImageMaybeSupplier: { viewStore.postUIImageMaybe },
                    loggedInUserPostData: loggedInUserPostData,
                    postFeedMessenger: postFeedMessenger
                )
            }
        )
    }
}
