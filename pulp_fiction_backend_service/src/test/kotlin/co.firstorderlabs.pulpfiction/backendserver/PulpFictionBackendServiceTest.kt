package co.firstorderlabs.pulpfiction.backendserver

import arrow.core.Either
import co.firstorderlabs.protos.pulpfiction.PulpFictionProtos
import co.firstorderlabs.protos.pulpfiction.PulpFictionProtos.CreateLoginSessionRequest
import co.firstorderlabs.protos.pulpfiction.PulpFictionProtos.CreateUserRequest
import co.firstorderlabs.protos.pulpfiction.PulpFictionProtos.CreateUserResponse
import co.firstorderlabs.protos.pulpfiction.PulpFictionProtos.Post.PostType
import co.firstorderlabs.protos.pulpfiction.createPostRequest
import co.firstorderlabs.protos.pulpfiction.getUserRequest
import co.firstorderlabs.pulpfiction.backendserver.TestProtoModelGenerator.buildGetPostRequest
import co.firstorderlabs.pulpfiction.backendserver.TestProtoModelGenerator.generateRandomCreatePostRequest
import co.firstorderlabs.pulpfiction.backendserver.TestProtoModelGenerator.generateRandomGetCommentFeedRequest
import co.firstorderlabs.pulpfiction.backendserver.TestProtoModelGenerator.generateRandomGetFollowingPostFeedRequest
import co.firstorderlabs.pulpfiction.backendserver.TestProtoModelGenerator.generateRandomGetGlobalPostFeedRequest
import co.firstorderlabs.pulpfiction.backendserver.TestProtoModelGenerator.generateRandomGetPostRequest
import co.firstorderlabs.pulpfiction.backendserver.TestProtoModelGenerator.generateRandomGetUserPostFeedRequest
import co.firstorderlabs.pulpfiction.backendserver.TestProtoModelGenerator.generateRandomUpdateDateOfBirthRequest
import co.firstorderlabs.pulpfiction.backendserver.TestProtoModelGenerator.generateRandomUpdateDisplayNameRequest
import co.firstorderlabs.pulpfiction.backendserver.TestProtoModelGenerator.generateRandomUpdateEmailRequest
import co.firstorderlabs.pulpfiction.backendserver.TestProtoModelGenerator.generateRandomUpdatePasswordRequest
import co.firstorderlabs.pulpfiction.backendserver.TestProtoModelGenerator.generateRandomUpdatePhoneNumberRequest
import co.firstorderlabs.pulpfiction.backendserver.TestProtoModelGenerator.withRandomCreateCommentRequest
import co.firstorderlabs.pulpfiction.backendserver.TestProtoModelGenerator.withRandomCreateImagePostRequest
import co.firstorderlabs.pulpfiction.backendserver.monitoring.metrics.collectors.PulpFictionCounter
import co.firstorderlabs.pulpfiction.backendserver.monitoring.metrics.collectors.PulpFictionMetric
import co.firstorderlabs.pulpfiction.backendserver.monitoring.metrics.collectors.PulpFictionSummary
import co.firstorderlabs.pulpfiction.backendserver.monitoring.metrics.metricsstore.CreatePostDataMetrics.createPostDataDurationSeconds
import co.firstorderlabs.pulpfiction.backendserver.monitoring.metrics.metricsstore.CreatePostDataMetrics.createPostDataTotal
import co.firstorderlabs.pulpfiction.backendserver.monitoring.metrics.metricsstore.CreatePostDataMetrics.toLabelValue
import co.firstorderlabs.pulpfiction.backendserver.monitoring.metrics.metricsstore.DatabaseMetrics
import co.firstorderlabs.pulpfiction.backendserver.monitoring.metrics.metricsstore.DatabaseMetrics.databaseQueryDurationSeconds
import co.firstorderlabs.pulpfiction.backendserver.monitoring.metrics.metricsstore.DatabaseMetrics.databaseRequestTotal
import co.firstorderlabs.pulpfiction.backendserver.monitoring.metrics.metricsstore.EndpointMetrics.EndpointName
import co.firstorderlabs.pulpfiction.backendserver.monitoring.metrics.metricsstore.EndpointMetrics.endpointRequestDurationSeconds
import co.firstorderlabs.pulpfiction.backendserver.monitoring.metrics.metricsstore.EndpointMetrics.endpointRequestTotal
import co.firstorderlabs.pulpfiction.backendserver.monitoring.metrics.metricsstore.S3Metrics
import co.firstorderlabs.pulpfiction.backendserver.monitoring.metrics.metricsstore.S3Metrics.s3RequestDurationSeconds
import co.firstorderlabs.pulpfiction.backendserver.monitoring.metrics.metricsstore.S3Metrics.s3RequestTotal
import co.firstorderlabs.pulpfiction.backendserver.testutils.S3AndPostgresContainers
import co.firstorderlabs.pulpfiction.backendserver.testutils.assertEquals
import co.firstorderlabs.pulpfiction.backendserver.testutils.assertTrue
import co.firstorderlabs.pulpfiction.backendserver.testutils.isWithinLast
import co.firstorderlabs.pulpfiction.backendserver.types.LoginSessionInvalidError
import co.firstorderlabs.pulpfiction.backendserver.utils.getResultAndThrowException
import co.firstorderlabs.pulpfiction.backendserver.utils.toUUID
import io.grpc.Status
import io.grpc.StatusException
import kotlinx.coroutines.flow.flow
import kotlinx.coroutines.flow.take
import kotlinx.coroutines.flow.toList
import kotlinx.coroutines.runBlocking
import org.junit.jupiter.api.AfterEach
import org.junit.jupiter.api.BeforeAll
import org.junit.jupiter.api.Test
import org.ktorm.dsl.deleteAll
import org.ktorm.entity.Tuple2
import org.ktorm.entity.Tuple3
import org.ktorm.entity.tupleOf
import org.testcontainers.containers.PostgreSQLContainer
import org.testcontainers.containers.localstack.LocalStackContainer
import org.testcontainers.junit.jupiter.Container
import org.testcontainers.junit.jupiter.Testcontainers
import java.util.UUID

