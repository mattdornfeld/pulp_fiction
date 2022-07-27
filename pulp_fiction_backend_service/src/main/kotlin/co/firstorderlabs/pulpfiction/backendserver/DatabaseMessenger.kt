package co.firstorderlabs.pulpfiction.backendserver

import arrow.core.continuations.Effect
import arrow.core.continuations.effect
import arrow.core.getOrElse
import co.firstorderlabs.protos.pulpfiction.PulpFictionProtos
import co.firstorderlabs.protos.pulpfiction.PulpFictionProtos.CreatePostRequest
import co.firstorderlabs.protos.pulpfiction.PulpFictionProtos.CreatePostRequest.CreateCommentRequest
import co.firstorderlabs.protos.pulpfiction.PulpFictionProtos.CreatePostRequest.CreateImagePostRequest
import co.firstorderlabs.protos.pulpfiction.PulpFictionProtos.CreatePostRequest.CreateUserPostRequest
import co.firstorderlabs.protos.pulpfiction.PulpFictionProtos.GetPostRequest
import co.firstorderlabs.protos.pulpfiction.PulpFictionProtos.LoginRequest
import co.firstorderlabs.protos.pulpfiction.post
import co.firstorderlabs.pulpfiction.backendserver.configs.DatabaseConfigs
import co.firstorderlabs.pulpfiction.backendserver.configs.ServiceConfigs.MAX_AGE_LOGIN_SESSION
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.CommentData
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.CommentDatum
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.ImagePostData
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.ImagePostDatum
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.LoginSession
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.LoginSessions
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.Post
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.PostId
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.Posts
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.User
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.UserPostData
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.UserPostDatum
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.commentData
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.imagePostData
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.loginSessions
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.postIds
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.posts
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.types.PostData
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.types.PostDatum
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.userPostData
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.users
import co.firstorderlabs.pulpfiction.backendserver.monitoring.metrics.metricsstore.CreatePostDataMetrics.logCreatePostDataMetrics
import co.firstorderlabs.pulpfiction.backendserver.monitoring.metrics.metricsstore.EndpointMetrics
import co.firstorderlabs.pulpfiction.backendserver.monitoring.metrics.metricsstore.S3Metrics
import co.firstorderlabs.pulpfiction.backendserver.monitoring.metrics.metricsstore.S3Metrics.logS3Metrics
import co.firstorderlabs.pulpfiction.backendserver.types.*
import co.firstorderlabs.pulpfiction.backendserver.utils.effectWithError
import co.firstorderlabs.pulpfiction.backendserver.utils.firstOrOption
import co.firstorderlabs.pulpfiction.backendserver.utils.toUUID
import com.password4j.Password
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
import org.ktorm.entity.Entity
import org.ktorm.entity.add
import org.ktorm.entity.find
import org.ktorm.support.postgresql.PostgreSqlDialect
import software.amazon.awssdk.services.s3.S3Client
import java.time.Instant
import java.util.UUID

class DatabaseMessenger(private val database: Database, s3Client: S3Client) {

    private val s3Messenger = S3Messenger(s3Client)

