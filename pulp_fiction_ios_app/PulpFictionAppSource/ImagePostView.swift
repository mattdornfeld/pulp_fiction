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
    private let postUIImage: UIImage
    private let userAvatarUIImage: UIImage
    
    public var body: some View {
        VStack() {
            HStack{
                CircularImage(
                    uiImage: userAvatarUIImage,
                    radius: 15,
                    borderColor: .red,
                    borderWidth: 1
                ).padding(.leading, 5)
                BoldCaption(imagePostData.postMetadata.postCreatorMetadata.displayName)
                Spacer()
            }
            postUIImage.toImage().resizable().scaledToFit()
            HStack {
                VStack(alignment: .leading) {
                    HStack {
                        BoldCaption(imagePostData.postMetadata.postCreatorMetadata.displayName)
                        Caption(imagePostData.caption)
                    }
                    Caption(imagePostData.postMetadata.createdAt.formatAsStringForView()).foregroundColor(.gray)
                }
                Spacer()
            }
        }
    }

    public static func create(_ imagePostData: ImagePostData) -> Either<PulpFictionRequestError, ImagePostView> {
        let createPostUIImageResult = Either<PulpFictionRequestError, UIImage>.var()
        let createUserAvatarUIImageResult = Either<PulpFictionRequestError, UIImage>.var()
        
        return binding(
            createPostUIImageResult <- imagePostData.imageJpg.toUIImage(),
            createUserAvatarUIImageResult <- imagePostData.postMetadata.postCreatorMetadata.avatarImageJpg.toUIImage(),
            yield: ImagePostView(
                id: imagePostData.id,
                imagePostData: imagePostData,
                postUIImage: createPostUIImageResult.get,
                userAvatarUIImage: createUserAvatarUIImageResult.get
            )
        )^.onError { cause in
            logger.error("Error loading post \(imagePostData.postMetadata.postId) because \(cause)")
        }
    }
}
