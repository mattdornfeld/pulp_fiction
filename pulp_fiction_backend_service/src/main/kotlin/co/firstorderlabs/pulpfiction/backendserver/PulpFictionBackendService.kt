package co.firstorderlabs.pulpfiction.backendserver

import arrow.core.continuations.effect
import co.firstorderlabs.protos.pulpfiction.PulpFictionGrpcKt
import co.firstorderlabs.protos.pulpfiction.PulpFictionProtos
import co.firstorderlabs.protos.pulpfiction.PulpFictionProtos.Post
import co.firstorderlabs.protos.pulpfiction.createPostResponse
import co.firstorderlabs.protos.pulpfiction.createUserResponse
import co.firstorderlabs.protos.pulpfiction.getPostResponse
import co.firstorderlabs.protos.pulpfiction.loginResponse
import co.firstorderlabs.pulpfiction.backendserver.monitoring.metrics.collectors.LabelValue
import co.firstorderlabs.pulpfiction.backendserver.monitoring.metrics.metricsstore.EndpointMetrics.logEndpointMetrics
import co.firstorderlabs.pulpfiction.backendserver.types.PulpFictionError
import co.firstorderlabs.pulpfiction.backendserver.utils.getResultAndHandleErrors
import org.ktorm.database.Database
import software.amazon.awssdk.services.s3.S3Client

data class PulpFictionBackendService(val database: Database, val s3Client: S3Client) :
    PulpFictionGrpcKt.PulpFictionCoroutineImplBase() {
    private val databaseMessenger = DatabaseMessenger(database, s3Client)

    enum class EndpointName : LabelValue {
        createPost,
        createUser,
        getPost,
        login;

        override fun getValue(): String = name
    }

    override suspend fun createPost(request: PulpFictionProtos.CreatePostRequest): PulpFictionProtos.CreatePostResponse {
        return logEndpointMetrics(EndpointName.createPost) {
            val postProto = effect<PulpFictionError, PulpFictionProtos.Post> {
                databaseMessenger.checkLoginSessionValid(request.loginSession).bind()
                databaseMessenger.createPost(request).bind()
            }.getResultAndHandleErrors()

            createPostResponse {
                this.postMetadata = postProto.metadata
            }
        }
    }

    override suspend fun createUser(request: PulpFictionProtos.CreateUserRequest): PulpFictionProtos.CreateUserResponse {
        return logEndpointMetrics(EndpointName.createUser) {
            val userPost = databaseMessenger
                .createUser(request)
                .getResultAndHandleErrors()

            createUserResponse {
                this.userPost = userPost
            }
        }
    }

    override suspend fun login(request: PulpFictionProtos.LoginRequest): PulpFictionProtos.LoginResponse {
        return logEndpointMetrics(EndpointName.login) {
            val loginSession = databaseMessenger.createLoginSession(request).getResultAndHandleErrors()

            loginResponse {
                this.loginSession = loginSession.toProto()
            }
        }
    }

    override suspend fun getPost(request: PulpFictionProtos.GetPostRequest): PulpFictionProtos.GetPostResponse {
        return logEndpointMetrics(EndpointName.getPost) {
            val post = effect<PulpFictionError, Post> {
                databaseMessenger.checkLoginSessionValid(request.loginSession).bind()
                databaseMessenger.getPost(request).bind()
            }.getResultAndHandleErrors()

            getPostResponse {
                this.post = post
            }
        }
    }
}