private typealias RequestAndResponseSuppliers = List<Tuple3<EndpointName, com.google.protobuf.GeneratedMessageV3, suspend (com.google.protobuf.GeneratedMessageV3) -> com.google.protobuf.GeneratedMessageV3>>

@Testcontainers
internal class PulpFictionBackendServiceTest {
    companion object : S3AndPostgresContainers() {
        @Container
        override val localStackContainer: LocalStackContainer = createLockStackContainer()

        @Container
        override val postgreSQLContainer: PostgreSQLContainer<Nothing> = createPostgreSQLContainer()

        @BeforeAll
        @JvmStatic
        override fun migrateDatabase() = super.migrateDatabase()

        private val pulpFictionBackendService by lazy(LazyThreadSafetyMode.PUBLICATION) {
            PulpFictionBackendService(
                database,
                s3Client
            )
        }
        private val s3Messenger by lazy { S3Messenger(s3Client) }
    }

    @AfterEach
    fun clearTables() {
        tables.forEach { database.deleteAll(it) }
    }

    @AfterEach
    fun clearMetricsRegistry() {
        PulpFictionMetric.clearRegistry()
    }

    private suspend fun createUser(): Tuple2<CreateUserResponse, CreateUserRequest> {
        val createUserRequest = TestProtoModelGenerator.generateRandomCreateUserRequest()
        return Tuple2(pulpFictionBackendService.createUser(createUserRequest), createUserRequest)
    }

