package co.firstorderlabs.pulpfiction.backendserver

import arrow.core.continuations.Effect
import arrow.core.continuations.effect
import arrow.core.getOrElse
import arrow.core.toOption
import co.firstorderlabs.protos.pulpfiction.PostKt.interactionAggregates
import co.firstorderlabs.protos.pulpfiction.PostKt.loggedInUserPostInteractions
import co.firstorderlabs.protos.pulpfiction.PulpFictionProtos
import co.firstorderlabs.protos.pulpfiction.PulpFictionProtos.CreatePostRequest
import co.firstorderlabs.protos.pulpfiction.PulpFictionProtos.CreatePostRequest.CreateCommentRequest
import co.firstorderlabs.protos.pulpfiction.PulpFictionProtos.CreatePostRequest.CreateImagePostRequest
import co.firstorderlabs.protos.pulpfiction.PulpFictionProtos.CreatePostRequest.CreateUserPostRequest
import co.firstorderlabs.protos.pulpfiction.PulpFictionProtos.GetFeedRequest
import co.firstorderlabs.protos.pulpfiction.PulpFictionProtos.GetPostRequest
import co.firstorderlabs.protos.pulpfiction.PulpFictionProtos.GetUserRequest
import co.firstorderlabs.protos.pulpfiction.PulpFictionProtos.LoginRequest
import co.firstorderlabs.protos.pulpfiction.PulpFictionProtos.UpdateUserRequest
import co.firstorderlabs.protos.pulpfiction.PulpFictionProtos.User.SensitiveUserMetadata
import co.firstorderlabs.protos.pulpfiction.PulpFictionProtos.User.UserMetadata
import co.firstorderlabs.protos.pulpfiction.post
import co.firstorderlabs.pulpfiction.backendserver.configs.DatabaseConfigs
import co.firstorderlabs.pulpfiction.backendserver.configs.ServiceConfigs.MAX_AGE_LOGIN_SESSION
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.CommentData
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.CommentDatum
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.Followers
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.ImagePostData
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.ImagePostDatum
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.LoginSession
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.LoginSessions
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.PostInteractionAggregate
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.PostInteractionAggregates
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.PostLikes
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.PostUpdate
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.PostUpdates
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.Posts
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.User
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.User.Companion.getDateOfBirth
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.UserPostData
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.UserPostDatum
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.commentData
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.imagePostData
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.loginSessions
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.postInteractionAggregates
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.postUpdates
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.posts
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.types.PostData
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.types.PostDatum
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.userPostData
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.users
import co.firstorderlabs.pulpfiction.backendserver.monitoring.metrics.metricsstore.CreatePostDataMetrics.logCreatePostDataMetrics
import co.firstorderlabs.pulpfiction.backendserver.monitoring.metrics.metricsstore.EndpointMetrics
import co.firstorderlabs.pulpfiction.backendserver.monitoring.metrics.metricsstore.S3Metrics
import co.firstorderlabs.pulpfiction.backendserver.monitoring.metrics.metricsstore.S3Metrics.logS3Metrics
import co.firstorderlabs.pulpfiction.backendserver.types.DatabaseConnectionError
import co.firstorderlabs.pulpfiction.backendserver.types.DatabaseError
import co.firstorderlabs.pulpfiction.backendserver.types.DatabaseUrl
import co.firstorderlabs.pulpfiction.backendserver.types.FunctionalityNotImplementedError
import co.firstorderlabs.pulpfiction.backendserver.types.InvalidUserPasswordError
import co.firstorderlabs.pulpfiction.backendserver.types.LoginSessionInvalidError
import co.firstorderlabs.pulpfiction.backendserver.types.PostNotFoundError
import co.firstorderlabs.pulpfiction.backendserver.types.PulpFictionRequestError
import co.firstorderlabs.pulpfiction.backendserver.types.PulpFictionStartupError
import co.firstorderlabs.pulpfiction.backendserver.types.RequestParsingError
import co.firstorderlabs.pulpfiction.backendserver.types.UserNotFoundError
import co.firstorderlabs.pulpfiction.backendserver.utils.effectWithError
import co.firstorderlabs.pulpfiction.backendserver.utils.firstOrOption
import co.firstorderlabs.pulpfiction.backendserver.utils.getOrThrow
import co.firstorderlabs.pulpfiction.backendserver.utils.nowTruncated
import co.firstorderlabs.pulpfiction.backendserver.utils.toUUID
import com.password4j.Password
import org.ktorm.database.Database
import org.ktorm.dsl.Query
import org.ktorm.dsl.and
import org.ktorm.dsl.desc
import org.ktorm.dsl.eq
import org.ktorm.dsl.from
import org.ktorm.dsl.greater
import org.ktorm.dsl.joinReferencesAndSelect
import org.ktorm.dsl.limit
import org.ktorm.dsl.map
import org.ktorm.dsl.orderBy
import org.ktorm.dsl.rightJoin
import org.ktorm.dsl.select
import org.ktorm.dsl.where
import org.ktorm.entity.Entity
import org.ktorm.entity.add
import org.ktorm.entity.filter
import org.ktorm.entity.find
import org.ktorm.entity.first
import org.ktorm.entity.sortedBy
import org.ktorm.support.postgresql.PostgreSqlDialect
import software.amazon.awssdk.services.s3.S3Client
import java.nio.file.Path
import java.util.UUID

