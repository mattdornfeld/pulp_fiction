//
//  CommentView.swift
//  build_app_source
//
//  Created by Matthew Dornfeld on 10/9/22.
//

import Bow
import Foundation
import Logging
import SwiftUI

public struct CommentView: PostView {
    private static let logger = Logger(label: String(describing: CommentView.self))
    public let commentPostData: CommentPostData
    public let creatorUserPostData: UserPostData
    public let id: Int
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
            Caption(commentPostData.body)
            HStack {
                VStack(alignment: .leading) {
                    HStack {
                        SymbolWithCaption(
                            symbolName: "arrow.up",
                            symbolCaption: commentPostData.postInteractionAggregates.getNetLikes().formatAsStringForView()
                        )
                    }.padding(.bottom, 1)
                    Caption(commentPostData.postMetadata.createdAt.formatAsStringForView()).foregroundColor(.gray)
                }.padding(.leading, 4)
                Spacer()
            }
        }
    }
    
    public static func create(_ postViewIndex: Int, _ commentPostData: CommentPostData, _ userPostData: UserPostData) -> Either<PulpFictionRequestError, CommentView> {
        let userAvatarUIImageEither = Either<PulpFictionRequestError, UIImage>.var()

        return binding(
            userAvatarUIImageEither <- userPostData.userPostContentData.toUIImage(),
            yield: CommentView(
                commentPostData: commentPostData,
                creatorUserPostData: userPostData,
                id: postViewIndex,
                userAvatarUIImage: userAvatarUIImageEither.get)
        )^.onError { cause in
            logger.error(
                "Error loading comment \(commentPostData.postMetadata.postUpdateIdentifier)",
                metadata: [
                    "cause": "\(cause)",
                ]
            )
        }
    }

}