    private suspend fun createUserAndLogin(): Tuple2<PulpFictionProtos.CreateLoginSessionResponse.LoginSession, CreateLoginSessionRequest> {
        val (_, createUserRequest) = createUser()
        val loginRequest =
            TestProtoModelGenerator.generateRandomLoginRequest(
                createUserRequest.phoneNumberVerification.phoneNumber,
                createUserRequest.password
            )
        val loginSession = pulpFictionBackendService.createLoginSession(loginRequest).loginSession
        pulpFictionBackendService.createPost(
            createPostRequest {
                this.loginSession = loginSession
                this.createUserPostRequest = TestProtoModelGenerator.generateRandomCreateUserPostRequest(loginSession)
            }
        )

        return Tuple2(loginSession, loginRequest)
    }

    private suspend fun createFailingLoginRequests(): List<CreateLoginSessionRequest> {
        val (_, createUserRequest) = createUser()

        val incorrectPhoneNumber = TestProtoModelGenerator.faker.phoneNumber.phoneNumber()
        val incorrectPassword = "fail_${createUserRequest.password}"

        val loginRequestWrongPhoneNumber =
            TestProtoModelGenerator.generateRandomLoginRequest(
                incorrectPhoneNumber,
                createUserRequest.password
            )
        val loginRequestWrongPass =
            TestProtoModelGenerator.generateRandomLoginRequest(
                createUserRequest.phoneNumberVerification.phoneNumber,
                incorrectPassword
            )

        return listOf(loginRequestWrongPhoneNumber, loginRequestWrongPass)
    }

    private fun assertMetricsCorrect(
        countMetric: PulpFictionCounter,
        durationMetric: PulpFictionSummary,
        expectedCount: Double,
        maxDurationSeconds: Double = 2.0
    ) {
        countMetric
            .assertEquals(expectedCount) { it.get() }

        durationMetric
            .assertEquals(expectedCount) { it.get().count }

        durationMetric
            .assertEquals(
                "${durationMetric.name} count for ${countMetric.labelNames.toList()} = ${countMetric.labelValuesMaybe.map { it.toList() }} should equal $expectedCount",
                expectedCount
            ) { it.get().count }

        durationMetric
            .assertTrue(
                "The quantiles for ${durationMetric.name} for ${durationMetric.labelNames.toList()} = ${durationMetric.labelValuesMaybe.map { it.toList() }} should be between 0 and $maxDurationSeconds but was ${durationMetric.get().quantiles}"
            ) { summary ->
                summary.get().quantiles.values.map { it > 0 && it < maxDurationSeconds }.stream()
                    .allMatch { it == true }
            }
    }

    private fun EndpointName.assertEndpointMetricsCorrect(expectedCount: Double, maxDurationSeconds: Double = 2.0) {
        assertMetricsCorrect(
            endpointRequestTotal.withLabels(this),
            endpointRequestDurationSeconds.withLabels(this),
            expectedCount,
            maxDurationSeconds
        )
    }

    private fun List<Tuple2<EndpointName, Double>>.assertEndpointMetricsCorrect() =
        this.forEach { it.first.assertEndpointMetricsCorrect(it.second) }

    private fun Tuple2<EndpointName, DatabaseMetrics.DatabaseOperation>.assertDatabaseMetricsCorrect(
        expectedCount: Double,
        maxDurationSeconds: Double = 2.0
    ) {
        assertMetricsCorrect(
            databaseRequestTotal.withLabels(this.first, this.second),
            databaseQueryDurationSeconds.withLabels(this.first, this.second),
            expectedCount,
            maxDurationSeconds
        )
    }

    private fun List<Tuple3<EndpointName, DatabaseMetrics.DatabaseOperation, Double>>.assertDatabaseMetricsCorrect() =
        this.forEach {
            tupleOf(it.first, it.second).assertDatabaseMetricsCorrect(it.third)
        }

    private fun Tuple2<EndpointName, S3Metrics.S3Operation>.assertS3MetricsCorrect(
        expectedCount: Double,
        maxDurationSeconds: Double = 0.5
    ) {
        assertMetricsCorrect(
            s3RequestTotal.withLabels(this.first, this.second),
            s3RequestDurationSeconds.withLabels(this.first, this.second),
            expectedCount,
            maxDurationSeconds
        )
    }