class DatabaseMessenger(private val database: Database, s3Client: S3Client) {

    private val s3Messenger = S3Messenger(s3Client)

    companion object {
        private val logger: StructuredLogger = StructuredLogger()
        const val DATABASE_CREDENTIALS_USERNAME_KEY = "username"
        const val DATABASE_CREDENTIALS_PASSWORD_KEY = "password"
        private suspend fun <A> effectWithDatabaseError(
            block: suspend arrow.core.continuations.EffectScope<PulpFictionRequestError>.() -> A
        ): Effect<PulpFictionRequestError, A> = effectWithError({ DatabaseError(it) }) { block(this) }

        /**
         * Runs a database transaction as an effectful computation,
         * catching any errors and transforming them to DatabaseError
         */
        private suspend fun <A> Database.transactionToEffectCatchErrors(
            block: suspend (org.ktorm.database.Transaction) -> A,
        ): Effect<PulpFictionRequestError, A> = effectWithDatabaseError {
            this@transactionToEffectCatchErrors.useTransaction { block(it) }
        }

        private suspend fun Database.Companion.connectAndHandleErrors(
            databaseUrl: DatabaseUrl,
            databaseCredentials: Map<String, String>,
        ): Effect<PulpFictionStartupError, Database> = effect {
            try {
                logger.withTag(databaseUrl).info("Connecting to database")

                connect(
                    url = databaseUrl.databaseUrl,
                    user = databaseCredentials.getOrThrow(DATABASE_CREDENTIALS_USERNAME_KEY),
                    password = databaseCredentials.getOrThrow(DATABASE_CREDENTIALS_PASSWORD_KEY),
                    dialect = PostgreSqlDialect(),
                )
            } catch (cause: Throwable) {
                shift(DatabaseConnectionError(cause))
            }
        }

        /**
         * Runs a database transaction as an effectful computation
         */
        private suspend fun <A> Database.transactionToEffect(
            block: suspend (org.ktorm.database.Transaction) -> A,
        ): Effect<PulpFictionRequestError, A> = effect {
            this@transactionToEffect.useTransaction { block(it) }
        }

        fun createDatabaseConnection(
            databaseUrl: DatabaseUrl,
            databaseCredentials: Map<String, String>
        ): Effect<PulpFictionStartupError, Database> = effect {
            Database
                .connectAndHandleErrors(databaseUrl, databaseCredentials)
                .bind()
        }

        fun createDatabaseConnection(
            databaseUrl: DatabaseUrl,
            encryptedCredentialsFile: Path
        ): Effect<PulpFictionStartupError, Database> = effect {
            val databaseCredentials = SecretsDecrypter()
                .decryptJsonCredentialsFileWithKmsKey(DatabaseConfigs.KMS_KEY_ID, encryptedCredentialsFile)
                .bind()

            createDatabaseConnection(databaseUrl, databaseCredentials).bind()
        }

        fun createDatabaseConnection(): Effect<PulpFictionStartupError, Database> =
            createDatabaseConnection(DatabaseConfigs.databaseUrl, DatabaseConfigs.ENCRYPTED_CREDENTIALS_FILE)
    }

    fun checkLoginSessionValid(loginSessionProto: PulpFictionProtos.LoginResponse.LoginSession): Effect<PulpFictionRequestError, Unit> =
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
                                    nowTruncated()
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

