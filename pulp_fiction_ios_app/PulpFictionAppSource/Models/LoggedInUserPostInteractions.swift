//
//  LoggedInUserPostInteractions.swift
//  build_app_source
//
//  Created by Matthew Dornfeld on 10/14/22.
//

import Foundation

public class LoggedInUserPostInteractions: Codable, Equatable {
    public let postLikeStatus: Post.PostLike
    
    public init(postLikeStatus: Post.PostLike) {
        self.postLikeStatus = postLikeStatus
    }
    
    required public convenience init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let postLikeRawValue = try values.decode(Int.self, forKey: .postLike)

        self.init(
            postLikeStatus: Post.PostLike(rawValue: postLikeRawValue) ?? Post.PostLike.UNRECOGNIZED(postLikeRawValue)
        )
    }
    
    public static func == (lhs: LoggedInUserPostInteractions, rhs: LoggedInUserPostInteractions) -> Bool {
        lhs.postLikeStatus == rhs.postLikeStatus
    }
}

public extension Post.LoggedInUserPostInteractions {
    func toLoggedInUserPostInteractions() -> LoggedInUserPostInteractions {
        LoggedInUserPostInteractions(postLikeStatus: postLike)
    }
}

public extension LoggedInUserPostInteractions {
    private enum CodingKeys: String, CodingKey {
        case postLike
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(postLikeStatus.rawValue, forKey: .postLike)
    }
}