    private fun PostType.assertCreatePostDataMetricsCorrect(
        expectedCount: Double,
        maxDurationSeconds: Double = 0.5
    ) {
        assertMetricsCorrect(
            createPostDataTotal.withLabels(this.toLabelValue()),
            createPostDataDurationSeconds.withLabels(this.toLabelValue()),
            expectedCount,
            maxDurationSeconds
        )
    }

    @Test
    fun testCreateUser() {
        runBlocking {
            val (createUserResponse, _) = createUser()

            createUserResponse
                .assertTrue { it.userId.toUUID().isRight() }
                .assertTrue { it.createdAt.isWithinLast(100) }

            EndpointName.createUser
                .assertEndpointMetricsCorrect(1.0)
        }
    }

    @Test
    fun testGetUser() {
        runBlocking {
            val (loginSession, createUserRequest) = createUserAndLogin()

//            val loginRequest =
//                TestProtoModelGenerator.generateRandomLoginRequest(
//                    createUserRequest.phoneNumberVerification.phoneNumber,
//                    createUserRequest.password
//                )
//            val loginSession = pulpFictionBackendService.createLoginSession(loginRequest).loginSession

            val updateDisplayNameRequest = TestProtoModelGenerator.generateRandomUpdateDisplayNameRequest(loginSession)

            val lastUpdateUserResponse = listOf(
                updateDisplayNameRequest,
            ).map { updateUserRequest ->
                pulpFictionBackendService.updateUser(updateUserRequest)
            }.last()

            val user = pulpFictionBackendService.getUser(
                getUserRequest {
                    this.loginSession = loginSession
                    this.userId = loginSession.userId
                }
            )

            // TODO (Matt): Add tests for other user properties
            user.userMetadata
                .assertEquals(loginSession.userId) { it.userId }
                .assertEquals(updateDisplayNameRequest.updateUserMetadata.updateDisplayName.newDisplayName) { it.displayName }
                .assertEquals(lastUpdateUserResponse.updateUserMetadata.userMetadata.latestUserPostUpdateIdentifier) { it.latestUserPostUpdateIdentifier }

            tupleOf(EndpointName.getUser, DatabaseMetrics.DatabaseOperation.getUser)
                .assertDatabaseMetricsCorrect(1.0)
        }
    }

    @Test
    fun testFailedGetUser() {
        runBlocking {
            val tuple2 = createUserAndLogin()
            val loginSession = tuple2.first

            Either.catch {
                pulpFictionBackendService.getUser(
                    getUserRequest {
                        this.loginSession = loginSession
                        this.userId = UUID.randomUUID().toString()
                    }
                )
            }
                .assertTrue { it.isLeft() }
                .mapLeft { error ->
                    error
                        .assertEquals(Status.NOT_FOUND.code) { (it as StatusException).status.code }
                }

            tupleOf(EndpointName.getUser, DatabaseMetrics.DatabaseOperation.getUser)
                .assertDatabaseMetricsCorrect(1.0)
        }
    }

    @Test
    fun testLogin() {
        runBlocking {
            val tuple2 = createUserAndLogin()
            val loginSession = tuple2.first
            val loginRequest = tuple2.second

            loginSession
                .assertTrue { it.sessionToken.toUUID().isRight() }
                .assertTrue { it.createdAt.isWithinLast(100) }
                .assertEquals(loginRequest.deviceId) { it.deviceId }

            EndpointName
                .login
                .assertEndpointMetricsCorrect(1.0)

            listOf(
                tupleOf(EndpointName.createUser, DatabaseMetrics.DatabaseOperation.createUser, 1.0),
                tupleOf(EndpointName.login, DatabaseMetrics.DatabaseOperation.login, 1.0),
            ).assertDatabaseMetricsCorrect()
        }
    }

