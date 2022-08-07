package co.firstorderlabs.pulpfiction.backendserver

import arrow.core.Either
import co.firstorderlabs.protos.pulpfiction.PulpFictionProtos
import co.firstorderlabs.protos.pulpfiction.PulpFictionProtos.CreatePostRequest
import co.firstorderlabs.protos.pulpfiction.PulpFictionProtos.CreateUserRequest
import co.firstorderlabs.protos.pulpfiction.PulpFictionProtos.GetPostRequest
import co.firstorderlabs.protos.pulpfiction.PulpFictionProtos.LoginRequest
import co.firstorderlabs.protos.pulpfiction.PulpFictionProtos.LoginResponse.LoginSession
import co.firstorderlabs.protos.pulpfiction.PulpFictionProtos.Post.PostState
import co.firstorderlabs.protos.pulpfiction.PulpFictionProtos.Post.PostType
import co.firstorderlabs.protos.pulpfiction.getPostRequest
import co.firstorderlabs.protos.pulpfiction.getUserRequest
import co.firstorderlabs.pulpfiction.backendserver.TestProtoModelGenerator.buildGetPostRequest
import co.firstorderlabs.pulpfiction.backendserver.TestProtoModelGenerator.generateRandomCreatePostRequest
import co.firstorderlabs.pulpfiction.backendserver.TestProtoModelGenerator.generateRandomGetPostRequest
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
import co.firstorderlabs.pulpfiction.backendserver.utils.getResultAndHandleErrors
import co.firstorderlabs.pulpfiction.backendserver.utils.toUUID
import io.grpc.Status
import io.grpc.StatusException
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
        override val postgreSQLContainer: PostgreSQLContainer<Nothing> = createPostgreSQLContainer()

        @Container
        override val localStackContainer: LocalStackContainer = createLockStackContainer()

        @BeforeAll
        @JvmStatic
        override fun migrateDatabase() = super.migrateDatabase()

        private val pulpFictionBackendService by lazy { PulpFictionBackendService(database, s3Client) }
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

    private suspend fun createUser(): Tuple2<PulpFictionProtos.Post, CreateUserRequest> {
        val createUserRequest = TestProtoModelGenerator.generateRandomCreateUserRequest()
        return Tuple2(pulpFictionBackendService.createUser(createUserRequest).userPost, createUserRequest)
    }

    private suspend fun createUserAndLogin(): Tuple2<LoginSession, LoginRequest> {
        val tuple2 = createUser()
        val userMetadata = tuple2.first.userPost.userMetadata
        val createUserRequest = tuple2.second
        val loginRequest =
            TestProtoModelGenerator.generateRandomLoginRequest(userMetadata.userId, createUserRequest.password)
        return Tuple2(pulpFictionBackendService.login(loginRequest).loginSession, loginRequest)
    }

    private suspend fun createFailingLoginRequests(): List<LoginRequest> {
        val tuple2 = createUser()
        val userMetadata = tuple2.first.userPost.userMetadata
        val createUserRequest = tuple2.second

        val incorrectUser = UUID.randomUUID().toString()
        val incorrectPassword = "fail_${createUserRequest.password}"

        val loginRequestWrongUser =
            TestProtoModelGenerator.generateRandomLoginRequest(
                incorrectUser,
                createUserRequest.password
            )
        val loginRequestWrongPass =
            TestProtoModelGenerator.generateRandomLoginRequest(userMetadata.userId, incorrectPassword)

        return listOf(loginRequestWrongUser, loginRequestWrongPass)
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
            val t2 = createUser()
            val post = t2.first
            val userMetadata = post.userPost.userMetadata
            val createUserRequest = t2.second

            userMetadata
                .assertTrue { it.userId.toUUID().isRight() }
                .assertTrue { it.createdAt.isWithinLast(100) }

            val loginRequest =
                TestProtoModelGenerator.generateRandomLoginRequest(
                    userMetadata.userId,
                    createUserRequest.password
                )
            val loginSession = pulpFictionBackendService.login(loginRequest).loginSession

            val userPost = pulpFictionBackendService.getPost(
                getPostRequest {
                    this.loginSession = loginSession
                    this.postId = post.metadata.postId
                }
            ).post.userPost

            s3Messenger
                .getObject(userPost.userMetadata.avatarImageUrl)
                .getResultAndHandleErrors()
                .assertEquals(
                    "The user avatar stored in s3 should be the one passed in to the CreateUser endpoint",
                    createUserRequest.avatarJpg
                ) { it }

            // TODO (matt): Check user is retrievable after getUser endpoint implemented

            EndpointName.createUser
                .assertEndpointMetricsCorrect(1.0)

            listOf(
                tupleOf(EndpointName.createUser, DatabaseMetrics.DatabaseOperation.createUser, 1.0),
                tupleOf(EndpointName.login, DatabaseMetrics.DatabaseOperation.login, 1.0),
                tupleOf(EndpointName.getPost, DatabaseMetrics.DatabaseOperation.getPost, 1.0),
            ).assertDatabaseMetricsCorrect()

            tupleOf(
                EndpointName.createPost, S3Metrics.S3Operation.uploadUserAvatar
            ).assertS3MetricsCorrect(1.0)

            PostType.USER
                .assertCreatePostDataMetricsCorrect(1.0)
        }
    }

    @Test
    fun testGetUser() {
        runBlocking {
            val tuple2 = createUser()
            val post = tuple2.first
            val createdUserMetadata = post.userPost.userMetadata
            val createUserRequest = tuple2.second

            val loginRequest =
                TestProtoModelGenerator.generateRandomLoginRequest(
                    createdUserMetadata.userId,
                    createUserRequest.password
                )
            val loginSession = pulpFictionBackendService.login(loginRequest).loginSession

            val user = pulpFictionBackendService.getUser(
                getUserRequest {
                    this.loginSession = loginSession
                    this.userId = createdUserMetadata.userId
                }
            )

            user.userMetadata
                .assertEquals(createdUserMetadata.userId) { it.userId }
                .assertEquals(createdUserMetadata.displayName) { it.displayName }
                .assertEquals(createdUserMetadata.avatarImageUrl) { it.avatarImageUrl }

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
            loginRequests.zip(expectedExceptions) {
                loginRequest, expectedException ->
                Either.catch { pulpFictionBackendService.login(loginRequest) }
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
                    ) { pulpFictionBackendService.createPost(it as CreatePostRequest) },
                    tupleOf(
                        EndpointName.getPost,
                        loginSession.generateRandomGetPostRequest()
                    ) { pulpFictionBackendService.getPost(it as GetPostRequest) }
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
            .assertEquals(loginSession.userId) { it.postCreatorId }
            .assertEquals(PostState.CREATED) { it.postState }
            .assertTrue { it.createdAt.isWithinLast(100) }

        val getPostRequest = loginSession.buildGetPostRequest(postMetadata)
        val post = pulpFictionBackendService.getPost(getPostRequest).post

        post
            .assertEquals(postMetadata) { it.metadata }
            .assertEquals(createPostRequest.createImagePostRequest.caption) { it.imagePost.caption }

        s3Messenger
            .getObject(post.imagePost.imageUrl)
            .getResultAndHandleErrors()
            .assertEquals(
                "The imageJpg uploaded to s3 should equal the imageJpg in the create post request",
                createPostRequest.createImagePostRequest.imageJpg
            ) { it }

        listOf(
            tupleOf(EndpointName.createPost, 1.0),
            tupleOf(EndpointName.getPost, 1.0)
        )
            .assertEndpointMetricsCorrect()

        listOf(
            tupleOf(EndpointName.createPost, DatabaseMetrics.DatabaseOperation.createPost, 1.0),
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
            .withRandomCreateCommentRequest(imagePostMetadata.postId)
        val postMetadata = pulpFictionBackendService.createPost(createCommentRequest).postMetadata

        postMetadata
            .assertEquals(loginSession.userId) { it.postCreatorId }
            .assertTrue { postMetadata.createdAt.isWithinLast(100) }
            .assertEquals(PostState.CREATED) { it.postState }

        val getPostRequest = loginSession.buildGetPostRequest(postMetadata)
        val post = pulpFictionBackendService.getPost(getPostRequest).post

        post
            .assertEquals(postMetadata) { it.metadata }
            .assertEquals(createCommentRequest.createCommentRequest.body) { it.comment.body }

        listOf(
            tupleOf(EndpointName.createPost, 2.0),
            tupleOf(EndpointName.getPost, 1.0)
        )
            .assertEndpointMetricsCorrect()

        listOf(
            tupleOf(EndpointName.createPost, DatabaseMetrics.DatabaseOperation.createPost, 2.0),
            tupleOf(EndpointName.getPost, DatabaseMetrics.DatabaseOperation.getPost, 1.0),
        ).assertDatabaseMetricsCorrect()

        PostType.COMMENT
            .assertCreatePostDataMetricsCorrect(1.0)
    }
}
