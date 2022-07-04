package co.firstorderlabs.pulpfiction.backendserver

import co.firstorderlabs.protos.pulpfiction.CreatePostRequestKt.createCommentRequest
import co.firstorderlabs.protos.pulpfiction.CreatePostRequestKt.createImagePostRequest
import co.firstorderlabs.protos.pulpfiction.LoginResponseKt.loginSession
import co.firstorderlabs.protos.pulpfiction.PulpFictionProtos
import co.firstorderlabs.protos.pulpfiction.PulpFictionProtos.CreatePostRequest
import co.firstorderlabs.protos.pulpfiction.PulpFictionProtos.CreatePostRequest.CreateCommentRequest
import co.firstorderlabs.protos.pulpfiction.PulpFictionProtos.CreatePostRequest.CreateImagePostRequest
import co.firstorderlabs.protos.pulpfiction.PulpFictionProtos.CreateUserRequest
import co.firstorderlabs.protos.pulpfiction.PulpFictionProtos.LoginResponse.LoginSession
import co.firstorderlabs.protos.pulpfiction.createPostRequest
import co.firstorderlabs.protos.pulpfiction.createUserRequest
import co.firstorderlabs.protos.pulpfiction.loginRequest
import co.firstorderlabs.pulpfiction.backendserver.testutils.nextByteString
import co.firstorderlabs.pulpfiction.backendserver.utils.toTimestamp
import co.firstorderlabs.pulpfiction.backendserver.utils.toYearMonthDay
import io.github.serpro69.kfaker.Faker
import java.time.Instant
import java.util.Random
import java.util.UUID

object TestProtoModelGenerator {
    private val faker = Faker()
    private val random = Random()

    fun generateRandomLoginSession(): LoginSession = loginSession {
        this.sessionToken = UUID.randomUUID().toString()
        this.userId = UUID.randomUUID().toString()
        this.createdAt = Instant.now().toTimestamp()
    }

    fun generateRandomCreateUserRequest(): CreateUserRequest = createUserRequest {
        this.displayName = faker.name.firstName()
        this.email = faker.internet.email()
        this.phoneNumber = faker.phoneNumber.phoneNumber()
        this.dateOfBirth = faker.person.birthDate(30).toYearMonthDay()
        this.password = faker.unique.toString()
        this.optInToEmails = random.nextBoolean()
        this.avatarAsPng = random.nextByteString(100)
    }

    fun generateRandomLoginRequest(userId: String, password: String): PulpFictionProtos.LoginRequest = loginRequest {
        this.userId = userId
        this.deviceId = faker.unique.toString()
        this.password = password
    }

    fun generateRandomCreateCommentRequest(parentPostId: String): CreateCommentRequest = createCommentRequest {
        this.body = faker.lovecraft.unique.toString()
        this.parentPostId = parentPostId
    }

    fun generateRandomCreateImagePostRequest(): CreateImagePostRequest = createImagePostRequest {
        this.caption = faker.lovecraft.unique.toString()
        this.imageAsPng = random.nextByteString(100)
    }

    fun LoginSession.generateRandomCreatePostRequest(): CreatePostRequest = createPostRequest {
        this.loginSession = this@generateRandomCreatePostRequest
        this.createImagePostRequest = generateRandomCreateImagePostRequest()
    }

    fun CreatePostRequest.withRandomCreateImagePostRequest(): CreatePostRequest {
        val builder = this.toBuilder()
        builder.createImagePostRequest = generateRandomCreateImagePostRequest()
        return builder.build()
    }

    fun CreatePostRequest.withRandomCreateCommentRequest(parentPostId: String): CreatePostRequest {
        val builder = this.toBuilder()
        builder.createCommentRequest = generateRandomCreateCommentRequest(parentPostId)
        return builder.build()
    }
}