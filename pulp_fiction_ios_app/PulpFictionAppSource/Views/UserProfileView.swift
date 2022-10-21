//
//  UserPostView.swift
//  PulpFictionApp
//
//  Created by Matthew Dornfeld on 10/19/22.
//

import Bow
import ComposableArchitecture
import Foundation
import SwiftUI

// struct UserProfileViewReducer: ReducerProtocol {
//    struct State: Equatable {
//
//    }
//
//    enum Action {
//
//    }
//
//    func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
//        <#code#>
//    }
// }

struct UserProfileView: PostView {
    let id: Int
    let userPostData: UserPostData
    let userAvatarUIImage: UIImage
    let postFeedMessenger: PostFeedMessenger

    static func == (lhs: UserProfileView, rhs: UserProfileView) -> Bool {
        lhs.id == rhs.id
            && lhs.userPostData == rhs.userPostData
            && lhs.userAvatarUIImage == rhs.userAvatarUIImage
    }

    var body: some View {
        UserProfileScrollView(
            userId: userPostData.userId,
            postFeedMessenger: postFeedMessenger
        ) {
            VStack {
                HStack {
                    CircularImage(
                        uiImage: userAvatarUIImage,
                        radius: 35,
                        borderColor: .gray,
                        borderWidth: 1
                    ).padding(.leading, 5)
                    Spacer()
                    BoldCaption(text: "5\nPosts", alignment: .center)
                        .foregroundColor(.gray)
                        .padding(5)
                    BoldCaption(text: "15\nComments", alignment: .center)
                        .foregroundColor(.gray)
                        .padding(5)
                    BoldCaption(text: "1000\nReputation", alignment: .center)
                        .foregroundColor(.gray)
                        .padding(5)
                }
                Caption(text: userPostData.bio, alignment: .center)
                    .foregroundColor(.gray)
                    .padding()
            }
        }
    }

    public static func create(
        postViewIndex: Int,
        userPostData: UserPostData,
        postFeedMessenger: PostFeedMessenger
    ) -> Either<PulpFictionRequestError, UserProfileView> {
        let createUserAvatarUIImageEither = Either<PulpFictionRequestError, UIImage>.var()

        return binding(
            createUserAvatarUIImageEither <- userPostData.userPostContentData.toUIImage(),
            yield: UserProfileView(
                id: postViewIndex,
                userPostData: userPostData,
                userAvatarUIImage: createUserAvatarUIImageEither.get,
                postFeedMessenger: postFeedMessenger
            )
        )^
    }
}
