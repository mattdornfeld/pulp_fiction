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

    private func generatePostsForFeed(_ postType: Post.PostType) -> [Post] {
        (0 ..< numPostsInFeedResponse).map { _ in Post.generate(postType) }
    }

    private func generateGetFeedResponse(_ postType: Post.PostType) -> GetFeedResponse {
        GetFeedResponse.with {
            $0.posts = generatePostsForFeed(postType)
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
            var postType: Post.PostType {
                switch getFeedRequest {
                case .getUserFeedRequest:
                    return Post.PostType.image
                case .getGlobalFeedRequest:
                    return Post.PostType.image
                case .getFollowedFeedRequest:
                    return Post.PostType.user
                case .getCommentFeedRequest:
                    return Post.PostType.comment
                }
            }

            try! stream.sendMessage(generateGetFeedResponse(postType))
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
