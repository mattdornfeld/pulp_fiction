//
//  PostFeedConfigs.swift
//  build_app_source
//
//  Created by Matthew Dornfeld on 9/30/22.
//

import Foundation

/// Configs for reading the post feed
struct PostFeedConfigs {
    /// The size of the internal queue used to to store post feed results
    static let postFeedMaxQueueSize = 20
    /// The number of post views loaded in advance of the current scroll offset
    static let numPostViewsLoadedInAdvance = 5
}