    @Test
    fun testFailedLogin() {
        runBlocking {
            val loginRequests = createFailingLoginRequests()
            val expectedExceptions = listOf(Status.NOT_FOUND.code, Status.UNAUTHENTICATED.code)
            loginRequests.zip(expectedExceptions) { loginRequest, expectedException ->
                Either.catch { pulpFictionBackendService.createLoginSession(loginRequest) }
                    .assertTrue { it.isLeft() }
                    .mapLeft { error ->
                        error
                            .assertEquals(
                                expectedException
                            ) { (it as StatusException).status.code }
                    }
            }

            tupleOf(EndpointName.login, DatabaseMetrics.DatabaseOperation.checkUserPasswordValid)
                .assertDatabaseMetricsCorrect(2.0)
        }
    }

    @Test
    fun testLoginRequired() {
        runBlocking {
            val loginSession = TestProtoModelGenerator.generateRandomLoginSession()

            val requestAndResponseSuppliers: RequestAndResponseSuppliers =
                listOf(
                    tupleOf(
                        EndpointName.createPost,
                        loginSession.generateRandomCreatePostRequest()
                    ) { pulpFictionBackendService.createPost(it as PulpFictionProtos.CreatePostRequest) },
                    tupleOf(
                        EndpointName.getPost,
                        loginSession.generateRandomGetPostRequest()
                    ) { pulpFictionBackendService.getPost(it as PulpFictionProtos.GetPostRequest) }
                )

            requestAndResponseSuppliers.forEach { requestAndResponseSupplier ->
                val endpointName = requestAndResponseSupplier.first
                val request = requestAndResponseSupplier.second
                val responseSupplier = requestAndResponseSupplier.third

                Either.catch { responseSupplier(request) }
                    .assertTrue { it.isLeft() }
                    .mapLeft { error ->
                        error
                            .assertTrue { it is StatusException }
                            .assertTrue { it.cause is LoginSessionInvalidError }
                            .assertEquals(Status.UNAUTHENTICATED.code) { (it as StatusException).status.code }
                    }

                tupleOf(endpointName, DatabaseMetrics.DatabaseOperation.checkLoginSessionValid)
                    .assertDatabaseMetricsCorrect(1.0)
            }
        }
    }

    @Test
    fun testCreateImagePost(): Unit = runBlocking {
        val loginSession = createUserAndLogin().first

        val createPostRequest = loginSession
            .generateRandomCreatePostRequest()
            .withRandomCreateImagePostRequest()
        val postMetadata = pulpFictionBackendService
            .createPost(createPostRequest)
            .postMetadata

        postMetadata
            .assertEquals(loginSession.userMetadata.userId) { it.postCreatorId }
            .assertEquals(PulpFictionProtos.Post.PostState.CREATED) { it.postState }
            .assertTrue { it.createdAt.isWithinLast(100) }

        val getPostRequest = loginSession.buildGetPostRequest(postMetadata)
        val post = pulpFictionBackendService.getPost(getPostRequest).post

        post
            .assertEquals(postMetadata) { it.metadata }
            .assertEquals(createPostRequest.createImagePostRequest.caption) { it.imagePost.caption }
            .assertTrue { it.imagePost.hasInteractionAggregates() }
            .assertTrue { it.imagePost.hasLoggedInUserPostInteractions() }

        s3Messenger
            .getObject(post.imagePost.imageUrl)
            .getResultAndThrowException()
            .assertEquals(
                "The imageJpg uploaded to s3 should equal the imageJpg in the create post request",
                createPostRequest.createImagePostRequest.imageJpg
            ) { it }

        listOf(
            tupleOf(EndpointName.createPost, 2.0),
            tupleOf(EndpointName.getPost, 1.0)
        )
            .assertEndpointMetricsCorrect()

        listOf(
            tupleOf(EndpointName.createPost, DatabaseMetrics.DatabaseOperation.createPost, 2.0),
            tupleOf(EndpointName.getPost, DatabaseMetrics.DatabaseOperation.getPost, 1.0),
        ).assertDatabaseMetricsCorrect()

        tupleOf(
            EndpointName.createPost, S3Metrics.S3Operation.uploadImagePost
        ).assertS3MetricsCorrect(1.0)

        PostType.IMAGE
            .assertCreatePostDataMetricsCorrect(1.0)
    }

