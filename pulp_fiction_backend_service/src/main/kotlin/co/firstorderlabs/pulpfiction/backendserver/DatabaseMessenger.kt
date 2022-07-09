package co.firstorderlabs.pulpfiction.backendserver

import arrow.core.continuations.Effect
import arrow.core.continuations.effect
import arrow.core.getOrElse
import co.firstorderlabs.protos.pulpfiction.PulpFictionProtos
import co.firstorderlabs.protos.pulpfiction.PulpFictionProtos.CreatePostRequest.CreateCommentRequest
import co.firstorderlabs.protos.pulpfiction.PulpFictionProtos.CreatePostRequest.CreateImagePostRequest
import co.firstorderlabs.protos.pulpfiction.PulpFictionProtos.CreatePostRequest.CreateUserPostRequest
import co.firstorderlabs.protos.pulpfiction.PulpFictionProtos.LoginRequest
import co.firstorderlabs.protos.pulpfiction.PulpFictionProtos.Post.PostMetadata
import co.firstorderlabs.pulpfiction.backendserver.configs.DatabaseConfigs
import co.firstorderlabs.pulpfiction.backendserver.configs.ServiceConfigs.MAX_AGE_LOGIN_SESSION
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.CommentDatum
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.ImagePostDatum
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.LoginSession
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.LoginSessions
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.Post
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.PostId
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.User
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.UserPostDatum
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.commentData
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.imagePostData
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.loginSessions
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.postIds
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.posts
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.userPostData
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.users
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
import org.ktorm.support.postgresql.PostgreSqlDialect
import software.amazon.awssdk.services.s3.S3Client
import java.time.Instant

class DatabaseMessenger(private val database: Database, s3Client: S3Client) {

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

    private suspend fun createComment(post: Post, request: CreateCommentRequest): Effect<PulpFictionError, Unit> =
        effect {
            val commentDatum = CommentDatum.createFromRequest(post, request).bind()
            database.commentData.add(commentDatum)
        }

    private suspend fun createImagePost(post: Post, request: CreateImagePostRequest): Effect<PulpFictionError, Unit> =
        effect {
            val imagePostDatum = ImagePostDatum.createFromRequest(post, request)
            s3Messenger.putAndTagObject(imagePostDatum, request.imageJpg).bind()
            database.imagePostData.add(imagePostDatum)
        }

    private suspend fun createUserPost(post: Post, request: CreateUserPostRequest): Effect<PulpFictionError, Unit> = effect {
        val userPostDatum = UserPostDatum.createFromRequest(post, request)
        s3Messenger.putAndTagObject(userPostDatum, request.avatarJpg).bind()
        database.userPostData.add(userPostDatum)
    }

    private suspend fun createPostData(
        post: Post,
        request: PulpFictionProtos.CreatePostRequest
    ): Effect<PulpFictionError, Unit> = effect {
        when (post.postType) {
            PulpFictionProtos.Post.PostType.COMMENT -> createComment(post, request.createCommentRequest)
            PulpFictionProtos.Post.PostType.IMAGE -> createImagePost(post, request.createImagePostRequest)
            PulpFictionProtos.Post.PostType.USER -> createUserPost(post, request.createUserPostRequest)
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
}
