//
//  PostInteractionAggregates.swift
//  build_app_source
//
//  Created by Matthew Dornfeld on 9/25/22.
//

import Foundation

/// Aggregares post interactions such as likes and dislikes
public struct PostInteractionAggregates: Codable, Equatable {
    public let numLikes: Int64
    public let numDislikes: Int64
    public let numChildComments: Int64

    func getNetLikes() -> Int64 {
        numLikes - numDislikes
    }
}

public extension Post.InteractionAggregates {
    func toPostInteractionAggregates() -> PostInteractionAggregates {
        PostInteractionAggregates(
            numLikes: numLikes,
            numDislikes: numDislikes,
            numChildComments: numChildComments
        )
    }
}