    @Test
    fun testCreateComment(): Unit = runBlocking {
        val loginSession = createUserAndLogin().first

        val createImagePostRequest = loginSession
            .generateRandomCreatePostRequest()
            .withRandomCreateImagePostRequest()
        val imagePostMetadata = pulpFictionBackendService.createPost(createImagePostRequest).postMetadata

        val createCommentRequest = loginSession
            .generateRandomCreatePostRequest()
            .withRandomCreateCommentRequest(imagePostMetadata.postUpdateIdentifier.postId)
        val postMetadata = pulpFictionBackendService.createPost(createCommentRequest).postMetadata

        postMetadata
            .assertEquals(loginSession.userMetadata.userId) { it.postCreatorId }
            .assertTrue { postMetadata.createdAt.isWithinLast(100) }
            .assertEquals(PulpFictionProtos.Post.PostState.CREATED) { it.postState }

        val getPostRequest = loginSession.buildGetPostRequest(postMetadata)
        val post = pulpFictionBackendService.getPost(getPostRequest).post

        post
            .assertEquals(postMetadata) { it.metadata }
            .assertEquals(createCommentRequest.createCommentRequest.body) { it.comment.body }
            .assertTrue { it.comment.hasInteractionAggregates() }
            .assertTrue { it.comment.hasLoggedInUserPostInteractions() }

        listOf(
            tupleOf(EndpointName.createPost, 3.0),
            tupleOf(EndpointName.getPost, 1.0)
        )
            .assertEndpointMetricsCorrect()

        listOf(
            tupleOf(EndpointName.createPost, DatabaseMetrics.DatabaseOperation.createPost, 3.0),
            tupleOf(EndpointName.getPost, DatabaseMetrics.DatabaseOperation.getPost, 1.0),
        ).assertDatabaseMetricsCorrect()

        PostType.COMMENT
            .assertCreatePostDataMetricsCorrect(1.0)
    }

    @Test
    fun testSuccessfulUpdateUser(): Unit = runBlocking {
        val loginSession = createUserAndLogin().first

        val updateDisplayNameRequest = generateRandomUpdateDisplayNameRequest(loginSession)
        val updateDateOfBirthRequest = generateRandomUpdateDateOfBirthRequest(loginSession)
        val updatePhoneNumberRequest = generateRandomUpdatePhoneNumberRequest(loginSession)
        val updateEmailRequest = generateRandomUpdateEmailRequest(loginSession)
        val requests = listOf(
            updateDisplayNameRequest,
            updateDateOfBirthRequest,
            updatePhoneNumberRequest,
            updateEmailRequest,
        )

        /* By testing the last response in a sequence of requests,
        * we can test both the endpoint response
        * and that the modification of the user row has been correctly resolved
        * in the database for each modification. */
        val finalResponse = requests.map { updateUserRequest ->
            pulpFictionBackendService.updateUser(updateUserRequest)
        }.last()

        finalResponse.assertEquals(
            tupleOf(
                updateDisplayNameRequest.updateUserMetadata.updateDisplayName.newDisplayName,
                updateDateOfBirthRequest.updateSensitiveUserMetadata.updateDateOfBirth.newDateOfBirth,
                updatePhoneNumberRequest.updateSensitiveUserMetadata.updatePhoneNumber.newPhoneNumber,
                updateEmailRequest.updateSensitiveUserMetadata.updateEmail.newEmail,
            )
        ) {
            tupleOf(
                it.updateSensitiveUserMetadata.sensitiveUserMetadata.nonSensitiveUserMetadata.displayName,
                it.updateSensitiveUserMetadata.sensitiveUserMetadata.dateOfBirth,
                it.updateSensitiveUserMetadata.sensitiveUserMetadata.phoneNumber,
                it.updateSensitiveUserMetadata.sensitiveUserMetadata.email,
            )
        }

        EndpointName.updateUser.assertEndpointMetricsCorrect(requests.size.toDouble())

        Tuple2(
            EndpointName.updateUser,
            DatabaseMetrics.DatabaseOperation.updateUser
        )
            .assertDatabaseMetricsCorrect(requests.size.toDouble())
    }

