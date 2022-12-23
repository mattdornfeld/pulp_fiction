//
//  EditProfileTest.swift
//  test_unit
//
//  Created by Matthew Dornfeld on 12/21/22.
//

import Bow
import ComposableArchitecture
import Foundation
import XCTest

@testable import PulpFictionAppPreview
@testable import PulpFictionAppSource

@MainActor
class EditProfileTest: XCTestCase {
    private let expectedUpdateUserResponseEither: Either<PulpFictionRequestError, UpdateUserResponse> = .right(UpdateUserResponse())
    private let userPostDataUpdateAction: EquatableWrapper<(UpdateUserResponse, EditProfileReducer.State) -> PulpFictionRequestEither<UserPostData>> = .init { _, _ in
        PulpFictionRequestEither<UserPostData>.left(PulpFictionRequestError())
    }

    func buildEditProfileReducer() throws -> EditProfileReducer {
        let externalMessengersEither = Either<PulpFictionRequestError, ExternalMessengers>.var()

        return try binding(
            externalMessengersEither <- ExternalMessengers
                .createForTests()
                .logError("Error creating ExternalMessengers")
                .mapLeft { PulpFictionRequestError($0) },
            yield: EditProfileReducer(
                backendMessenger: externalMessengersEither.get.backendMessenger,
                notificationBannerViewStore: NotificationBanner.buildViewStore()
            )
        )^.getOrThrow()
    }

    func buildTestStore(reducer: EditProfileReducer) throws -> PulpFictionTestStore<EditProfileReducer> {
        let userPostDataEither = Either<PulpFictionRequestError, UserPostData>.var()
        return try binding(
            userPostDataEither <- UserPostData
                .generate()
                .unsafeRunSyncEither(),
            yield: TestStore(
                initialState: EditProfileReducer.State(loggedInUserPostData: userPostDataEither.get),
                reducer: reducer
            )
        )^.getOrThrow()
    }

    func testUpdateUserAvatarUIImage() async throws {
        let reducer = try buildEditProfileReducer()
        let store = try buildTestStore(reducer: reducer)
        let originalUIImage = store.state.loggedInUserPostData.userAvatarUIImage
        let expectedUIImage = store.state.loggedInUserPostData.userAvatarUIImage.withTintColor(.blue)
        await store.send(.updateUserAvatarUIImage(expectedUIImage))
        await store.receive(
            .processUpdateUserResponse(
                expectedUpdateUserResponseEither,
                UpdateUserBackendMessenger.BackendPath.updateUserAvatarUIImage.rawValue,
                EditProfileReducer.BannerMessage.updateUserAvatarUIImage,
                userPostDataUpdateAction
            ),
            timeout: Duration.seconds(0.2)
        )
        await store.receive(.updateLoggedInUserPostData(store.state.loggedInUserPostData)) {
            $0.toggleToRefresh = true
        }
        XCTAssertNotEqual(expectedUIImage, originalUIImage)
        XCTAssertEqual(expectedUIImage, store.state.loggedInUserPostData.userAvatarUIImage)

        let pulpFictionTestClientWithFakeData = reducer.backendMessenger.getPulpFictionTestClientWithFakeData()
        let updateUserRequest = pulpFictionTestClientWithFakeData.requestBuffers.updateUser[0]
        XCTAssertEqual(try expectedUIImage.serializeImage().getOrThrow(), updateUserRequest.updateUserAvatar.avatarJpg)
    }

    func testUpdateDisplayName() async throws {
        let reducer = try buildEditProfileReducer()
        let store = try buildTestStore(reducer: reducer)
        let expectedDisplayName = "expectedDisplayName"
        await store.send(.updateDisplayName(expectedDisplayName))
        await store.receive(
            .processUpdateUserResponse(
                expectedUpdateUserResponseEither,
                UpdateUserBackendMessenger.BackendPath.updateDisplayName.rawValue,
                EditProfileReducer.BannerMessage.updateDisplayName,
                userPostDataUpdateAction
            ),
            timeout: Duration.seconds(0.2)
        )
        await store.receive(.updateLoggedInUserPostData(store.state.loggedInUserPostData)) {
            $0.toggleToRefresh = true
        }
        XCTAssertEqual(expectedDisplayName, store.state.loggedInUserPostData.userDisplayName)

        let pulpFictionTestClientWithFakeData = reducer.backendMessenger.getPulpFictionTestClientWithFakeData()
        let updateUserRequest = pulpFictionTestClientWithFakeData.requestBuffers.updateUser[0]
        XCTAssertEqual(expectedDisplayName, updateUserRequest.updateDisplayName.newDisplayName)
    }
}
