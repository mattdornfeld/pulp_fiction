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
    private let userPostDataUpdateAction: EquatableWrapper<(UpdateUserResponse, EditProfileReducer.State) -> PulpFictionRequestEither<UserData>> = .init { _, _ in
        .left(PulpFictionRequestError())
    }

    func buildEditProfileReducer() throws -> EditProfileReducer {
        let externalMessengersEither = Either<PulpFictionRequestError, ExternalMessengers>.var()

        return try binding(
            externalMessengersEither <- ExternalMessengers
                .createForTests()
                .logError("Error creating ExternalMessengers")
                .mapLeft { PulpFictionRequestError($0) },
            yield: EditProfileReducer(
                externalMessengers: externalMessengersEither.get,
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

    func testUpdateBio() async throws {
        let reducer = try buildEditProfileReducer()
        let store = try buildTestStore(reducer: reducer)
        let expectedBio = "expectedDisplayName"
        await store.send(.updateBio(expectedBio))
        await store.receive(
            .processUpdateUserResponse(
                expectedUpdateUserResponseEither,
                UpdateUserBackendMessenger.BackendPath.updateBio.rawValue,
                EditProfileReducer.BannerMessage.updateBio,
                userPostDataUpdateAction
            ),
            timeout: Duration.seconds(0.2)
        )
        await store.receive(.updateLoggedInUserPostData(store.state.loggedInUserPostData)) {
            $0.toggleToRefresh = true
        }
        XCTAssertEqual(expectedBio, store.state.loggedInUserPostData.bio)

        let pulpFictionTestClientWithFakeData = reducer.backendMessenger.getPulpFictionTestClientWithFakeData()
        let updateUserRequest = pulpFictionTestClientWithFakeData.requestBuffers.updateUser[0]
        XCTAssertEqual(expectedBio, updateUserRequest.updateBio.newBio)
    }

    func testUpdateEmail() async throws {
        let reducer = try buildEditProfileReducer()
        let store = try buildTestStore(reducer: reducer)
        let expectedLoggedInUserSensitiveMetadata = SensitiveUserMetadata
            .setter(for: \.email)
            .set(store.state.loggedInUserSensitiveMetadata, "expectedEmail@gmail.com")
        await store.send(.updateEmail(expectedLoggedInUserSensitiveMetadata.email))
        await store.receive(
            .processUpdateUserResponse(
                expectedUpdateUserResponseEither,
                UpdateUserBackendMessenger.BackendPath.updateEmail.rawValue,
                EditProfileReducer.BannerMessage.updateEmail,
                userPostDataUpdateAction
            ),
            timeout: Duration.seconds(0.2)
        )

        await store.receive(.updateLoggedInUserSensitiveMetadata(expectedLoggedInUserSensitiveMetadata)) {
            $0.loggedInUserSensitiveMetadata = expectedLoggedInUserSensitiveMetadata
        }
        XCTAssertEqual(expectedLoggedInUserSensitiveMetadata.email, store.state.loggedInUserSensitiveMetadata.email)

        let pulpFictionTestClientWithFakeData = reducer.backendMessenger.getPulpFictionTestClientWithFakeData()
        let updateUserRequest = pulpFictionTestClientWithFakeData.requestBuffers.updateUser[0]
        XCTAssertEqual(expectedLoggedInUserSensitiveMetadata.email, updateUserRequest.updateEmail.newEmail)
    }

    func testUpdatePhoneNumber() async throws {
        let reducer = try buildEditProfileReducer()
        let store = try buildTestStore(reducer: reducer)
        let expectedLoggedInUserSensitiveMetadata = SensitiveUserMetadata
            .setter(for: \.phoneNumber)
            .set(store.state.loggedInUserSensitiveMetadata, "876-5309")
        await store.send(.updatePhoneNumber(expectedLoggedInUserSensitiveMetadata.phoneNumber))
        await store.receive(
            .processUpdateUserResponse(
                expectedUpdateUserResponseEither,
                UpdateUserBackendMessenger.BackendPath.updatePhoneNumber.rawValue,
                EditProfileReducer.BannerMessage.updatePhoneNumber,
                userPostDataUpdateAction
            ),
            timeout: Duration.seconds(0.2)
        )

        await store.receive(.updateLoggedInUserSensitiveMetadata(expectedLoggedInUserSensitiveMetadata)) {
            $0.loggedInUserSensitiveMetadata = expectedLoggedInUserSensitiveMetadata
        }
        XCTAssertEqual(expectedLoggedInUserSensitiveMetadata.phoneNumber, store.state.loggedInUserSensitiveMetadata.phoneNumber)

        let pulpFictionTestClientWithFakeData = reducer.backendMessenger.getPulpFictionTestClientWithFakeData()
        let updateUserRequest = pulpFictionTestClientWithFakeData.requestBuffers.updateUser[0]
        XCTAssertEqual(expectedLoggedInUserSensitiveMetadata.phoneNumber, updateUserRequest.updatePhoneNumber.newPhoneNumber)
    }

    func testUpdateDateOfBirth() async throws {
        let reducer = try buildEditProfileReducer()
        let store = try buildTestStore(reducer: reducer)
        let expectedLoggedInUserSensitiveMetadata = SensitiveUserMetadata
            .setter(for: \.dateOfBirth)
            .set(store.state.loggedInUserSensitiveMetadata, .distantPast)
        await store.send(.updateDateOfBirth(expectedLoggedInUserSensitiveMetadata.dateOfBirth))
        await store.receive(
            .processUpdateUserResponse(
                expectedUpdateUserResponseEither,
                UpdateUserBackendMessenger.BackendPath.updateDateOfBirth.rawValue,
                EditProfileReducer.BannerMessage.updateDateOfBirth,
                userPostDataUpdateAction
            ),
            timeout: Duration.seconds(0.2)
        )

        await store.receive(.updateLoggedInUserSensitiveMetadata(expectedLoggedInUserSensitiveMetadata)) {
            $0.loggedInUserSensitiveMetadata = expectedLoggedInUserSensitiveMetadata
        }
        XCTAssertEqual(expectedLoggedInUserSensitiveMetadata.dateOfBirth, store.state.loggedInUserSensitiveMetadata.dateOfBirth)

        let pulpFictionTestClientWithFakeData = reducer.backendMessenger.getPulpFictionTestClientWithFakeData()
        let updateUserRequest = pulpFictionTestClientWithFakeData.requestBuffers.updateUser[0]
        XCTAssertEqual(expectedLoggedInUserSensitiveMetadata.dateOfBirth, updateUserRequest.updateDateOfBirth.newDateOfBirth.date)
    }
}
