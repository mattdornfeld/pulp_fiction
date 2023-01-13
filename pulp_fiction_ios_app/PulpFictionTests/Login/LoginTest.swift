//
//  LoginTest.swift
//  _SwiftUINavigationState
//
//  Created by Matthew Dornfeld on 12/26/22.
//

import Bow
import ComposableArchitecture
import Foundation
import XCTest

@testable import PulpFictionAppPreview
@testable import PulpFictionAppSource

@MainActor
class LoginTest: XCTestCase {
    func buildLoginReducer() throws -> LoginReducer {
        let externalMessengersEither = Either<PulpFictionRequestError, ExternalMessengers>.var()

        return try binding(
            externalMessengersEither <- ExternalMessengers
                .createForTests()
                .logError("Error creating ExternalMessengers")
                .mapLeft { PulpFictionRequestError($0) },
            yield: .init(
                externalMessengers: externalMessengersEither.get,
                emailOrPhoneTextFieldViewStore: PulpFictionTextField.buildViewStore(),
                passwordTextFieldViewStore: PulpFictionTextField.buildViewStore(),
                notificationBannerViewStore: NotificationBanner.buildViewStore(),
                bottomNavigationBarNavigationLinkViewStore: EmptyNavigationLinkView<Login>.buildViewStore()
            )
        )^.getOrThrow()
    }

    func buildTestStore(reducer: LoginReducer) -> PulpFictionTestStore<LoginReducer> {
        TestStore(
            initialState: LoginReducer.State(),
            reducer: reducer
        )
    }

    func testCreateLoginSession() async throws {
        try await [
            (FakeData.expectedEmail, { (createLoginSessionRequest: CreateLoginSessionRequest) in
                XCTAssertEqual(FakeData.expectedEmail, createLoginSessionRequest.emailLogin.email)
            }),
            (FakeData.expectedPhoneNumber, { (createLoginSessionRequest: CreateLoginSessionRequest) in
                XCTAssertEqual(FakeData.expectedPhoneNumber, createLoginSessionRequest.phoneNumberLogin.phoneNumber)
            }),
        ].asyncForEach { expectedEmailOrPhone, assertEmailOrPhoneValue in
            let reducer = try buildLoginReducer()
            let store = buildTestStore(reducer: reducer)

            await reducer.emailOrPhoneTextFieldViewStore.send(.updateText(expectedEmailOrPhone)).finish()
            await reducer.passwordTextFieldViewStore.send(.updateText(FakeData.expectedPassword)).finish()
            await store.send(.createLoginSession)
            await store.receive(.processCreateLoginSessionResponse(.right(PulpFictionTestClientWithFakeData.createLoginSessionResponse)))
            reducer.backendMessenger.getPulpFictionTestClientWithFakeData()

            let pulpFictionTestClientWithFakeData = reducer.backendMessenger.getPulpFictionTestClientWithFakeData()
            let createLoginSessionRequest = pulpFictionTestClientWithFakeData.requestBuffers.createLoginSession[0]
            assertEmailOrPhoneValue(createLoginSessionRequest)
            XCTAssertEqual(FakeData.expectedPassword, createLoginSessionRequest.password)
            XCTAssertEqual(reducer.backendMessenger.createLoginSessionBackendMessenger.getDeviceId(), createLoginSessionRequest.deviceID)

            reducer.notificationBannerViewStore.assertStateChange {
                .init(
                    shouldShowNotification: true,
                    notificationTextMaybe: "Successfully logged in!",
                    bannerTypeMaybe: .success
                )
            }
        }
    }
}
