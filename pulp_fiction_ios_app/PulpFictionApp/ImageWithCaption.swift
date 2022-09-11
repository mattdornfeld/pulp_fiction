//
// Created by Matthew Dornfeld on 4/3/22.
//

import Bow
import Logging
import SwiftUI

public struct ImageWithCaption: View, Identifiable {
    private static let logger = Logger(label: String(describing: ImageWithCaption.self))
    public let id: UUID
    public let imagePostData: ImagePostData
    private let uiImage: UIImage
    public var body: some View {
        VStack {
            Image(uiImage: uiImage).resizable().scaledToFit()
            Text(imagePostData.caption)
        }
    }
    
    public static func create(_ imagePostData: ImagePostData) -> Either<PulpFictionRequestError, ImageWithCaption> {
        return imagePostData.imageJpg.toUIImage().mapRight{uiImage in
            ImageWithCaption(id: imagePostData.id, imagePostData: imagePostData, uiImage: uiImage)
        }.onError{ cause in
            logger.error("Error loading post \(imagePostData.postMetadata.postId) because \(cause)")
        }
    }
}
