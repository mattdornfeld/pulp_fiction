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
import SwiftProtobuf

/// Backend client used during testing and for the preview version of the app. Generates fake data on each request then returns it.
public class PulpFictionTestClientWithFakeData: PulpFictionClientProtocol {
    private let fakeChannel: FakeChannel
    private let logger: Logger = .init(label: String(describing: PulpFictionTestClientWithFakeData.self))
    public var channel: GRPC.GRPCChannel
    public var defaultCallOptions: GRPC.CallOptions = CallOptions()
    public var interceptors: PulpFiction_Protos_PulpFictionClientInterceptorFactoryProtocol?
    var requestBuffers: RequestBuffers = .init()

    static let createLoginSessionResponse: CreateLoginSessionResponse = {
        let userMetadataProto = UserMetadataProto.generate()
        return CreateLoginSessionResponse.with {
            $0.loginSession = CreateLoginSessionResponse.LoginSession.with {
                $0.sessionToken = UUID().uuidString
                $0.userID = userMetadataProto.userID
                $0.createdAt = .init(date: .now)
                $0.deviceID = UUID().uuidString
                $0.userMetadata = userMetadataProto
            }
        }
    }()

    private enum Path: String {
        case createLoginSession = "/pulp_fiction.protos.PulpFiction/CreateLoginSession"
        case createPost = "/pulp_fiction.protos.PulpFiction/CreatePost"
        case createUser = "/pulp_fiction.protos.PulpFiction/CreateUser"
        case getFeed = "/pulp_fiction.protos.PulpFiction/GetFeed"
        case updateLoginSession = "/pulp_fiction.protos.PulpFiction/UpdateLoginSession"
        case updatePost = "/pulp_fiction.protos.PulpFiction/UpdatePost"
        case updateUser = "/pulp_fiction.protos.PulpFiction/UpdateUser"
    }

    class RequestBuffers {
        var createLoginSession: [CreateLoginSessionRequest] = .init()
        var createPost: [CreatePostRequest] = .init()
        var createUser: [CreateUserRequest] = .init()
        var getFeed: [GetFeedRequest] = .init()
        var updateLoginSession: [UpdateLoginSessionRequest] = .init()
        var updatePost: [UpdatePostRequest] = .init()
        var updateUser: [UpdateUserRequest] = .init()
    }

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
        var responseBuffer: Queue<GetFeedResponse> = .init(maxSize: 1)
        let stream: FakeStreamingResponse<GetFeedRequest, GetFeedResponse> = fakeChannel.makeFakeStreamingResponse(
            path: Path.getFeed.rawValue,
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

                    self.requestBuffers.getFeed.append(getFeedRequest)

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
                    responseBuffer.close()
                }
            }
        )

        DispatchQueue.global(qos: .userInitiated).async {
            while true {
                if responseBuffer.isClosed() {
                    break
                }

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
            path: Path.getFeed.rawValue,
            callOptions: callOptions ?? defaultCallOptions,
            interceptors: interceptors?.makeGetFeedInterceptors() ?? [],
            handler: handler
        )
    }

    private func processUnaryRequest<Request: SwiftProtobuf.Message, Response: SwiftProtobuf.Message>(
        request: Request,
        responseSupplier: @escaping (Request) -> Response,
        path: Path
    ) -> UnaryCall<Request, Response> where Response: Equatable {
        logger.debug(
            "Received request",
            metadata: [
                "request": "\(request)",
                "path": "\(path.rawValue)",
            ]
        )

        let responseBuffer: Queue<Response> = .init(maxSize: 1)
        let stream: FakeUnaryResponse<Request, Response> = fakeChannel.makeFakeUnaryResponse(path: path.rawValue) { fakeRequestPart in
            switch fakeRequestPart {
            case let .message(request):
                switch request {
                case let request as CreateLoginSessionRequest:
                    self.requestBuffers.createLoginSession.append(request)
                case let request as CreatePostRequest:
                    self.requestBuffers.createPost.append(request)
                case let request as UpdateLoginSessionRequest:
                    self.requestBuffers.updateLoginSession.append(request)
                case let request as UpdateUserRequest:
                    self.requestBuffers.updateUser.append(request)
                case let request as UpdatePostRequest:
                    self.requestBuffers.updatePost.append(request)
                default:
                    break
                }

                responseBuffer.enqueue(responseSupplier(request))
                /// TODO (matt): For some reason tests fails if you take out this sleep. Unclear why.
                /// Figure out in future. This code block is only run in tests.
                Thread.sleep(forTimeInterval: 0.05)
            case .end:
                responseBuffer.close()
            default:
                return
            }
        }

        DispatchQueue.global(qos: .userInitiated).async {
            responseBuffer.dequeue().map { response in
                self.logger.debug(
                    "Sending response",
                    metadata: [
                        "response": "\(response)",
                        "path": "\(path.rawValue)",
                    ]
                )

                try! stream.sendMessage(response)
            }
        }

        return makeUnaryCall(
            path: path.rawValue,
            request: request
        )
    }

    public func createLoginSession(
        _ request: CreateLoginSessionRequest,
        callOptions _: CallOptions? = nil
    ) -> UnaryCall<CreateLoginSessionRequest, CreateLoginSessionResponse> {
        let userMetadataProto = UserMetadataProto.generate()
        return processUnaryRequest(
            request: request,
            responseSupplier: { _ in PulpFictionTestClientWithFakeData.createLoginSessionResponse },
            path: Path.createPost
        )
    }

    public func createUser(
        _ request: CreateUserRequest,
        callOptions _: CallOptions? = nil
    ) -> UnaryCall<CreateUserRequest, CreateUserResponse> {
        processUnaryRequest(
            request: request,
            responseSupplier: { _ in CreateUserResponse() },
            path: Path.createUser
        )
    }

    public func createPost(
        _ request: CreatePostRequest,
        callOptions _: CallOptions? = nil
    ) -> UnaryCall<CreatePostRequest, CreatePostResponse> {
        processUnaryRequest(
            request: request,
            responseSupplier: { _ in CreatePostResponse() },
            path: Path.createPost
        )
    }

    public func updateLoginSession(
        _ request: UpdateLoginSessionRequest,
        callOptions _: CallOptions? = nil
    ) -> UnaryCall<UpdateLoginSessionRequest, UpdateLoginSessionResponse> {
        processUnaryRequest(
            request: request,
            responseSupplier: { _ in UpdateLoginSessionResponse() },
            path: Path.updateLoginSession
        )
    }

    public func updatePost(
        _ request: UpdatePostRequest,
        callOptions _: CallOptions? = nil
    ) -> UnaryCall<UpdatePostRequest, UpdatePostResponse> {
        processUnaryRequest(
            request: request,
            responseSupplier: { _ in UpdatePostResponse() },
            path: Path.updatePost
        )
    }

    public func updateUser(
        _ request: UpdateUserRequest,
        callOptions _: CallOptions? = nil
    ) -> UnaryCall<UpdateUserRequest, UpdateUserResponse> {
        processUnaryRequest(
            request: request,
            responseSupplier: { _ in UpdateUserResponse() },
            path: Path.updateUser
        )
    }
}

