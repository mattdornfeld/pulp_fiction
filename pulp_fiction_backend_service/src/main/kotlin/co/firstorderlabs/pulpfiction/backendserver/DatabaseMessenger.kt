package co.firstorderlabs.pulpfiction.backendserver

import arrow.core.continuations.Effect
import arrow.core.continuations.effect
import arrow.core.getOrElse
import co.firstorderlabs.protos.pulpfiction.PulpFictionProtos
import co.firstorderlabs.protos.pulpfiction.PulpFictionProtos.CreatePostRequest.CreateCommentRequest
import co.firstorderlabs.protos.pulpfiction.PulpFictionProtos.CreatePostRequest.CreateImagePostRequest
import co.firstorderlabs.protos.pulpfiction.PulpFictionProtos.LoginRequest
import co.firstorderlabs.protos.pulpfiction.PulpFictionProtos.Post.PostMetadata
import co.firstorderlabs.pulpfiction.backendserver.S3Messenger.Companion.toS3Key
import co.firstorderlabs.pulpfiction.backendserver.configs.DatabaseConfigs
import co.firstorderlabs.pulpfiction.backendserver.configs.ServiceConfigs.MAX_AGE_LOGIN_SESSION
import co.firstorderlabs.pulpfiction.backendserver.database.models.CommentDatum
import co.firstorderlabs.pulpfiction.backendserver.database.models.ImagePostDatum
import co.firstorderlabs.pulpfiction.backendserver.database.models.LoginSession
import co.firstorderlabs.pulpfiction.backendserver.database.models.LoginSessions
import co.firstorderlabs.pulpfiction.backendserver.database.models.Post
import co.firstorderlabs.pulpfiction.backendserver.database.models.PostId
import co.firstorderlabs.pulpfiction.backendserver.database.models.User
import co.firstorderlabs.pulpfiction.backendserver.database.models.comment_data
import co.firstorderlabs.pulpfiction.backendserver.database.models.image_post_data
import co.firstorderlabs.pulpfiction.backendserver.database.models.loginSessions
import co.firstorderlabs.pulpfiction.backendserver.database.models.postIds
import co.firstorderlabs.pulpfiction.backendserver.database.models.posts
import co.firstorderlabs.pulpfiction.backendserver.database.models.users
import co.firstorderlabs.pulpfiction.backendserver.types.DatabaseError
import co.firstorderlabs.pulpfiction.backendserver.types.LoginSessionInvalidError
import co.firstorderlabs.pulpfiction.backendserver.types.PulpFictionError
import co.firstorderlabs.pulpfiction.backendserver.types.RequestParsingError
import co.firstorderlabs.pulpfiction.backendserver.utils.effectWithError
import co.firstorderlabs.pulpfiction.backendserver.utils.firstOrOption
import co.firstorderlabs.pulpfiction.backendserver.utils.toUUID
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
import org.ktorm.entity.find
import org.ktorm.support.postgresql.PostgreSqlDialect
import software.amazon.awssdk.services.s3.S3Client
import java.time.Instant
import java.util.*

data class DatabaseMessenger(val database: Database, val s3Client: S3Client) {

    private val s3Messenger = S3Messenger(s3Client)

    companion object {
        /**
         * Runs a database transaction as an effectful computation
         */
        private suspend fun <A> Database.transactionToEffect(
            func: suspend (org.ktorm.database.Transaction) -> A,
        ): Effect<PulpFictionError, A> = effectWithError({ DatabaseError(it) }) {
            this@transactionToEffect.useTransaction { func(it) }
        }

        fun createDatabaseConnection(): Database = Database.connect(
            url = DatabaseConfigs.URL,
            user = DatabaseConfigs.USER,
            password = DatabaseConfigs.PASSWORD,
            dialect = PostgreSqlDialect(),
        )
    }

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

    private suspend fun createImagePost(post: Post, request: CreateImagePostRequest): Effect<PulpFictionError, Unit> =
        effect {
            s3Messenger.uploadImageFromImagePost(post, request.imageJpg).bind()
            val imagePostDatum = ImagePostDatum {
                this.createdAt = post.createdAt
                this.postId = post.postId
                this.caption = request.caption
                this.imageS3Key = post.toS3Key()
            }
            database.image_post_data.add(imagePostDatum)
        }

    private suspend fun createComment(post: Post, request: CreateCommentRequest): Effect<PulpFictionError, Unit> =
        effect {
            val commentDatum = CommentDatum {
                this.createdAt = post.createdAt
                this.postId = post.postId
                this.body = request.body
                this.parentPostId = request.parentPostId.toUUID().bind()
            }
            database.comment_data.add(commentDatum)
        }

    private suspend fun createPostData(
        post: Post,
        request: PulpFictionProtos.CreatePostRequest
    ): Effect<PulpFictionError, Unit> = effect {
        when (post.postType) {
            PulpFictionProtos.Post.PostType.COMMENT -> createComment(post, request.createCommentRequest)
            PulpFictionProtos.Post.PostType.IMAGE -> createImagePost(post, request.createImagePostRequest)
            else -> RequestParsingError("CreatePost is not implemented for ${post.postType}")
        }
    }

    fun createPost(
        request: PulpFictionProtos.CreatePostRequest
    ): Effect<PulpFictionError, PostMetadata> = effect {
        val postId = PostId.generate()
        val post = Post.generateFromRequest(postId.postId, request).bind()
        database.transactionToEffect {
            database.postIds.add(postId)
            database.posts.add(post)
            createPostData(post, request).bind()
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

    fun getUserDuringLogin(
        request: LoginRequest
    ): Effect<PulpFictionError, User?> = effect {
        val uuid = UUID.fromString(request.userId)
        database.users.find { it.userId eq uuid }
    }
}
