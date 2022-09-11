//
// Created by Matthew Dornfeld on 4/3/22.
//

import Bow
import Logging
import SwiftUI

public struct ImagePostView: View, Identifiable {
    private static let logger = Logger(label: String(describing: ImagePostView.self))
    public let id: UUID
    public let imagePostData: ImagePostData
    private let uiImage: UIImage
    public var body: some View {
        VStack {
            Image(uiImage: uiImage).resizable().scaledToFit()
            Text(imagePostData.caption)
        }
    }
    
    public static func create(_ imagePostData: ImagePostData) -> Either<PulpFictionRequestError, ImagePostView> {
        return imagePostData.imageJpg.toUIImage().mapRight{uiImage in
            ImagePostView(id: imagePostData.id, imagePostData: imagePostData, uiImage: uiImage)
        }.onError{ cause in
            logger.error("Error loading post \(imagePostData.postMetadata.postId) because \(cause)")
        }
    }
}

struct ImagePostView_Preview: PreviewProvider {
    static var previews: some View {
        let generateImagePostDataResult = Either<PulpFictionRequestError, ImagePostData>.var()
        let createImagePostViewResult = Either<PulpFictionRequestError, ImagePostView>.var()
        
        return binding(
            generateImagePostDataResult <- ImagePostData.generate(),
            createImagePostViewResult <- ImagePostView.create(generateImagePostDataResult.get),
            yield: createImagePostViewResult.get
        )^
            .mapLeft{cause in EmptyView()}
            .toEitherView()
    }
}