    companion object {
        private suspend fun <A> effectWithDatabaseError(
            block: suspend arrow.core.continuations.EffectScope<PulpFictionError>.() -> A
        ): Effect<PulpFictionError, A> = effectWithError({ DatabaseError(it) }) { block(this) }

        /**
         * Runs a database transaction as an effectful computation,
         * catching any errors and transforming them to DatabaseError
         */
        private suspend fun <A> Database.transactionToEffectCatchErrors(
            block: suspend (org.ktorm.database.Transaction) -> A,
        ): Effect<PulpFictionError, A> = effectWithDatabaseError {
            this@transactionToEffectCatchErrors.useTransaction { block(it) }
        }

        /**
         * Runs a database transaction as an effectful computation
         */
        private suspend fun <A> Database.transactionToEffect(
            block: suspend (org.ktorm.database.Transaction) -> A,
        ): Effect<PulpFictionError, A> = effect {
            this@transactionToEffect.useTransaction { block(it) }
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
            val loginSessionMaybe = database.transactionToEffectCatchErrors {
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
        val loginSession = LoginSession.fromRequest(request).bind()
        database.transactionToEffectCatchErrors {
            database.loginSessions.add(loginSession)
        }.bind()
        loginSession
    }

    private suspend fun createComment(
        post: Post,
        request: CreateCommentRequest
    ): Effect<PulpFictionError, PulpFictionProtos.Post> =
        effect {
            val commentDatum = CommentDatum.fromRequest(post, request).bind()
            database.commentData.add(commentDatum)
            post {
                this.metadata = post.toProto()
                this.comment = commentDatum.toProto()
            }
        }

    private suspend fun createImagePost(
        post: Post,
        request: CreateImagePostRequest
    ): Effect<PulpFictionError, PulpFictionProtos.Post> =
        effect {
            val imagePostDatum = ImagePostDatum.fromRequest(post, request)

            s3Messenger
                .putAndTagObject(imagePostDatum, request.imageJpg)
                .logS3Metrics(EndpointMetrics.EndpointName.createPost, S3Metrics.S3Operation.uploadImagePost)
                .bind()

            database.imagePostData.add(imagePostDatum)
            post {
                this.metadata = post.toProto()
                this.imagePost = imagePostDatum.toProto()
            }
        }

    private suspend fun createUserPost(
        post: Post,
        request: CreateUserPostRequest
    ): Effect<PulpFictionError, PulpFictionProtos.Post> =
        effect {
            val userPostDatum = UserPostDatum.fromRequest(post, request)

            s3Messenger
                .putAndTagObject(userPostDatum, request.avatarJpg)
                .logS3Metrics(EndpointMetrics.EndpointName.createPost, S3Metrics.S3Operation.uploadUserAvatar)
                .bind()

            database.userPostData.add(userPostDatum)
            post {
                this.metadata = post.toProto()
                this.userPost = userPostDatum.toProto()
            }
        }

    private suspend fun createPostData(
        post: Post,
        request: CreatePostRequest
    ): Effect<PulpFictionError, PulpFictionProtos.Post> = effect {
        when (post.postType) {
            PulpFictionProtos.Post.PostType.COMMENT -> createComment(post, request.createCommentRequest).bind()
            PulpFictionProtos.Post.PostType.IMAGE -> createImagePost(post, request.createImagePostRequest).bind()
            PulpFictionProtos.Post.PostType.USER -> createUserPost(post, request.createUserPostRequest).bind()
            else -> shift(RequestParsingError("CreatePost is not implemented for ${post.postType}"))
        }
    }

    fun createPost(
        request: CreatePostRequest
    ): Effect<PulpFictionError, PulpFictionProtos.Post> = effect {
        val postId = PostId.generate()
        val post = Post.fromRequest(postId.postId, request).bind()

        database.transactionToEffect {
            effectWithDatabaseError {
                database.postIds.add(postId)
                database.posts.add(post)
            }.bind()

            createPostData(post, request)
                .bind()
        }
            .logCreatePostDataMetrics(post.postType)
            .bind()
    }

    fun createUser(
        request: PulpFictionProtos.CreateUserRequest
    ): Effect<PulpFictionError, PulpFictionProtos.Post> = effect {
        val user = User.fromRequest(request).bind()

        database.transactionToEffect {
            effectWithDatabaseError { database.users.add(user) }.bind()
            createPost(user.toCreatePostRequest(request.avatarJpg)).bind()
        }.bind()
    }

    private suspend fun <A> getPostData(
        postId: UUID,
        table: PostData<A>
    ): Effect<PulpFictionError, A> where A : PostDatum, A : Entity<A> = database.transactionToEffectCatchErrors {
        database
            .from(table)
            .select()
            .where(table.postId eq postId)
            .orderBy(table.createdAt.desc())
            .limit(1)
            .map { table.createEntity(it) }
            .first()
    }

    suspend fun getPost(
        request: GetPostRequest
    ): Effect<PulpFictionError, PulpFictionProtos.Post> = effect {
        val postId = request.postId.toUUID().bind()
        val post = database.transactionToEffectCatchErrors {
            database.from(Posts)
                .select()
                .where(Posts.postId eq postId)
                .orderBy(Posts.createdAt.desc())
                .limit(1)
                .map { Posts.createEntity(it) }
                .first()
        }.bind()

        post {
            this.metadata = post.toProto()

            when (post.postType) {
                PulpFictionProtos.Post.PostType.COMMENT -> {
                    this.comment = getPostData(postId, CommentData)
                        .bind()
                        .toProto()
                }
                PulpFictionProtos.Post.PostType.IMAGE -> {
                    this.imagePost = getPostData(postId, ImagePostData)
                        .bind()
                        .toProto()
                }
                PulpFictionProtos.Post.PostType.USER -> {
                    this.userPost = getPostData(postId, UserPostData)
                        .bind()
                        .toProto()
                }
                else -> {
                    shift(RequestParsingError("GetPost is not implemented for PostType ${post.postType}"))
                }
            }
        }
    }

    fun checkUserPasswordValid(
        request: LoginRequest
    ): Effect<PulpFictionError, Boolean> = effect {
        val uuid = request.userId.toUUID().bind()
        val userLoginCandidate = database.users.find { it.userId eq uuid } ?:
            shift(UserNotFoundError("User ${request.userId} not found"))

        val hashedPass = userLoginCandidate.hashedPassword
        val authenticated = Password.check(request.password, hashedPass).withBcrypt()
        if (!authenticated) { shift(InvalidUserPasswordError()) } else { true }
    }
}
