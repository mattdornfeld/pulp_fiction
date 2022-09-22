//
//  PostDataGenerators.swift
//  PulpFictionApp
//
//  Created by Matthew Dornfeld on 9/21/22.
//

import Bow
import Foundation
import PulpFictionAppSource
import SwiftUI

public extension ImagePostData {
    class ErrorBuildingUIImage: PulpFictionRequestError {}
    class ErrorBuildingPostUIImage: ErrorBuildingUIImage {}
    class ErrorBuildingUserAvatarUIImage: ErrorBuildingUIImage {}

    static func generate() -> Either<PulpFictionRequestError, ImagePostData> {
        let postProto = Post.generate(Post.PostType.image)

        let serializePostImageResult = Either<PulpFictionRequestError, Data>.var()
        let serializeUserAvatarImageResult = Either<PulpFictionRequestError, Data>.var()
        let buildPostMetadataResult = Either<PulpFictionRequestError, PostMetadata>.var()
        return binding(
            serializePostImageResult <- UIImage
                .fromBundleFile(named: FakeData.imagePostJpgName)
                .toEither(ErrorBuildingPostUIImage())
                .flatMap { $0.serializeImage() },
            serializeUserAvatarImageResult <- UIImage
                .fromBundleFile(named: FakeData.userAvatarJpgName)
                .toEither(ErrorBuildingUserAvatarUIImage())
                .flatMap { $0.serializeImage() },
            buildPostMetadataResult <- postProto
                .metadata
                .toPostMetadata(serializeUserAvatarImageResult.get),
            yield: postProto
                .imagePost
                .toPostData(buildPostMetadataResult.get, serializePostImageResult.get)
        )^
    }
}
