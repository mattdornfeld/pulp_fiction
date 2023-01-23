package co.firstorderlabs.pulpfiction.backendserver

import arrow.core.continuations.Effect
import arrow.core.continuations.effect
import co.firstorderlabs.protos.pulpfiction.PulpFictionGrpcKt
import co.firstorderlabs.protos.pulpfiction.PulpFictionProtos
import co.firstorderlabs.protos.pulpfiction.PulpFictionProtos.CreatePostResponse
import co.firstorderlabs.protos.pulpfiction.PulpFictionProtos.CreateUserResponse
import co.firstorderlabs.protos.pulpfiction.PulpFictionProtos.GetPostResponse
import co.firstorderlabs.protos.pulpfiction.PulpFictionProtos.GetUserResponse
import co.firstorderlabs.protos.pulpfiction.createLoginSessionResponse
import co.firstorderlabs.protos.pulpfiction.createPostResponse
import co.firstorderlabs.protos.pulpfiction.createUserResponse
import co.firstorderlabs.protos.pulpfiction.getFeedResponse
import co.firstorderlabs.protos.pulpfiction.getPostResponse
import co.firstorderlabs.protos.pulpfiction.getUserResponse
import co.firstorderlabs.pulpfiction.backendserver.monitoring.metrics.metricsstore.DatabaseMetrics.DatabaseOperation
import co.firstorderlabs.pulpfiction.backendserver.monitoring.metrics.metricsstore.DatabaseMetrics.logDatabaseMetrics
import co.firstorderlabs.pulpfiction.backendserver.monitoring.metrics.metricsstore.EndpointMetrics.EndpointName
import co.firstorderlabs.pulpfiction.backendserver.monitoring.metrics.metricsstore.EndpointMetrics.logEndpointMetrics
import co.firstorderlabs.pulpfiction.backendserver.types.PulpFictionRequestError
import co.firstorderlabs.pulpfiction.backendserver.utils.getResultAndThrowException
import co.firstorderlabs.pulpfiction.backendserver.utils.toTimestamp
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.collectIndexed
import kotlinx.coroutines.flow.flow
import org.ktorm.database.Database
import software.amazon.awssdk.services.s3.S3Client

data class PulpFictionBackendService(val database: Database, val s3Client: S3Client) :
    PulpFictionGrpcKt.PulpFictionCoroutineImplBase() {
    private val databaseMessenger = DatabaseMessenger(database, s3Client)

    private suspend fun checkLoginSessionValid(
        loginSession: PulpFictionProtos.CreateLoginSessionResponse.LoginSession,
        endpointName: EndpointName
    ): Effect<PulpFictionRequestError, Unit> =
        databaseMessenger
            .checkLoginSessionValid(loginSession)
            .logDatabaseMetrics(endpointName, DatabaseOperation.checkLoginSessionValid)

    override suspend fun createLoginSession(request: PulpFictionProtos.CreateLoginSessionRequest): PulpFictionProtos.CreateLoginSessionResponse {
        val endpointName = EndpointName.createLoginSession
        return effect<PulpFictionRequestError, PulpFictionProtos.CreateLoginSessionResponse> {
            val user = databaseMessenger
                .checkPasswordValidAndGetUser(request)
                .logDatabaseMetrics(endpointName, DatabaseOperation.checkUserPasswordValid)
                .bind()

            val loginSession = databaseMessenger
                .createLoginSession(user, request)
                .logDatabaseMetrics(endpointName, DatabaseOperation.login)
                .bind()

            createLoginSessionResponse {
                this.loginSession = loginSession
            }
        }
            .logEndpointMetrics(endpointName)
            .getResultAndThrowException()
    }

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
            val user = databaseMessenger
                .createUser(request)
                .logDatabaseMetrics(endpointName, DatabaseOperation.createUser)
                .bind()

            createUserResponse {
                this.userId = user.userId.toString()
                this.createdAt = user.createdAt.toTimestamp()
            }
        }
            .logEndpointMetrics(endpointName)
            .getResultAndThrowException()
    }

    override fun getFeed(requests: Flow<PulpFictionProtos.GetFeedRequest>): Flow<PulpFictionProtos.GetFeedResponse> {
        val endpointName = EndpointName.getFeed
        return flow {
            requests.collectIndexed { idx, request ->
                checkLoginSessionValid(request.loginSession, endpointName).getResultAndThrowException()

                val postsFeed = databaseMessenger
                    .getFeed(request, idx)
                    .logDatabaseMetrics(endpointName, DatabaseOperation.getFeed)
                    .getResultAndThrowException()
                emit(
                    getFeedResponse {
                        this.posts += postsFeed
                    }
                )
            }
        }
            .logEndpointMetrics(endpointName)
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

    override suspend fun updateLoginSession(request: PulpFictionProtos.UpdateLoginSessionRequest): PulpFictionProtos.UpdateLoginSessionResponse =
        effect<PulpFictionRequestError, PulpFictionProtos.UpdateLoginSessionResponse> {
            checkLoginSessionValid(request.loginSession, EndpointName.updateLoginSession).bind()
            databaseMessenger
                .logout(request.loginSession)
                .logDatabaseMetrics(EndpointName.updateLoginSession, DatabaseOperation.logout)
                .bind()
        }
            .logEndpointMetrics(EndpointName.updateLoginSession)
            .getResultAndThrowException()

    override suspend fun updatePost(request: PulpFictionProtos.UpdatePostRequest): PulpFictionProtos.UpdatePostResponse =
        effect<PulpFictionRequestError, PulpFictionProtos.UpdatePostResponse> {
            checkLoginSessionValid(request.loginSession, EndpointName.updatePost).bind()
            databaseMessenger
                .updatePost(request)
                .bind()
        }
            .logEndpointMetrics(EndpointName.updatePost)
            .getResultAndThrowException()

    override suspend fun updateUser(request: PulpFictionProtos.UpdateUserRequest): PulpFictionProtos.UpdateUserResponse {
        val endpointName = EndpointName.updateUser
        return effect<PulpFictionRequestError, PulpFictionProtos.UpdateUserResponse> {
            checkLoginSessionValid(request.loginSession, endpointName).bind()
            databaseMessenger
                .updateUser(request)
                .logDatabaseMetrics(endpointName, DatabaseOperation.updateUser)
                .bind()
        }
            .logEndpointMetrics(endpointName)
            .getResultAndThrowException()
    }
}
