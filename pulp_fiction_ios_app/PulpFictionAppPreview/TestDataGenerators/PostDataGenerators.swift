//
//  PostDataGenerators.swift
//  PulpFictionApp
//
//  Created by Matthew Dornfeld on 9/21/22.
//

import Bow
import BowEffects
import Foundation
import PulpFictionAppSource
import SwiftUI

public extension ImagePostData {
    class ErrorBuildingPostUIImage: PulpFictionRequestError {}

    static func generate() -> IO<PulpFictionRequestError, ImagePostData> {
        let postProto = Post.generate(Post.PostType.image)

        let postImageContentDataIO = IO<PulpFictionRequestError, ContentData>.var()
        let buildPostMetadataIO = IO<PulpFictionRequestError, PostMetadata>.var()
        return binding(
            postImageContentDataIO <- UIImage
                .fromBundleFile(named: FakeData.imagePostJpgName)
                .toEither(ErrorBuildingPostUIImage())
                .flatMap { $0.toContentData() }^
                .toIO(),
            buildPostMetadataIO <- postProto
                .metadata
                .toPostMetadata()
                .toIO(),
            yield: postProto
                .imagePost
                .toPostData(buildPostMetadataIO.get, postImageContentDataIO.get)
        )^
    }
}

public extension UserPostData {
    class ErrorBuildingUserAvatarUIImage: PulpFictionRequestError {}

    static func generate() -> IO<PulpFictionRequestError, UserPostData> {
        let postProto = Post.generate(Post.PostType.user)

        let serializeUserAvatarImageIO = IO<PulpFictionRequestError, ContentData>.var()
        let buildPostMetadataIO = IO<PulpFictionRequestError, PostMetadata>.var()
        return binding(
            serializeUserAvatarImageIO <- UIImage
                .fromBundleFile(named: FakeData.userAvatarJpgName)
                .toEither(ErrorBuildingUserAvatarUIImage())
                .flatMap { $0.toContentData() }^
                .toIO(),
            buildPostMetadataIO <- postProto
                .metadata
                .toPostMetadata()
                .toIO(),
            yield: postProto
                .userPost
                .toPostData(buildPostMetadataIO.get, serializeUserAvatarImageIO.get)
        )^
    }
}
