//
//  ScrollViewParent.swift
//  build_app_source
//
//  Created by Matthew Dornfeld on 12/11/22.
//

import Bow
import ComposableArchitecture
import Foundation
import SwiftUI

/// Parent for a views for scrolling through posts
protocol ScrollViewParent: View {
    var postFeedMessenger: PostFeedMessenger { get }
    var backendMessenger: BackendMessenger { get }
    var notificationBannerViewStore: NotificationnotificationBannerViewStore { get }
}
