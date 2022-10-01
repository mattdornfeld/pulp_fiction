//
// Created by Matthew Dornfeld on 4/3/22.
//

import Bow
import BowEffects
import Logging
import PhotosUI
import SwiftUI

public struct ScrollingContentView: View {
    private static let logger = Logger(label: String(describing: ScrollingContentView.self))
    private let backendMessenger: BackendMessenger
    private let postDataMessenger: PostDataMessenger

    public init(backendMessenger: BackendMessenger, postDataMessenger: PostDataMessenger) {
        self.backendMessenger = backendMessenger
        self.postDataMessenger = postDataMessenger
    }

    private func getImagePostViews() -> [ImagePostView] {
        let postProtos = backendMessenger
            .getGlobalPostFeed()
            .takeAll()

        let imagePostDataEithers = postProtos
            .map { postProto in
                postDataMessenger
                    .getPostData(postProto)
                    .unsafeRunSyncEither()
                    .flatMap { postDataOneOf in postDataOneOf.toImagePostData() }^
                    .logError("Error retrieving ImagePostData")
            }

        let userPostDataEithers = postProtos.map { postProto in
            postDataMessenger
                .getPostData(postProto.imagePost.postCreatorLatestUserPost)
                .unsafeRunSyncEither()
                .flatMap { postDataOneOf in postDataOneOf.toUserPostData() }^
                .logError("Error retrieving UserPostData")
        }

        return zip(imagePostDataEithers, userPostDataEithers).map { t2 in
            let imagePostDataEither = Either<PulpFictionRequestError, ImagePostData>.var()
            let userPostDataEither = Either<PulpFictionRequestError, UserPostData>.var()
            let imagePostViewEither = Either<PulpFictionRequestError, ImagePostView>.var()

            return binding(
                imagePostDataEither <- t2.0,
                userPostDataEither <- t2.1,
                imagePostViewEither <- ImagePostView
                    .create(imagePostDataEither.get, userPostDataEither.get)
                    .logError("Error Creating ImagePostView"),

                yield: imagePostViewEither.get
            )^
        }.flattenError()
    }

    public var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading) {
                ForEach(getImagePostViews()) { $0 }
            }
        }
    }
}
