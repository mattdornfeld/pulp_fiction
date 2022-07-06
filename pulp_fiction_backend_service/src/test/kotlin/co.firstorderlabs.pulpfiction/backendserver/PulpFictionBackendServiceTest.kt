package co.firstorderlabs.pulpfiction.backendserver

import arrow.core.Either
import co.firstorderlabs.protos.pulpfiction.PulpFictionProtos.CreateUserRequest
import co.firstorderlabs.protos.pulpfiction.PulpFictionProtos.LoginRequest
import co.firstorderlabs.protos.pulpfiction.PulpFictionProtos.LoginResponse.LoginSession
import co.firstorderlabs.protos.pulpfiction.PulpFictionProtos.Post.PostState
import co.firstorderlabs.protos.pulpfiction.PulpFictionProtos.User.UserMetadata
import co.firstorderlabs.pulpfiction.backendserver.TestProtoModelGenerator.generateRandomCreatePostRequest
import co.firstorderlabs.pulpfiction.backendserver.TestProtoModelGenerator.withRandomCreateCommentRequest
import co.firstorderlabs.pulpfiction.backendserver.TestProtoModelGenerator.withRandomCreateImagePostRequest
import co.firstorderlabs.pulpfiction.backendserver.testutils.TestContainerDependencies
import co.firstorderlabs.pulpfiction.backendserver.testutils.isWithinLast
import co.firstorderlabs.pulpfiction.backendserver.types.LoginSessionInvalidError
import co.firstorderlabs.pulpfiction.backendserver.utils.toUUID
import com.adobe.testing.s3mock.testcontainers.S3MockContainer
import io.grpc.Status
import io.grpc.StatusException
import kotlinx.coroutines.runBlocking
import org.junit.jupiter.api.AfterEach
import org.junit.jupiter.api.Assertions
import org.junit.jupiter.api.BeforeAll
import org.junit.jupiter.api.Test
import org.ktorm.dsl.deleteAll
import org.ktorm.entity.Tuple2
import org.testcontainers.containers.PostgreSQLContainer
import org.testcontainers.junit.jupiter.Container
import org.testcontainers.junit.jupiter.Testcontainers

@Testcontainers
internal class PulpFictionBackendServiceTest {
    companion object : TestContainerDependencies() {
        @Container
        override val postgreSQLContainer: PostgreSQLContainer<Nothing> = createPostgreSQLContainer()

        @Container
        override val s3MockContainer: S3MockContainer = createS3MockContainer()

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

    private suspend fun createUser(): Tuple2<UserMetadata, CreateUserRequest> {
        val createUserRequest = TestProtoModelGenerator.generateRandomCreateUserRequest()
        return Tuple2(pulpFictionBackendService.createUser(createUserRequest).userMetadata, createUserRequest)
    }

    private suspend fun createUserAndLogin(): Tuple2<LoginSession, LoginRequest> {
        val tuple2 = createUser()
        val userMetadata = tuple2.first
        val createUserRequest = tuple2.second
        val loginRequest =
            TestProtoModelGenerator.generateRandomLoginRequest(userMetadata.userId, createUserRequest.password)
        return Tuple2(pulpFictionBackendService.login(loginRequest).loginSession, loginRequest)
    }

    @Test
    fun testCreateUser() {
        runBlocking {
            val userMetadata = createUser().first
            Assertions.assertTrue(userMetadata.userId.toUUID().isRight())
            Assertions.assertTrue(userMetadata.createdAt.isWithinLast(100))
            // TODO (matt): Check user is retrievable after getUser endpoint implemented
            // TODO (matt): Check avatarImageURL is valid after image uploading is implemented
        }
    }

    @Test
    fun testLogin() {
        runBlocking {
            val tuple2 = createUserAndLogin()
            val loginSession = tuple2.first
            val loginRequest = tuple2.second
            Assertions.assertTrue(loginSession.sessionToken.toUUID().isRight())
            Assertions.assertTrue(loginSession.createdAt.isWithinLast(100))
            Assertions.assertEquals(loginRequest.deviceId, loginSession.deviceId)
        }
    }

    @Test
    fun testLoginRequired() {
        runBlocking {
            val loginSession = TestProtoModelGenerator.generateRandomLoginSession()
            val createPostRequest = loginSession.generateRandomCreatePostRequest()
            val either = Either.catch {
                pulpFictionBackendService.createPost(createPostRequest)
            }
            Assertions.assertTrue(either.isLeft())
            either.mapLeft {
                Assertions.assertTrue(it is StatusException)
                Assertions.assertTrue(it.cause is LoginSessionInvalidError)
                Assertions.assertEquals(Status.UNAUTHENTICATED.code, (it as StatusException).status.code)
            }
        }
    }

    @Test
    fun testCreateImagePost() {
        runBlocking {
            val loginSession = createUserAndLogin().first

            val createPostRequest = loginSession
                .generateRandomCreatePostRequest()
                .withRandomCreateImagePostRequest()
            val postMetadata = pulpFictionBackendService.createPost(createPostRequest).postMetadata

            Assertions.assertEquals(loginSession.userId, postMetadata.postCreatorId)
            Assertions.assertTrue(postMetadata.createdAt.isWithinLast(100))
            Assertions.assertEquals(PostState.CREATED, postMetadata.postState)
            // TODO (matt): Check post is retrievable after getPost endpoint implemented
            // TODO (matt): Check imageURL is valid after image uploading is implemented
        }
    }

    @Test
    fun testCreateComment() {
        runBlocking {
            val loginSession = createUserAndLogin().first

            val createImagePostRequest = loginSession
                .generateRandomCreatePostRequest()
                .withRandomCreateImagePostRequest()
            val imagePostMetadata = pulpFictionBackendService.createPost(createImagePostRequest).postMetadata

            val createCommentRequest = loginSession
                .generateRandomCreatePostRequest()
                .withRandomCreateCommentRequest(imagePostMetadata.postId)
            val commentMetadata = pulpFictionBackendService.createPost(createCommentRequest).postMetadata

            Assertions.assertEquals(loginSession.userId, commentMetadata.postCreatorId)
            Assertions.assertTrue(commentMetadata.createdAt.isWithinLast(100))
            Assertions.assertEquals(PostState.CREATED, commentMetadata.postState)
            // TODO (matt): Check post is retrievable after getPost endpoint implemented and assert comment post parent id
        }
    }
}
