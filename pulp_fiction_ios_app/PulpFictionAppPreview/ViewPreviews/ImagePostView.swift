//
//  ImagePostView.swift
//  PulpFictionApp
//
//  Created by Matthew Dornfeld on 9/13/22.
//

import Bow
import PulpFictionAppSource
import SwiftUI

struct ImagePostView_Preview: PreviewProvider {
    static var previews: some View {
        let generateImagePostDataResult = Either<PulpFictionRequestError, ImagePostData>.var()
        let createImagePostViewResult = Either<PulpFictionRequestError, ImagePostView>.var()

        return binding(
            generateImagePostDataResult <- ImagePostData.generate(),
            createImagePostViewResult <- ImagePostView.create(generateImagePostDataResult.get),
            yield: createImagePostViewResult.get
        )^
            .mapLeft { _ in EmptyView() }
            .toEitherView()
    }
}
