package co.firstorderlabs.pulpfiction.backendserver

import arrow.core.continuations.effect
import co.firstorderlabs.protos.pulpfiction.PulpFictionGrpcKt
import co.firstorderlabs.protos.pulpfiction.PulpFictionProtos
import co.firstorderlabs.protos.pulpfiction.PulpFictionProtos.Post.PostMetadata
import co.firstorderlabs.protos.pulpfiction.createPostResponse
import co.firstorderlabs.protos.pulpfiction.createUserResponse
import co.firstorderlabs.protos.pulpfiction.loginResponse
import co.firstorderlabs.pulpfiction.backendserver.types.PulpFictionError
import co.firstorderlabs.pulpfiction.backendserver.utils.getResultAndHandleErrors
import org.ktorm.database.Database
import software.amazon.awssdk.services.s3.S3Client

data class PulpFictionBackendService(val database: Database, val s3Client: S3Client) : PulpFictionGrpcKt.PulpFictionCoroutineImplBase() {
    private val databaseMessenger = DatabaseMessenger(database, s3Client)
    override suspend fun createPost(request: PulpFictionProtos.CreatePostRequest): PulpFictionProtos.CreatePostResponse {
        val postMetadata = effect<PulpFictionError, PostMetadata> {
            databaseMessenger.checkLoginSessionValid(request.loginSession).bind()
            databaseMessenger.createPost(request).bind()
        }.getResultAndHandleErrors()

        return createPostResponse {
            this.postMetadata = postMetadata
        }
    }

    override suspend fun createUser(request: PulpFictionProtos.CreateUserRequest): PulpFictionProtos.CreateUserResponse {
        val nonSensitiveUserMetadata = databaseMessenger
            .createUser(request)
            .getResultAndHandleErrors()

        return createUserResponse {
            this.userMetadata = nonSensitiveUserMetadata
        }
    }

    override suspend fun login(request: PulpFictionProtos.LoginRequest): PulpFictionProtos.LoginResponse {
        val loginSession = databaseMessenger.createLoginSession(request).getResultAndHandleErrors()

        return loginResponse {
            this.loginSession = loginSession.toLoginSessionProto()
        }
    }
}
