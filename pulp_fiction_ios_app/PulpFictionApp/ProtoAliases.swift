//
//  ProtoAliases.swift
//  _idx_PictureSaverSource_6C36F415_ios_min15.0
//
//  Created by Matthew Dornfeld on 5/22/22.
//

import Foundation
import protos_pulp_fiction_grpc_stubs_swift
import protos_pulp_fiction_grpc_swift
import protos_pulp_fiction_proto
import SwiftProtobuf

public typealias Post = PulpFiction_Protos_Post
public typealias ImagePost = PulpFiction_Protos_Post.ImagePost
public typealias PulpFictionServiceClient = PulpFiction_Protos_PulpFictionClient
public typealias PulpFictionTestClient = PulpFiction_Protos_PulpFictionTestClient
public typealias PulpFictionClientProtocol = PulpFiction_Protos_PulpFictionClientProtocol
public typealias CreatePostRequest = PulpFiction_Protos_CreatePostRequest

public struct ImageWithMetadata: Equatable, Identifiable {
    public let id: String
    public var imageMetadata: ImageMetadata
    public var imageAsBase64Png: Data
    public var caption: String

    init(_ imageId: String, _ imageAsBase64Png: Data, _ createdAt: SwiftProtobuf.Google_Protobuf_Timestamp) {
        id = imageId
        imageMetadata = ImageMetadata(imageId, createdAt)
        caption = ""
        self.imageAsBase64Png = imageAsBase64Png
    }

    init(_ imageId: String, _ imageAsBase64Png: Data) {
        self.init(imageId, imageAsBase64Png, SwiftProtobuf.Google_Protobuf_Timestamp())
    }

    func serializedData() throws -> Data {
        return imageAsBase64Png
    }
}

public struct ImageMetadata: Equatable {
    public var imageID: String
    public var createdAt: SwiftProtobuf.Google_Protobuf_Timestamp

    init(_ imageId: String, _ createdAt: SwiftProtobuf.Google_Protobuf_Timestamp) {
        imageID = imageId
        self.createdAt = createdAt
    }
}
