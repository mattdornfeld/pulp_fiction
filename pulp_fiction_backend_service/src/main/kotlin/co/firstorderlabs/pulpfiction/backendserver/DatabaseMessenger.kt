package co.firstorderlabs.pulpfiction.backendserver

import arrow.core.continuations.Effect
import arrow.core.continuations.effect
import arrow.core.getOrElse
import co.firstorderlabs.protos.pulpfiction.PulpFictionProtos
import co.firstorderlabs.protos.pulpfiction.PulpFictionProtos.LoginRequest
import co.firstorderlabs.protos.pulpfiction.PulpFictionProtos.Post.PostMetadata
import co.firstorderlabs.pulpfiction.backendserver.configs.ServiceConfigs.MAX_AGE_LOGIN_SESSION
import co.firstorderlabs.pulpfiction.backendserver.database.models.LoginSession
import co.firstorderlabs.pulpfiction.backendserver.database.models.LoginSessions
import co.firstorderlabs.pulpfiction.backendserver.database.models.Post
import co.firstorderlabs.pulpfiction.backendserver.database.models.PostId
import co.firstorderlabs.pulpfiction.backendserver.database.models.User
import co.firstorderlabs.pulpfiction.backendserver.database.models.loginSessions
import co.firstorderlabs.pulpfiction.backendserver.database.models.postIds
import co.firstorderlabs.pulpfiction.backendserver.database.models.posts
import co.firstorderlabs.pulpfiction.backendserver.database.models.users
import co.firstorderlabs.pulpfiction.backendserver.types.LoginSessionInvalidError
import co.firstorderlabs.pulpfiction.backendserver.types.PulpFictionError
import co.firstorderlabs.pulpfiction.backendserver.utils.firstOrOption
import co.firstorderlabs.pulpfiction.backendserver.utils.toUUID
import co.firstorderlabs.pulpfiction.backendserver.utils.transactionToEffect
import org.ktorm.database.Database
import org.ktorm.dsl.and
import org.ktorm.dsl.desc
import org.ktorm.dsl.eq
import org.ktorm.dsl.from
import org.ktorm.dsl.greater
import org.ktorm.dsl.limit
import org.ktorm.dsl.map
import org.ktorm.dsl.orderBy
import org.ktorm.dsl.select
import org.ktorm.dsl.where
import org.ktorm.entity.add
import java.time.Instant

data class DatabaseMessenger(val database: Database) {
    fun checkLoginSessionValid(loginSessionProto: PulpFictionProtos.LoginResponse.LoginSession): Effect<PulpFictionError, Unit> =
        effect {
            val userId = loginSessionProto.userId.toUUID().bind()
            // TODO (matt): Implement hashing for sessionToken
            val sessionToken = loginSessionProto.sessionToken.toUUID().bind()
            val loginSessionMaybe = database.transactionToEffect {
                database
                    .from(LoginSessions)
                    .select(LoginSessions.sessionToken, LoginSessions.createdAt)
                    .where(
                        (LoginSessions.userId eq userId) and
                            (LoginSessions.deviceId eq loginSessionProto.deviceId) and
                            (
                                LoginSessions.createdAt greater (
                                    Instant.now()
                                        .minus(MAX_AGE_LOGIN_SESSION)
                                    )
                                )
                    )
                    .orderBy(LoginSessions.createdAt.desc())
                    .limit(1)
                    .map { LoginSessions.createEntity(it) }
                    .firstOrOption()
            }.bind()

            loginSessionMaybe
                .map { it.sessionToken == sessionToken }
                .getOrElse { shift(LoginSessionInvalidError()) }
        }

    suspend fun createLoginSession(request: LoginRequest): Effect<PulpFictionError, LoginSession> = effect {
        val loginSession = LoginSession.generateFromRequest(request).bind()
        database.transactionToEffect {
            database.loginSessions.add(loginSession)
        }.bind()
        loginSession
    }

    fun createPost(
        request: PulpFictionProtos.CreatePostRequest
    ): Effect<PulpFictionError, PostMetadata> = effect {
        val postId = PostId.generate()
        val post = Post.generateFromRequest(postId.postId, request).bind()
        database.transactionToEffect {
            database.postIds.add(postId)
            database.posts.add(post)
        }.bind()
        post.toPostMetadata()
    }

    fun createUser(
        request: PulpFictionProtos.CreateUserRequest
    ): Effect<PulpFictionError, PulpFictionProtos.User.UserMetadata> = effect {
        val user = User.generateFromRequest(request).bind()
        database.users.add(user)
        user.toNonSensitiveUserMetadataProto()
    }
}
