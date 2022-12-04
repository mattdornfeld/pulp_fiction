//
//  PostCreatorView.swift
//  build_app
//
//  Created by Matthew Dornfeld on 11/8/22.
//

import Foundation
import SwiftUI

/// Navigation bar for the PostCreatorView
struct PostCreatorTopNavigationBar: ToolbarContent {
    /// The currently selected image source type for the drop down menu
    let currentImageSourceType: ImageSourceType
    /// Supplies the currently selected image
    let uiImageMaybeSupplier: () -> UIImage?
    /// UserPostData for the currently logged in user
    let loggedInUserPostData: UserPostData
    /// The post feed messenger
    let postFeedMessenger: PostFeedMessenger
    /// Dropdown menu for selecting the image source type
    let imageSourceTypeDropDownMenuView: SymbolWithDropDownMenuView<ImageSourceType>

    var body: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Title("Create Post")
                .foregroundColor(.gray)
        }

        ToolbarItem(placement: .navigationBarTrailing) {
            HStack {
                imageSourceTypeDropDownMenuView
                Symbol(symbolName: "arrow.right", size: 20, color: .gray)
                    .navigateOnTap(destination: CaptionCreatorView(
                        loggedInUserPostData: loggedInUserPostData,
                        postFeedMessenger: postFeedMessenger,
                        uiImageMaybeSupplier: uiImageMaybeSupplier
                    ))
            }
        }
    }
}

/// View for creating posts
struct PostCreatorView: View {
    let loggedInUserPostData: UserPostData
    let postFeedMessenger: PostFeedMessenger
    @ObservedObject private var imageSourceTypeDropDownMenu: SymbolWithDropDownMenu<ImageSourceType> = .init(
        symbolName: "line.3.horizontal.decrease.circle",
        symbolSize: 20,
        symbolColor: .gray,
        menuOptions: ImageSourceType.allCases,
        initialMenuSelection: .Camera
    )

    var body: some View {
        ImageSelectorView(
            topNavigationBarSupplier: { viewStore in
                PostCreatorTopNavigationBar(
                    currentImageSourceType: ImageSourceType.Album,
                    uiImageMaybeSupplier: { viewStore.postUIImageMaybe },
                    loggedInUserPostData: loggedInUserPostData,
                    postFeedMessenger: postFeedMessenger,
                    imageSourceTypeDropDownMenuView: imageSourceTypeDropDownMenu.view
                )
            },
            imageSourceType: imageSourceTypeDropDownMenu.currentSelection
        )
    }
}