    @Test
    fun testSuccessfulUpdatePassword(): Unit = runBlocking {
        val (loginSession, createLoginSessionRequest) = createUserAndLogin()
        val correctPassword = createLoginSessionRequest.password

        val updatePasswordProto = generateRandomUpdatePasswordRequest(loginSession, correctPassword)
        pulpFictionBackendService.updateUser(updatePasswordProto)

        val updatedLoginRequest = TestProtoModelGenerator.generateRandomLoginRequest(
            createLoginSessionRequest.phoneNumberLogin.phoneNumber,
            updatePasswordProto.updatePassword.newPassword
        )

        val updatedLoginSession = pulpFictionBackendService.createLoginSession(updatedLoginRequest).loginSession
        updatedLoginSession
            .assertTrue { it.sessionToken.toUUID().isRight() }
            .assertTrue { it.createdAt.isWithinLast(100) }

        EndpointName.updateUser.assertEndpointMetricsCorrect(1.0)

        Tuple2(
            EndpointName.updateUser,
            DatabaseMetrics.DatabaseOperation.updateUser
        )
            .assertDatabaseMetricsCorrect(1.0)
    }

    @Test
    fun testFailedUpdatePassword(): Unit = runBlocking {
        val tuple2 = createUserAndLogin()
        val loginSession = tuple2.first
        val loginRequest = tuple2.second

        val incorrectPassword = "fail_${loginRequest.password}"
        val updatePasswordProto = generateRandomUpdatePasswordRequest(loginSession, incorrectPassword)

        Either.catch {
            pulpFictionBackendService.updateUser(updatePasswordProto)
        }.assertTrue { it.isLeft() }.mapLeft { error ->
            error
                .assertEquals(Status.UNAUTHENTICATED.code) { (it as StatusException).status.code }
        }

        EndpointName.updateUser.assertEndpointMetricsCorrect(1.0)

        Tuple2(
            EndpointName.updateUser,
            DatabaseMetrics.DatabaseOperation.updateUser
        )
            .assertDatabaseMetricsCorrect(1.0)
    }

    private suspend fun setupTestFeed(numUsers: Int): Tuple2<PulpFictionProtos.CreateLoginSessionResponse.LoginSession,
        List<PulpFictionProtos.CreatePostResponse>> {
        val userTuples = (1..numUsers).map { createUserAndLogin() }
        val createdPosts = userTuples.map { tuple2 ->
            val loginSession = tuple2.first
            val imagePostRequest = loginSession.generateRandomCreatePostRequest().withRandomCreateImagePostRequest()
            pulpFictionBackendService.createPost(imagePostRequest)
        }

        val loginSession = userTuples.first().first
        return Tuple2(loginSession, createdPosts)
    }

    @Test
    fun testGetGlobalPostFeed(): Unit = runBlocking {
        val (loginSession, createdPosts) = setupTestFeed(2)

        val clientFeedRequests = listOf(
            generateRandomGetGlobalPostFeedRequest(loginSession = loginSession),
            generateRandomGetGlobalPostFeedRequest(loginSession = loginSession)
        )
        val globalFeed = pulpFictionBackendService.getFeed(
            flow {
                clientFeedRequests.map { emit(it) }
            }
        )
        val feedList = globalFeed.take(clientFeedRequests.size).toList()
        feedList
            .map { resp ->
                resp.postsList.map { post ->
                    post.metadata.postUpdateIdentifier.postId
                }
            }
            .assertEquals(
                listOf(
                    createdPosts.map { request ->
                        request.postMetadata.postUpdateIdentifier.postId
                    }.reversed(),
                    emptyList()
                )
            )

        EndpointName.getFeed.assertEndpointMetricsCorrect(1.0)
        Tuple2(
            EndpointName.getFeed,
            DatabaseMetrics.DatabaseOperation.getFeed
        )
            .assertDatabaseMetricsCorrect(2.0)
    }

