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
protocol ScrollViewParent: PulpFictionView {
    var notificationBannerViewStore: NotificationnotificationBannerViewStore { get }
}