    suspend fun createLoginSession(request: LoginRequest): Effect<PulpFictionRequestError, PulpFictionProtos.LoginResponse.LoginSession> =
        effect {
            val loginSession = LoginSession.fromRequest(request).bind()
            val userMetadata = database.transactionToEffectCatchErrors {
                database.loginSessions.add(loginSession)
                getPublicUserMetadata(loginSession.userId.toString()).bind()
            }.bind()
            loginSession.toProto(userMetadata)
        }

    private suspend fun createComment(
        postUpdate: PostUpdate,
        request: CreateCommentRequest,
        postCreatorMetadata: UserMetadata
    ): Effect<PulpFictionRequestError, PulpFictionProtos.Post> =
        effect {
            val commentDatum = CommentDatum.fromRequest(postUpdate, request).bind()
            database.commentData.add(commentDatum)
            post {
                this.metadata = postUpdate.toProto(postCreatorMetadata)
                this.comment = commentDatum.toProto(
                    loggedInUserPostInteractions {},
                    interactionAggregates {}
                )
            }
        }

    private suspend fun createImagePost(
        postUpdate: PostUpdate,
        request: CreateImagePostRequest,
        postCreatorMetadata: UserMetadata
    ): Effect<PulpFictionRequestError, PulpFictionProtos.Post> =
        effect {
            val imagePostDatum = ImagePostDatum.fromRequest(postUpdate, request)

            s3Messenger
                .putAndTagObject(imagePostDatum, request.imageJpg)
                .logS3Metrics(EndpointMetrics.EndpointName.createPost, S3Metrics.S3Operation.uploadImagePost)
                .bind()

            database.imagePostData.add(imagePostDatum)
            post {
                this.metadata = postUpdate.toProto(postCreatorMetadata)
                this.imagePost = imagePostDatum.toProto(
                    loggedInUserPostInteractions {},
                    interactionAggregates {}
                )
            }
        }

    private suspend fun createUserPost(
        postUpdate: PostUpdate,
        request: CreateUserPostRequest,
        postCreatorMetadata: UserMetadata
    ): Effect<PulpFictionRequestError, PulpFictionProtos.Post> =
        effect {
            val userPostDatum = UserPostDatum.fromRequest(postUpdate, request)

            s3Messenger
                .putAndTagObject(userPostDatum, request.avatarJpg)
                .logS3Metrics(EndpointMetrics.EndpointName.createPost, S3Metrics.S3Operation.uploadUserAvatar)
                .bind()

            database.userPostData.add(userPostDatum)
            post {
                this.metadata = postUpdate.toProto(postCreatorMetadata)
                this.userPost = userPostDatum.toProto()
            }
        }

    private suspend fun createPostData(
        postUpdate: PostUpdate,
        request: CreatePostRequest
    ): Effect<PulpFictionRequestError, PulpFictionProtos.Post> = effect {
        when (postUpdate.post.postType) {
            PulpFictionProtos.Post.PostType.COMMENT -> createComment(
                postUpdate,
                request.createCommentRequest,
                request.loginSession.userMetadata
            ).bind()
            PulpFictionProtos.Post.PostType.IMAGE -> createImagePost(
                postUpdate,
                request.createImagePostRequest,
                request.loginSession.userMetadata
            ).bind()
            PulpFictionProtos.Post.PostType.USER -> createUserPost(
                postUpdate,
                request.createUserPostRequest,
                request.loginSession.userMetadata
            ).bind()
            else -> shift(RequestParsingError("CreatePost is not implemented for ${postUpdate.post.postType}"))
        }
    }

    fun createPost(
        request: CreatePostRequest
    ): Effect<PulpFictionRequestError, PulpFictionProtos.Post> = effect {
        val postUpdate = PostUpdate.fromRequest(UUID.randomUUID(), request).bind()

        database.transactionToEffect {
            effectWithDatabaseError {
                database.posts.add(postUpdate.post)
                database.postUpdates.add(postUpdate)
                database.postInteractionAggregates.add(PostInteractionAggregate.create(postUpdate.post.postId))
            }.bind()

            createPostData(postUpdate, request)
                .bind()
        }
            .logCreatePostDataMetrics(postUpdate.post.postType)
            .bind()
    }

    fun createUser(
        request: PulpFictionProtos.CreateUserRequest
    ): Effect<PulpFictionRequestError, PulpFictionProtos.Post> = effect {
        val user = User.fromRequest(request).bind()

        database.transactionToEffect {
            effectWithDatabaseError { database.users.add(user) }.bind()
            createPost(user.toCreatePostRequest(request)).bind()
        }.bind()
    }

