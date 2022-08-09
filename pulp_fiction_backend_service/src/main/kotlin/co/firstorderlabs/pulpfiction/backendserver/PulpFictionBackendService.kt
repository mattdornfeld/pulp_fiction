package co.firstorderlabs.pulpfiction.backendserver

import arrow.core.continuations.Effect
import arrow.core.continuations.effect
import co.firstorderlabs.protos.pulpfiction.PulpFictionGrpcKt
import co.firstorderlabs.protos.pulpfiction.PulpFictionProtos
import co.firstorderlabs.protos.pulpfiction.PulpFictionProtos.CreatePostResponse
import co.firstorderlabs.protos.pulpfiction.PulpFictionProtos.CreateUserResponse
import co.firstorderlabs.protos.pulpfiction.PulpFictionProtos.GetPostResponse
import co.firstorderlabs.protos.pulpfiction.PulpFictionProtos.GetUserResponse
import co.firstorderlabs.protos.pulpfiction.PulpFictionProtos.LoginResponse
import co.firstorderlabs.protos.pulpfiction.createPostResponse
import co.firstorderlabs.protos.pulpfiction.createUserResponse
import co.firstorderlabs.protos.pulpfiction.getPostResponse
import co.firstorderlabs.protos.pulpfiction.getUserResponse
import co.firstorderlabs.protos.pulpfiction.loginResponse
import co.firstorderlabs.pulpfiction.backendserver.monitoring.metrics.metricsstore.DatabaseMetrics.DatabaseOperation
import co.firstorderlabs.pulpfiction.backendserver.monitoring.metrics.metricsstore.DatabaseMetrics.logDatabaseMetrics
import co.firstorderlabs.pulpfiction.backendserver.monitoring.metrics.metricsstore.EndpointMetrics.EndpointName
import co.firstorderlabs.pulpfiction.backendserver.monitoring.metrics.metricsstore.EndpointMetrics.logEndpointMetrics
import co.firstorderlabs.pulpfiction.backendserver.types.PulpFictionRequestError
import co.firstorderlabs.pulpfiction.backendserver.utils.getResultAndThrowException
import org.ktorm.database.Database
import software.amazon.awssdk.services.s3.S3Client

data class PulpFictionBackendService(val database: Database, val s3Client: S3Client) :
    PulpFictionGrpcKt.PulpFictionCoroutineImplBase() {
    private val databaseMessenger = DatabaseMessenger(database, s3Client)

    private suspend fun checkLoginSessionValid(
        loginSession: LoginResponse.LoginSession,
        endpointName: EndpointName
    ): Effect<PulpFictionRequestError, Unit> =
        databaseMessenger
            .checkLoginSessionValid(loginSession)
            .logDatabaseMetrics(endpointName, DatabaseOperation.checkLoginSessionValid)

    override suspend fun createPost(request: PulpFictionProtos.CreatePostRequest): PulpFictionProtos.CreatePostResponse {
        val endpointName = EndpointName.createPost
        return effect<PulpFictionRequestError, CreatePostResponse> {
            checkLoginSessionValid(request.loginSession, endpointName).bind()

            val postProto = databaseMessenger
                .createPost(request)
                .logDatabaseMetrics(endpointName, DatabaseOperation.createPost)
                .bind()

            createPostResponse {
                this.postMetadata = postProto.metadata
            }
        }
            .logEndpointMetrics(endpointName)
            .getResultAndThrowException()
    }

    override suspend fun createUser(request: PulpFictionProtos.CreateUserRequest): PulpFictionProtos.CreateUserResponse {
        val endpointName = EndpointName.createUser
        return effect<PulpFictionRequestError, CreateUserResponse> {
            val userPost = databaseMessenger
                .createUser(request)
                .logDatabaseMetrics(endpointName, DatabaseOperation.createUser)
                .bind()

            createUserResponse {
                this.userPost = userPost
            }
        }
            .logEndpointMetrics(endpointName)
            .getResultAndThrowException()
    }

    override suspend fun login(request: PulpFictionProtos.LoginRequest): PulpFictionProtos.LoginResponse {
        val endpointName = EndpointName.login
        return effect<PulpFictionRequestError, LoginResponse> {
            databaseMessenger
                .checkUserPasswordValid(request)
                .logDatabaseMetrics(endpointName, DatabaseOperation.checkUserPasswordValid)
                .bind()

            val loginSession = databaseMessenger
                .createLoginSession(request)
                .logDatabaseMetrics(endpointName, DatabaseOperation.login)
                .bind()

            loginResponse {
                this.loginSession = loginSession.toProto()
            }
        }
            .logEndpointMetrics(endpointName)
            .getResultAndThrowException()
    }

    override suspend fun getPost(request: PulpFictionProtos.GetPostRequest): PulpFictionProtos.GetPostResponse {
        val endpointName = EndpointName.getPost
        return effect<PulpFictionRequestError, GetPostResponse> {
            checkLoginSessionValid(request.loginSession, endpointName).bind()

            val post = databaseMessenger
                .getPost(request)
                .logDatabaseMetrics(endpointName, DatabaseOperation.getPost)
                .bind()

            getPostResponse {
                this.post = post
            }
        }
            .logEndpointMetrics(endpointName)
            .getResultAndThrowException()
    }

    override suspend fun getUser(request: PulpFictionProtos.GetUserRequest): PulpFictionProtos.GetUserResponse {
        val endpointName = EndpointName.getUser
        return effect<PulpFictionRequestError, GetUserResponse> {
            checkLoginSessionValid(request.loginSession, endpointName).bind()

            val userMetadata = databaseMessenger
                .getPublicUserMetadata(request)
                .logDatabaseMetrics(endpointName, DatabaseOperation.getUser)
                .bind()
            getUserResponse {
                this.userMetadata = userMetadata
            }
        }
            .logEndpointMetrics(endpointName)
            .getResultAndThrowException()
    }
}
