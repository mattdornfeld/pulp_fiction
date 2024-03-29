//
//  PostCreatorView.swift
//  build_app
//
//  Created by Matthew Dornfeld on 11/8/22.
//

import Foundation
import SwiftUI

/// Navigation bar for the PostCreatorView
struct PostCreatorTopNavigationBar: PulpFictionToolbarContent {
    /// The currently selected image source type for the drop down menu
    let currentImageSourceType: ImageSourceType
    /// Supplies the currently selected image
    let uiImageMaybeSupplier: () -> UIImage?
    /// UserPostData for the currently logged in user
    let loggedInUserPostData: UserPostData
    /// Container for external interface code
    let externalMessengers: ExternalMessengers
    /// Dropdown menu for selecting the image source type
    let imageSourceTypeDropDownMenuView: SymbolWithDropDownMenuView<ImageSourceType>
    let backendMessenger: BackendMessenger
    let notificationBannerViewStore: NotificationnotificationBannerViewStore

    var body: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Title("Create Post")
                .foregroundColor(.gray)
        }

        ToolbarItem(placement: .navigationBarTrailing) {
            HStack {
                imageSourceTypeDropDownMenuView
                Symbol(symbolName: "arrow.right", size: 20, color: .gray)
                    .navigateOnTap(destination: CaptionCreator(
                        loggedInUserPostData: loggedInUserPostData,
                        externalMessengers: externalMessengers,
                        notificationBannerViewStore: notificationBannerViewStore,
                        uiImageMaybeSupplier: uiImageMaybeSupplier
                    ))
            }
        }
    }
}

/// View for creating posts
struct PostCreatorView: PulpFictionView {
    let loggedInUserPostData: UserPostData
    let externalMessengers: ExternalMessengers
    let notificationBannerViewStore: NotificationnotificationBannerViewStore
    @ObservedObject private var imageSourceTypeDropDownMenu: SymbolWithDropDownMenu<ImageSourceType> = .init(
        symbolName: "line.3.horizontal.decrease.circle",
        symbolSize: 20,
        symbolColor: .gray,
        menuOptions: ImageSourceType.allCases,
        initialMenuSelection: .Album
    )

    var body: some View {
        ImageSelectorView(
            topNavigationBarSupplier: { viewStore in
                PostCreatorTopNavigationBar(
                    currentImageSourceType: imageSourceTypeDropDownMenu.currentSelection,
                    uiImageMaybeSupplier: { viewStore.postUIImageMaybe },
                    loggedInUserPostData: loggedInUserPostData,
                    externalMessengers: externalMessengers,
                    imageSourceTypeDropDownMenuView: imageSourceTypeDropDownMenu.view,
                    backendMessenger: backendMessenger,
                    notificationBannerViewStore: notificationBannerViewStore
                )
            },
            imageSourceType: imageSourceTypeDropDownMenu.currentSelection
        )
    }
}