    private suspend fun <A> getPostData(
        postId: UUID,
        table: PostData<A>
    ): Effect<PulpFictionRequestError, A> where A : PostDatum, A : Entity<A> = effect {
        database
            .from(table)
            .select()
            .where(table.postId eq postId)
            .orderBy(table.updatedAt.desc())
            .limit(1)
            .map { table.createEntity(it) }
            .firstOrOption()
            .getOrElse { shift(PostNotFoundError()) }
    }

    private suspend fun getPostInteractionAggregates(postId: UUID): Effect<PulpFictionRequestError, PulpFictionProtos.Post.InteractionAggregates> =
        effect {
            database.postInteractionAggregates.find { PostInteractionAggregates.postId eq postId }
                .toOption()
                .map { it.toProto() }
                .getOrElse { shift(PostNotFoundError()) }
        }

    private fun getLoggedInUserPostInteractions(
        postId: UUID,
        userId: UUID
    ): Effect<PulpFictionRequestError, PulpFictionProtos.Post.LoggedInUserPostInteractions> = effect {
        val postLike = database.from(PostLikes)
            .select(PostLikes.postLikeType)
            .where { (PostLikes.postId eq postId) and (PostLikes.postLikerUserId eq userId) }
            .map { PostLikes.createEntity(it) }
            .firstOrOption()
            .map { it.postLikeType }
            .getOrElse { PulpFictionProtos.Post.PostLike.NEUTRAL }

        loggedInUserPostInteractions {
            this.postLike = postLike
        }
    }

    suspend fun getPost(
        request: GetPostRequest
    ): Effect<PulpFictionRequestError, PulpFictionProtos.Post> = effect {
        val postId = request.postId.toUUID().bind()
        val postUpdate = getPostUpdate(postId).bind()
        val userMetadata = getPublicUserMetadata(postUpdate.post.postCreatorId.toString()).bind()

        val userId = request.loginSession.userId.toUUID().bind()
        post {
            this.metadata = postUpdate.toProto(userMetadata)

            when (postUpdate.post.postType) {
                PulpFictionProtos.Post.PostType.COMMENT -> {
                    val loggedInUserPostInteractions = getLoggedInUserPostInteractions(postId, userId).bind()
                    val postInteractionAggregates = getPostInteractionAggregates(postId).bind()
                    this.comment = getPostData(postId, CommentData)
                        .bind()
                        .toProto(loggedInUserPostInteractions, postInteractionAggregates)
                }
                PulpFictionProtos.Post.PostType.IMAGE -> {
                    val loggedInUserPostInteractions = getLoggedInUserPostInteractions(postId, userId).bind()
                    val postInteractionAggregates = getPostInteractionAggregates(postId).bind()
                    this.imagePost = getPostData(postId, ImagePostData)
                        .bind()
                        .toProto(loggedInUserPostInteractions, postInteractionAggregates)
                }
                PulpFictionProtos.Post.PostType.USER -> {
                    this.userPost = getPostData(postId, UserPostData)
                        .bind()
                        .toProto()
                }
                else -> {
                    shift(RequestParsingError("GetPost is not implemented for PostType ${postUpdate.post.postType}"))
                }
            }
        }
    }

    suspend fun updateUser(request: UpdateUserRequest): Effect<PulpFictionRequestError, SensitiveUserMetadata> =
        effect {
            val userId = request.loginSession.userId
            val user = getUserFromUserId(userId).bind()

            when {
                request.hasUpdateUserInfo() -> {
                    user.currentDisplayName = request.updateUserInfo.newDisplayName
                    user.dateOfBirth = getDateOfBirth(request.updateUserInfo.newDateOfBirth).bind().orNull()
                }
                request.hasUpdateEmail() -> {
                    user.email = request.updateEmail.newEmail
                }
                request.hasUpdatePassword() -> {
                    val authenticated = Password.check(
                        request.updatePassword.oldPassword,
                        user.hashedPassword
                    ).withBcrypt()
                    if (!authenticated) {
                        shift(InvalidUserPasswordError())
                    } else {
                        user.hashedPassword = Password.hash(request.updatePassword.newPassword).withBcrypt().result
                    }
                }
                request.hasUpdatePhoneNumber() -> {
                    user.phoneNumber = request.updatePhoneNumber.newPhoneNumber
                }
                request.hasResetPassword() -> {
                    shift(FunctionalityNotImplementedError())
                }
                else -> {
                    shift(RequestParsingError("UpdateUserRequest received without instructions."))
                }
            }
            user.flushChanges()
            val userPostDatum = getMostRecentUserPostDatum(user.userId).bind()
            user.toSensitiveUserMetadataProto(userPostDatum)
        }

