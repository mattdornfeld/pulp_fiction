//
//  PulpFictionTestClientBuilder.swift
//  PulpFictionApp
//
//  Created by Matthew Dornfeld on 9/22/22.
//

import Foundation
import GRPC
import Logging
import protos_pulp_fiction_grpc_swift

/// Backend client used during testing and for the preview version of the app. Generates fake data on each request then returns it.
public class PulpFictionTestClientWithFakeData: PulpFictionClientProtocol {
    private let fakeChannel: FakeChannel
    private let logger: Logger = .init(label: String(describing: PulpFictionTestClientWithFakeData.self))
    public var channel: GRPC.GRPCChannel
    public var defaultCallOptions: GRPC.CallOptions = CallOptions()
    public var interceptors: PulpFiction_Protos_PulpFictionClientInterceptorFactoryProtocol?

    public init() {
        fakeChannel = .init()
        channel = fakeChannel
    }

    private func generatePostsForFeed(_ postGenerator: () -> Post) -> [Post] {
        (0 ..< PostFeedConfigs.numPostReturnedPerRequest).map { _ in postGenerator() }
    }

    private func generateImagePostsForFeed() -> [Post] {
        generatePostsForFeed { Post.generate(Post.PostType.image) }
    }

    private func generateUserPostsForFeed() -> [Post] {
        generatePostsForFeed { Post.generate(Post.PostType.user) }
    }

    private func generateCommentPostsForFeed(_ parentPostId: UUID) -> [Post] {
        generatePostsForFeed {
            let postMetadata = Post.PostMetadata.generate(Post.PostType.comment)
            return Post.Comment
                .generate(parentPostId: parentPostId)
                .toPost(postMetadata)
        }
    }

    public func getFeed(
        callOptions: CallOptions? = nil,
        handler: @escaping (GetFeedResponse) -> Void
    ) -> BidirectionalStreamingCall<GetFeedRequest, GetFeedResponse> {
        let path = "/pulp_fiction.protos.PulpFiction/GetFeed"
        var responseBuffer: Queue<GetFeedResponse> = .init(maxSize: 1)
        let stream: FakeStreamingResponse<GetFeedRequest, GetFeedResponse> = fakeChannel.makeFakeStreamingResponse(
            path: path,
            requestHandler: { fakeRequestPart in
                switch fakeRequestPart {
                case let .message(getFeedRequest):
                    self.logger.debug(
                        "Received getFeedRequest",
                        metadata: [
                            "thread": "\(Thread.current.hashValue)",
                            "getFeedRequest": "\(getFeedRequest.getFeedRequest)",
                        ]
                    )

                    var posts: [Post] {
                        switch getFeedRequest.getFeedRequest {
                        case .getUserPostFeedRequest:
                            return self.generateImagePostsForFeed()
                        case .getGlobalPostFeedRequest:
                            return self.generateImagePostsForFeed()
                        case .getFollowingPostFeedRequest:
                            return self.generateImagePostsForFeed()
                        case .getFollowingFeedRequest:
                            return self.generateUserPostsForFeed()
                        case .getFollowersFeedRequest:
                            return self.generateUserPostsForFeed()
                        case .getCommentFeedRequest:
                            let parentPostId = getFeedRequest
                                .getCommentFeedRequest
                                .postID
                                .toUUID()
                                .getOrElse(UUID())
                            return self.generateCommentPostsForFeed(parentPostId)
                        case .none:
                            return []
                        }
                    }

                    let getFeedResponse = GetFeedResponse.with {
                        $0.posts = posts
                    }

                    responseBuffer.enqueue(getFeedResponse)

                case .metadata:
                    return
                case .end:
                    return
                }
            }
        )

        DispatchQueue.global(qos: .userInitiated).async {
            while true {
                responseBuffer.dequeue().map { getFeedResponse in
                    self.logger.debug(
                        "Sending getFeedResponse",
                        metadata: [
                            "thread": "\(Thread.current.hashValue)",
                            "numPosts": "\(getFeedResponse.posts.count)",
                        ]
                    )
                    try! stream.sendMessage(getFeedResponse)
                }
            }
        }

        return makeBidirectionalStreamingCall(
            path: path,
            callOptions: callOptions ?? defaultCallOptions,
            interceptors: interceptors?.makeGetFeedInterceptors() ?? [],
            handler: handler
        )
    }
}

/// This is the only way to get the code to use the test clients methods during test time.
/// This is because the real client method's are implemented using extension methods
public extension PulpFictionClientProtocol {
    func getFeed(
        callOptions: CallOptions? = nil,
        handler: @escaping (GetFeedResponse) -> Void
    ) -> BidirectionalStreamingCall<GetFeedRequest, GetFeedResponse> {
        switch self {
        case let pulpFictionTestClientWithFakeData as PulpFictionTestClientWithFakeData:
            return pulpFictionTestClientWithFakeData.getFeed(handler: handler)
        default:
            return getFeed(callOptions: callOptions, handler: handler)
        }
    }
}
