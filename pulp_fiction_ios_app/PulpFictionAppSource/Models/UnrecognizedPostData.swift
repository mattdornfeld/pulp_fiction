//
//  UnrecognizedPostData.swift
//  build_app_source
//
//  Created by Matthew Dornfeld on 9/25/22.
//

import Foundation

/// For error handling if an unrecognized post type is matched on. Should never be instantiated.
public struct UnrecognizedPostData: PostData, PostDataIdentifiable, Equatable {
    public let id: PostUpdateIdentifier
    public let postMetadata: PostMetadata

    public func toPostDataOneOf() -> PostDataOneOf {
        PostDataOneOf.unregonizedPostData(self)
    }
}

public extension UnrecognizedPostData {
    init(_ postMetadata: PostMetadata) {
        self.init(id: postMetadata.id, postMetadata: postMetadata)
    }
}