    @Test
    fun testGetUserPostFeed(): Unit = runBlocking {
        val (loginSession, createdPosts) = setupTestFeed(2)

        val userFeedRequest =
            generateRandomGetUserPostFeedRequest(loginSession = loginSession, userId = loginSession.userId)
        val clientFeedRequests = listOf(userFeedRequest, userFeedRequest)
        val userFeed = pulpFictionBackendService.getFeed(flow { clientFeedRequests.map { emit(it) } })
        val userFeedList = userFeed.take(clientFeedRequests.size).toList()
        userFeedList
            .map { resp ->
                resp.postsList.map { post ->
                    post.metadata.postUpdateIdentifier.postId
                }
            }
            .assertEquals(
                listOf(
                    listOf(createdPosts.first().postMetadata.postUpdateIdentifier.postId).reversed(),
                    emptyList()
                )
            )

        EndpointName.getFeed.assertEndpointMetricsCorrect(1.0)
        Tuple2(
            EndpointName.getFeed,
            DatabaseMetrics.DatabaseOperation.getFeed
        )
            .assertDatabaseMetricsCorrect(2.0)
    }

    @Test
    fun testFollowingPostFeed(): Unit = runBlocking {
        /* TODO(Ceena): Properly test following post feed after following endpoint is implemented */
        val (loginSession, _) = setupTestFeed(2)

        val followingFeedRequest = generateRandomGetFollowingPostFeedRequest(loginSession = loginSession)
        val clientFeedRequests = listOf(followingFeedRequest)
        val followingFeed = pulpFictionBackendService.getFeed(flow { listOf(clientFeedRequests.map { emit(it) }) })
        followingFeed.take(clientFeedRequests.size).toList().forEach { it.postsList.isEmpty() }

        EndpointName.getFeed.assertEndpointMetricsCorrect(1.0)
        Tuple2(
            EndpointName.getFeed,
            DatabaseMetrics.DatabaseOperation.getFeed
        )
            .assertDatabaseMetricsCorrect(1.0)
    }

    @Test
    fun testGetCommentFeed(): Unit = runBlocking {
        /* Set up feed */
        val userTuples = (1..6).map { createUserAndLogin() }
        val loginSession = userTuples.first().first
        val imagePostRequest = loginSession.generateRandomCreatePostRequest().withRandomCreateImagePostRequest()
        val imagePostResponse = pulpFictionBackendService.createPost(imagePostRequest)
        val imagePostMetadata = imagePostResponse.postMetadata

        /* Each user creates a comment */
        val createdComments = userTuples.map {
            val createCommentRequest = loginSession.generateRandomCreatePostRequest()
                .withRandomCreateCommentRequest(imagePostMetadata.postUpdateIdentifier.postId)
            pulpFictionBackendService.createPost(createCommentRequest).postMetadata
        }

        val commentFeedRequest = generateRandomGetCommentFeedRequest(
            loginSession,
            imagePostMetadata.postUpdateIdentifier.postId
        )
        val clientFeedRequests = listOf(commentFeedRequest, commentFeedRequest)
        val commentFeed = pulpFictionBackendService.getFeed(
            flow {
                clientFeedRequests.map { emit(it) }
            }
        )
        val feedList = commentFeed.take(clientFeedRequests.size).toList()
        feedList
            .map { resp ->
                resp.postsList.map { post ->
                    post.metadata.postUpdateIdentifier.postId
                }
            }
            .assertEquals(
                listOf(
                    createdComments.map { postMetadata ->
                        postMetadata.postUpdateIdentifier.postId
                    }.reversed(),
                    emptyList()
                )
            )

        EndpointName.getFeed.assertEndpointMetricsCorrect(1.0)
        Tuple2(
            EndpointName.getFeed,
            DatabaseMetrics.DatabaseOperation.getFeed
        )
            .assertDatabaseMetricsCorrect(2.0)
    }
}