    private suspend fun getUserFromUserId(
        userId: String
    ): Effect<PulpFictionRequestError, User> = effect {
        val uuid = userId.toUUID().bind()
        database.users.find { it.userId eq uuid }
            ?: shift(UserNotFoundError(userId))
    }

    suspend fun getPublicUserMetadata(
        request: GetUserRequest
    ): Effect<PulpFictionRequestError, UserMetadata> =
        getPublicUserMetadata(request.userId)

    private suspend fun getMostRecentUserPostDatum(userId: UUID): Effect<PulpFictionRequestError, UserPostDatum> =
        effect {
            database.userPostData
                .filter { it.userId eq userId }
                .sortedBy { it.updatedAt.desc() }
                .first()
        }

    suspend fun getPublicUserMetadata(
        userId: String
    ): Effect<PulpFictionRequestError, UserMetadata> = effect {
        val user = getUserFromUserId(userId).bind()
        val userPostDatum = getMostRecentUserPostDatum(user.userId).bind()
        user.toNonSensitiveUserMetadataProto(userPostDatum)
    }

    suspend fun getFeed(
        request: GetFeedRequest
    ): Effect<PulpFictionRequestError, List<PulpFictionProtos.Post>> = effect {
        val userId = request.loginSession.userId.toUUID().bind()

        val unsortedPostQuery = getPostsQuery(request, userId)
        val sortedPostsQuery = unsortedPostQuery
            .bind()
            .where { Posts.postType eq PulpFictionProtos.Post.PostType.IMAGE }
            .orderBy(Posts.createdAt.desc())

        val pagination = 2000
        val paginatedPosts = sortedPostsQuery.limit(offset = 0, limit = pagination)
        paginatedPosts.map { row ->
            val postId = row[Posts.postId] ?: shift(PostNotFoundError())
            val postUpdate = getPostUpdate(postId).bind()
            val postCreatorId = row[Posts.postCreatorId] ?: shift(UserNotFoundError("Null"))
            val loggedInUserPostInteractions = getLoggedInUserPostInteractions(postId, userId).bind()
            val postInteractionAggregates = getPostInteractionAggregates(postId).bind()
            post {
                this.metadata = postUpdate.toProto(getPublicUserMetadata(postCreatorId.toString()).bind())
                this.imagePost = getPostData(postId, ImagePostData).bind()
                    .toProto(
                        loggedInUserPostInteractions,
                        postInteractionAggregates
                    )
            }
        }
    }

    private fun getPostsQuery(
        request: GetFeedRequest,
        userId: UUID
    ): Effect<PulpFictionRequestError, Query> = effect {
        val postsTable = database
            .from(Posts)
        val columns = listOf(Posts.postId, Posts.postCreatorId)
        when {
            request.hasGetGlobalPostFeedRequest() -> {
                postsTable
                    .select(columns)
            }
            request.hasGetUserPostFeedRequest() -> {
                postsTable
                    .select(columns)
                    .where { Posts.postCreatorId eq userId }
            }
            request.hasGetFollowingPostFeedRequest() -> {
                database
                    .from(Followers)
                    .rightJoin(Posts, on = Followers.userId eq Posts.postCreatorId)
                    .select(columns)
                    .where { Followers.followerId eq userId }
            }
            else -> { shift(RequestParsingError("Feed request received without valid instruction.")) }
        }
    }

    fun checkUserPasswordValid(
        request: LoginRequest
    ): Effect<PulpFictionRequestError, Boolean> = effect {
        val userLoginCandidate = getUserFromUserId(request.userId).bind()
        val hashedPass = userLoginCandidate.hashedPassword
        val authenticated = Password.check(request.password, hashedPass).withBcrypt()
        if (!authenticated) {
            shift(InvalidUserPasswordError())
        } else {
            true
        }
    }

    private suspend fun getPostUpdate(postId: UUID): Effect<PulpFictionRequestError, PostUpdate> = effect {
        database.from(PostUpdates)
            .joinReferencesAndSelect()
            .where(PostUpdates.postId eq postId)
            .orderBy(PostUpdates.updatedAt.desc())
            .limit(1)
            .map { PostUpdates.createEntity(it) }
            .firstOrOption()
            .getOrElse { shift(PostNotFoundError()) }
    }
}
