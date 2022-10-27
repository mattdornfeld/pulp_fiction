//
//  PulpFictionTestClientBuilder.swift
//  PulpFictionApp
//
//  Created by Matthew Dornfeld on 9/22/22.
//

import Foundation
import GRPC
import protos_pulp_fiction_grpc_swift

/// Backend client used during testing and for the preview version of the app. Generates fake data on each request then returns it.
public class PulpFictionTestClientWithFakeData: PulpFictionClientProtocol {
    private let fakeChannel: FakeChannel
    public let numPostsInFeedResponse: Int
    public var channel: GRPC.GRPCChannel
    public var defaultCallOptions: GRPC.CallOptions = CallOptions()
    public var interceptors: PulpFiction_Protos_PulpFictionClientInterceptorFactoryProtocol?

    public init(numPostsInFeedResponse: Int) {
        fakeChannel = FakeChannel()
        channel = fakeChannel
        self.numPostsInFeedResponse = numPostsInFeedResponse
    }

    private func generatePostsForFeed(_ postGenerator: () -> Post) -> [Post] {
        (0 ..< numPostsInFeedResponse).map { _ in postGenerator() }
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
        _ request: GetFeedRequest,
        callOptions: CallOptions? = nil,
        handler: @escaping (GetFeedResponse) -> Void
    ) -> ServerStreamingCall<GetFeedRequest, GetFeedResponse> {
        let path = "/pulp_fiction.protos.PulpFiction/GetFeed"
        let stream: FakeStreamingResponse<GetFeedRequest, GetFeedResponse> = fakeChannel.makeFakeStreamingResponse(
            path: path,
            requestHandler: { _ in }
        )

        request.getFeedRequest.map { getFeedRequest in
            var posts: [Post] {
                switch getFeedRequest {
                case .getUserPostFeedRequest:
                    return generateImagePostsForFeed()
                case .getGlobalPostFeedRequest:
                    return generateImagePostsForFeed()
                case .getFollowingPostFeedRequest:
                    return generateImagePostsForFeed()
                case .getFollowingFeedRequest:
                    return generateUserPostsForFeed()
                case .getFollowersFeedRequest:
                    return generateUserPostsForFeed()
                case .getCommentFeedRequest:
                    let parentPostId = request
                        .getCommentFeedRequest
                        .postID
                        .toUUID()
                        .getOrElse(UUID())
                    return generateCommentPostsForFeed(parentPostId)
                }
            }

            let getFeedResponse = GetFeedResponse.with {
                $0.posts = posts
            }

            try! stream.sendMessage(getFeedResponse)
            try! stream.sendEnd()
        }

        return makeServerStreamingCall(
            path: path,
            request: request,
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
        _ request: GetFeedRequest,
        callOptions: CallOptions? = nil,
        handler: @escaping (GetFeedResponse) -> Void
    ) -> ServerStreamingCall<GetFeedRequest, GetFeedResponse> {
        switch self {
        case let pulpFictionTestClientWithFakeData as PulpFictionTestClientWithFakeData:
            return pulpFictionTestClientWithFakeData.getFeed(request, handler: handler)
        default:
            return getFeed(request, callOptions: callOptions, handler: handler)
        }
    }
}
