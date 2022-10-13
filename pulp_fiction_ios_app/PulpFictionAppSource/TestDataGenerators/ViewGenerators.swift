//
//  ViewGenerators.swift
//  build_app_source
//
//  Created by Matthew Dornfeld on 10/12/22.
//

import Bow
import BowEffects
import Foundation

public extension ImagePostView {
    static func generate(postFeedMessenger: PostFeedMessenger) -> IO<PulpFictionRequestError, ImagePostView> {
        let imagePostDataIO = IO<PulpFictionRequestError, ImagePostData>.var()
        let userPostDataIO = IO<PulpFictionRequestError, UserPostData>.var()
        let imagePostViewIO = IO<PulpFictionRequestError, ImagePostView>.var()

        return binding(
            imagePostDataIO <- ImagePostData.generate(),
            userPostDataIO <- UserPostData.generate(),
            imagePostViewIO <- ImagePostView.create(
                postViewIndex: 0,
                imagePostData: imagePostDataIO.get,
                userPostData: userPostDataIO.get,
                postFeedMessenger: postFeedMessenger
            ).toIO(),
            yield: imagePostViewIO.get
        )^
    }
}