/// This is the only way to get the code to use the test clients methods during test time.
/// This is because the real client method's are implemented using extension methods
public extension PulpFictionClientProtocol {
    private func getClient() -> PulpFictionClientProtocol {
        switch self {
        case let pulpFictionTestClientWithFakeData as PulpFictionTestClientWithFakeData:
            return pulpFictionTestClientWithFakeData
        default:
            return self
        }
    }

    func getFeed(
        callOptions: CallOptions? = nil,
        handler: @escaping (GetFeedResponse) -> Void
    ) -> BidirectionalStreamingCall<GetFeedRequest, GetFeedResponse> {
        getClient().getFeed(callOptions: callOptions, handler: handler)
    }

    func createLoginSession(
        _ request: CreateLoginSessionRequest,
        callOptions: CallOptions? = nil
    ) -> UnaryCall<CreateLoginSessionRequest, CreateLoginSessionResponse> {
        getClient().createLoginSession(request, callOptions: callOptions)
    }

    func createPost(
        _ request: CreatePostRequest,
        callOptions: CallOptions? = nil
    ) -> UnaryCall<CreatePostRequest, CreatePostResponse> {
        getClient().createPost(request, callOptions: callOptions)
    }

    func createUser(
        _ request: CreateUserRequest,
        callOptions: CallOptions? = nil
    ) -> UnaryCall<CreateUserRequest, CreateUserResponse> {
        getClient().createUser(request, callOptions: callOptions)
    }

    func updateLoginSession(
        _ request: UpdateLoginSessionRequest,
        callOptions: CallOptions? = nil
    ) -> UnaryCall<UpdateLoginSessionRequest, UpdateLoginSessionResponse> {
        getClient().updateLoginSession(request, callOptions: callOptions)
    }

    func updatePost(
        _ request: UpdatePostRequest,
        callOptions: CallOptions? = nil
    ) -> UnaryCall<UpdatePostRequest, UpdatePostResponse> {
        getClient().updatePost(request, callOptions: callOptions)
    }

    func updateUser(
        _ request: UpdateUserRequest,
        callOptions: CallOptions? = nil
    ) -> UnaryCall<UpdateUserRequest, UpdateUserResponse> {
        getClient().updateUser(request, callOptions: callOptions)
    }
}
