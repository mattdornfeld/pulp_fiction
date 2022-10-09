//
// Created by Matthew Dornfeld on 4/3/22.
//

import Bow
import Logging
import SwiftUI

/// Renders an image post
public struct ImagePostView: PostView {
    private static let logger = Logger(label: String(describing: ImagePostView.self))
    public let id: Int
    public let imagePostData: ImagePostData
    public let creatorUserPostData: UserPostData
    private let postUIImage: UIImage
    private let userAvatarUIImage: UIImage

    public var body: some View {
        VStack {
            HStack(alignment: .bottom) {
                HStack {
                    CircularImage(
                        uiImage: userAvatarUIImage,
                        radius: 15,
                        borderColor: .red,
                        borderWidth: 1
                    ).padding(.leading, 5)
                    BoldCaption(creatorUserPostData.userDisplayName)
                }
                Spacer()
                Symbol(symbolName: "ellipsis")
                    .padding(.trailing, 10)
                    .padding(.bottom, 4)
            }
            postUIImage.toImage().resizable().scaledToFit()
            HStack {
                VStack(alignment: .leading) {
                    HStack {
                        SymbolWithCaption(
                            symbolName: "arrow.up",
                            symbolCaption: imagePostData.postInteractionAggregates.getNetLikes().formatAsStringForView()
                        )
                        SymbolWithCaption(
                            symbolName: "text.bubble",
                            symbolCaption: imagePostData.postInteractionAggregates.numChildComments.formatAsStringForView()
                        )
                    }.padding(.bottom, 1)
                    HStack {
                        BoldCaption(creatorUserPostData.userDisplayName)
                        Caption(imagePostData.caption)
                    }
                    Caption(imagePostData.postMetadata.createdAt.formatAsStringForView()).foregroundColor(.gray)
                }.padding(.leading, 4)
                Spacer()
            }
        }
    }

    public static func create(_ postViewIndex: Int, _ imagePostData: ImagePostData, _ userPostData: UserPostData) -> Either<PulpFictionRequestError, ImagePostView> {
        let createPostUIImageResult = Either<PulpFictionRequestError, UIImage>.var()
        let createUserAvatarUIImageResult = Either<PulpFictionRequestError, UIImage>.var()

        return binding(
            createPostUIImageResult <- imagePostData.imagePostContentData.toUIImage(),
            createUserAvatarUIImageResult <- userPostData.userPostContentData.toUIImage(),
            yield: ImagePostView(
                id: postViewIndex,
                imagePostData: imagePostData,
                creatorUserPostData: userPostData,
                postUIImage: createPostUIImageResult.get,
                userAvatarUIImage: createUserAvatarUIImageResult.get
            )
        )^.onError { cause in
            logger.error(
                "Error loading post \(imagePostData.postMetadata.postUpdateIdentifier)",
                metadata: [
                    "cause": "\(cause)",
                ]
            )
        }
    }
}
