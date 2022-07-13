package co.firstorderlabs.pulpfiction.backendserver

import arrow.core.Either
import co.firstorderlabs.protos.pulpfiction.PulpFictionProtos
import co.firstorderlabs.protos.pulpfiction.PulpFictionProtos.CreatePostRequest
import co.firstorderlabs.protos.pulpfiction.PulpFictionProtos.CreateUserRequest
import co.firstorderlabs.protos.pulpfiction.PulpFictionProtos.GetPostRequest
import co.firstorderlabs.protos.pulpfiction.PulpFictionProtos.LoginRequest
import co.firstorderlabs.protos.pulpfiction.PulpFictionProtos.LoginResponse.LoginSession
import co.firstorderlabs.protos.pulpfiction.PulpFictionProtos.Post.PostState
import co.firstorderlabs.protos.pulpfiction.getPostRequest
import co.firstorderlabs.pulpfiction.backendserver.TestProtoModelGenerator.buildGetPostRequest
import co.firstorderlabs.pulpfiction.backendserver.TestProtoModelGenerator.generateRandomCreatePostRequest
import co.firstorderlabs.pulpfiction.backendserver.TestProtoModelGenerator.generateRandomGetPostRequest
import co.firstorderlabs.pulpfiction.backendserver.TestProtoModelGenerator.withRandomCreateCommentRequest
import co.firstorderlabs.pulpfiction.backendserver.TestProtoModelGenerator.withRandomCreateImagePostRequest
import co.firstorderlabs.pulpfiction.backendserver.monitoring.metrics.collectors.PulpFictionMetric
import co.firstorderlabs.pulpfiction.backendserver.monitoring.metrics.metricsstore.EndpointMetrics
import co.firstorderlabs.pulpfiction.backendserver.testutils.TestContainerDependencies
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
import org.ktorm.entity.tupleOf
import org.testcontainers.containers.PostgreSQLContainer
import org.testcontainers.containers.localstack.LocalStackContainer
import org.testcontainers.junit.jupiter.Container
import org.testcontainers.junit.jupiter.Testcontainers

private typealias RequestAndResponseSuppliers = List<Pair<com.google.protobuf.GeneratedMessageV3, suspend (com.google.protobuf.GeneratedMessageV3) -> com.google.protobuf.GeneratedMessageV3>>

@Testcontainers
internal class PulpFictionBackendServiceTest {
    companion object : TestContainerDependencies() {
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

    private fun PulpFictionBackendService.EndpointName.assertMetricsCorrectForEndpoint(expectedNumEndpointCalls: Double) {
        EndpointMetrics
            .endpointRequestTotal
            .withLabels(this)
            .assertEquals(expectedNumEndpointCalls) { it.get() }

        EndpointMetrics
            .endpointRequestDurationSeconds
            .withLabels(this)
            .assertEquals(expectedNumEndpointCalls) { it.get().count }
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

            PulpFictionBackendService
                .EndpointName
                .createUser
                .assertMetricsCorrectForEndpoint(1.0)

            // TODO (matt): Check user is retrievable after getUser endpoint implemented
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

            PulpFictionBackendService
                .EndpointName
                .login
                .assertMetricsCorrectForEndpoint(1.0)
        }
    }

    @Test
    fun testLoginRequired() {
        runBlocking {
            val loginSession = TestProtoModelGenerator.generateRandomLoginSession()

            val requestAndResponseSuppliers: RequestAndResponseSuppliers =
                listOf(
                    tupleOf(loginSession.generateRandomCreatePostRequest()) { pulpFictionBackendService.createPost(it as CreatePostRequest) },
                    tupleOf(loginSession.generateRandomGetPostRequest()) { pulpFictionBackendService.getPost(it as GetPostRequest) }
                )

            requestAndResponseSuppliers.forEach { requestAndResponseSupplier ->
                val request = requestAndResponseSupplier.first
                val responseSupplier = requestAndResponseSupplier.second

                Either.catch { responseSupplier(request) }
                    .assertTrue { it.isLeft() }
                    .mapLeft { error ->
                        error
                            .assertTrue { it is StatusException }
                            .assertTrue { it.cause is LoginSessionInvalidError }
                            .assertEquals(Status.UNAUTHENTICATED.code) { (it as StatusException).status.code }
                    }
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

        PulpFictionBackendService
            .EndpointName
            .createPost
            .assertMetricsCorrectForEndpoint(1.0)
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

        PulpFictionBackendService
            .EndpointName
            .createPost
            .assertMetricsCorrectForEndpoint(2.0)
    }
}
