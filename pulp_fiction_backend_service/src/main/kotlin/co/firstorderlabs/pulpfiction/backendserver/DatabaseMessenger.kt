package co.firstorderlabs.pulpfiction.backendserver

import arrow.core.Either
import arrow.core.continuations.Effect
import arrow.core.continuations.effect
import arrow.core.getOrElse
import arrow.core.toOption
import co.firstorderlabs.protos.pulpfiction.CreatePostRequestKt
import co.firstorderlabs.protos.pulpfiction.PostKt.interactionAggregates
import co.firstorderlabs.protos.pulpfiction.PostKt.loggedInUserPostInteractions
import co.firstorderlabs.protos.pulpfiction.PulpFictionProtos
import co.firstorderlabs.protos.pulpfiction.PulpFictionProtos.CreateLoginSessionRequest
import co.firstorderlabs.protos.pulpfiction.PulpFictionProtos.CreatePostRequest
import co.firstorderlabs.protos.pulpfiction.PulpFictionProtos.CreatePostRequest.CreateCommentRequest
import co.firstorderlabs.protos.pulpfiction.PulpFictionProtos.CreatePostRequest.CreateImagePostRequest
import co.firstorderlabs.protos.pulpfiction.PulpFictionProtos.CreatePostRequest.CreateUserPostRequest
import co.firstorderlabs.protos.pulpfiction.PulpFictionProtos.GetFeedRequest
import co.firstorderlabs.protos.pulpfiction.PulpFictionProtos.GetPostRequest
import co.firstorderlabs.protos.pulpfiction.PulpFictionProtos.GetUserRequest
import co.firstorderlabs.protos.pulpfiction.PulpFictionProtos.UpdateUserRequest
import co.firstorderlabs.protos.pulpfiction.PulpFictionProtos.UpdateUserRequest.UpdateUserFollowingStatus
import co.firstorderlabs.protos.pulpfiction.PulpFictionProtos.UpdateUserResponse
import co.firstorderlabs.protos.pulpfiction.PulpFictionProtos.User.UserMetadata
import co.firstorderlabs.protos.pulpfiction.UpdateUserResponseKt
import co.firstorderlabs.protos.pulpfiction.UpdateUserResponseKt.updatePassword
import co.firstorderlabs.protos.pulpfiction.post
import co.firstorderlabs.protos.pulpfiction.updateUserResponse
import co.firstorderlabs.pulpfiction.backendserver.configs.DatabaseConfigs
import co.firstorderlabs.pulpfiction.backendserver.configs.ServiceConfigs.MAX_AGE_LOGIN_SESSION
import co.firstorderlabs.pulpfiction.backendserver.configs.ServiceConfigs.MAX_PAGE_SIZE
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.CommentData
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.CommentDatum
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.DatesOfBirth
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.DisplayNames
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.Email
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.Emails
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.Follower
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.Followers
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.ImagePostData
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.ImagePostDatum
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.LoginSession
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.LoginSessions
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.PhoneNumber
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.PhoneNumbers
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.PostInteractionAggregate
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.PostInteractionAggregates
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.PostLikes
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.PostUpdate
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.PostUpdates
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.Posts
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.User
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.UserPostData
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.UserPostDatum
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.Users
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.commentData
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.emails
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.followers
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.imagePostData
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.loginSessions
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.phoneNumbers
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
import co.firstorderlabs.pulpfiction.backendserver.types.EmailNotFoundError
import co.firstorderlabs.pulpfiction.backendserver.types.FeedNotImplementedError
import co.firstorderlabs.pulpfiction.backendserver.types.FunctionalityNotImplementedError
import co.firstorderlabs.pulpfiction.backendserver.types.InvalidUserPasswordError
import co.firstorderlabs.pulpfiction.backendserver.types.LoginSessionInvalidError
import co.firstorderlabs.pulpfiction.backendserver.types.PhoneNumberNotFoundError
import co.firstorderlabs.pulpfiction.backendserver.types.PostNotFoundError
import co.firstorderlabs.pulpfiction.backendserver.types.PulpFictionRequestError
import co.firstorderlabs.pulpfiction.backendserver.types.PulpFictionStartupError
import co.firstorderlabs.pulpfiction.backendserver.types.RequestParsingError
import co.firstorderlabs.pulpfiction.backendserver.types.UnrecognizedEnumValue
import co.firstorderlabs.pulpfiction.backendserver.types.UserNotFoundError
import co.firstorderlabs.pulpfiction.backendserver.utils.effectWithError
import co.firstorderlabs.pulpfiction.backendserver.utils.firstOrOption
import co.firstorderlabs.pulpfiction.backendserver.utils.getOrThrow
import co.firstorderlabs.pulpfiction.backendserver.utils.nowTruncated
import co.firstorderlabs.pulpfiction.backendserver.utils.toLocalDate
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
import org.ktorm.entity.firstOrNull
import org.ktorm.entity.removeIf
import org.ktorm.entity.sortedBy
import org.ktorm.support.postgresql.PostgreSqlDialect
import org.ktorm.support.postgresql.insertOrUpdate
import software.amazon.awssdk.services.s3.S3Client
import java.nio.file.Path
import java.util.UUID

class DatabaseMessenger(private val database: Database, s3Client: S3Client) {

    private val s3Messenger = S3Messenger(s3Client)

    companion object {
        private val logger: StructuredLogger = StructuredLogger()
        const val DATABASE_CREDENTIALS_USERNAME_KEY = "username"
        const val DATABASE_CREDENTIALS_PASSWORD_KEY = "password"

        suspend fun <A> effectWithDatabaseError(
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

    fun checkLoginSessionValid(loginSessionProto: PulpFictionProtos.CreateLoginSessionResponse.LoginSession): Effect<PulpFictionRequestError, Unit> =
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

    suspend fun createLoginSession(
        user: User,
        request: PulpFictionProtos.CreateLoginSessionRequest
    ): Effect<PulpFictionRequestError, PulpFictionProtos.CreateLoginSessionResponse.LoginSession> =
        effect {
            val loginSession = LoginSession.fromRequest(user, request)
            val userMetadata = database.transactionToEffectCatchErrors {
                database.loginSessions.add(loginSession)
                getPublicUserMetadata(loginSession.userId.toString()).bind()
            }.bind()
            loginSession.toProto(userMetadata)
        }

    private suspend fun createComment(
        postUpdate: PostUpdate,
        request: CreateCommentRequest,
    ): Effect<PulpFictionRequestError, CommentDatum> =
        effect {
            val commentDatum = CommentDatum.fromRequest(postUpdate, request).bind()
            database.postUpdates.add(postUpdate)
            database.commentData.add(commentDatum)
            commentDatum
        }

    private suspend fun createImagePost(
        postUpdate: PostUpdate,
        request: CreateImagePostRequest,
    ): Effect<PulpFictionRequestError, ImagePostDatum> =
        effect {
            val imagePostDatum = ImagePostDatum.fromRequest(postUpdate, request)

            s3Messenger
                .putAndTagObject(imagePostDatum, request.imageJpg)
                .logS3Metrics(EndpointMetrics.EndpointName.createPost, S3Metrics.S3Operation.uploadImagePost)
                .bind()

            database.postUpdates.add(postUpdate)
            database.imagePostData.add(imagePostDatum)
            imagePostDatum
        }

    private suspend fun createUserPostAndUploadAvatarJpg(
        postUpdate: PostUpdate,
        request: CreateUserPostRequest,
    ): Effect<PulpFictionRequestError, UserPostDatum> =
        effect {
            val userPostDatum = UserPostDatum.fromRequest(postUpdate, request)

            s3Messenger
                .putAndTagObject(userPostDatum, request.avatarJpg)
                .logS3Metrics(EndpointMetrics.EndpointName.createPost, S3Metrics.S3Operation.uploadUserAvatar)
                .bind()

            createUserPost(postUpdate, userPostDatum).bind()
        }

    private fun createUserPost(
        postUpdate: PostUpdate,
        userPostDatum: UserPostDatum,
    ): Effect<PulpFictionRequestError, UserPostDatum> =
        effect {
            database.postUpdates.add(postUpdate)
            database.userPostData.add(userPostDatum)
            userPostDatum
        }

    private suspend fun createPostData(
        postUpdate: PostUpdate,
        request: CreatePostRequest
    ): Effect<PulpFictionRequestError, PulpFictionProtos.Post> = effect {
        when (postUpdate.post.postType) {
            PulpFictionProtos.Post.PostType.COMMENT -> {
                val commentDatum = createComment(
                    postUpdate,
                    request.createCommentRequest
                ).bind()

                post {
                    this.metadata = postUpdate.toProto()
                    this.comment = commentDatum.toProto(
                        loggedInUserPostInteractions {},
                        interactionAggregates {}
                    )
                }
            }

            PulpFictionProtos.Post.PostType.IMAGE -> {
                val imagePostDatum = createImagePost(
                    postUpdate,
                    request.createImagePostRequest
                ).bind()

                post {
                    this.metadata = postUpdate.toProto()
                    this.imagePost = imagePostDatum.toProto(
                        loggedInUserPostInteractions {},
                        interactionAggregates {}
                    )
                }
            }
            PulpFictionProtos.Post.PostType.USER -> {
                val userPostDatum = createUserPostAndUploadAvatarJpg(
                    postUpdate,
                    request.createUserPostRequest
                ).bind()

                post {
                    this.metadata = postUpdate.toProto()
                    this.userPost = userPostDatum.toProto()
                }
            }
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
                database.postInteractionAggregates.add(PostInteractionAggregate.create(postUpdate.post.postId))
            }.bind()

            createPostData(postUpdate, request)
                .bind()
        }
            .logCreatePostDataMetrics(postUpdate.post.postType)
            .bind()
    }

    private suspend fun PulpFictionProtos.CreateUserRequest.addContactVerificationToDatabase(user: User): Effect<PulpFictionRequestError, Int> =
        effect {
            when (contactVerificationCase) {
                PulpFictionProtos.CreateUserRequest.ContactVerificationCase.PHONE_NUMBER_VERIFICATION -> {
                    val phoneNumber = PhoneNumber {
                        this.userId = user.userId
                        this.phoneNumber = phoneNumberVerification.phoneNumber
                    }
                    effectWithDatabaseError { database.phoneNumbers.add(phoneNumber) }.bind()
                }
                PulpFictionProtos.CreateUserRequest.ContactVerificationCase.EMAIL_VERIFICATION -> {
                    val email = Email {
                        this.userId = user.userId
                        this.email = emailVerification.email
                    }
                    effectWithDatabaseError { database.emails.add(email) }.bind()
                }
                else -> {
                    shift(UnrecognizedEnumValue(contactVerificationCase))
                }
            }
        }

    fun createUser(
        request: PulpFictionProtos.CreateUserRequest
    ): Effect<PulpFictionRequestError, User> = effect {
        val user = User.fromRequest(request).bind()

        database.transactionToEffect {
            effectWithDatabaseError { database.users.add(user) }.bind()
            request.addContactVerificationToDatabase(user).bind()
        }.bind()

        user
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

        val userId = request.loginSession.userId.toUUID().bind()
        post {
            this.metadata = postUpdate.toProto()

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

    private suspend fun updateUserMetadata(
        user: User,
        updateUserMetadata: UpdateUserRequest.UpdateUserMetadata
    ): Effect<PulpFictionRequestError, UpdateUserResponse> =
        effect {
            val userPostDatum = getMostRecentUserPostDatum(user.userId).bind()
            val newUserPostDatum = when (updateUserMetadata.updateUserMetadataCase) {
                UpdateUserRequest.UpdateUserMetadata.UpdateUserMetadataCase.UPDATE_USER_AVATAR -> {
                    val createUserPostRequest = CreatePostRequestKt.createUserPostRequest {
                        this.userId = user.userId.toString()
                        this.bio = userPostDatum.bio
                        this.displayName = userPostDatum.displayName
                        this.avatarJpg = updateUserMetadata.updateUserAvatar.avatarJpg
                    }

                    createUserPostAndUploadAvatarJpg(
                        PostUpdate.fromPost(userPostDatum.post),
                        createUserPostRequest
                    ).bind()
                }

                UpdateUserRequest.UpdateUserMetadata.UpdateUserMetadataCase.UPDATE_DISPLAY_NAME -> {
                    user.displayName.currentDisplayName = updateUserMetadata.updateDisplayName.newDisplayName

                    database.insertOrUpdate(DisplayNames) {
                        set(DisplayNames.userId, user.userId)
                        set(DisplayNames.currentDisplayName, user.displayName.currentDisplayName)
                        onConflict {
                            set(DisplayNames.currentDisplayName, user.displayName.currentDisplayName)
                        }
                    }

                    val postUpdate = PostUpdate.fromPost(userPostDatum.post)
                    val newUserPostDatum = UserPostDatum {
                        this.post = postUpdate.post
                        this.updatedAt = postUpdate.updatedAt
                        this.userId = user.userId
                        this.displayName = updateUserMetadata.updateDisplayName.newDisplayName
                        this.avatarImageS3Key = toS3Key()
                        this.bio = userPostDatum.bio
                    }

                    createUserPost(postUpdate, newUserPostDatum).bind()
                }
                UpdateUserRequest.UpdateUserMetadata.UpdateUserMetadataCase.UPDATE_BIO -> {
                    val postUpdate = PostUpdate.fromPost(userPostDatum.post)
                    val newUserPostDatum = UserPostDatum {
                        this.post = userPostDatum.post
                        this.updatedAt = postUpdate.updatedAt
                        this.userId = user.userId
                        this.displayName = userPostDatum.displayName
                        this.avatarImageS3Key = toS3Key()
                        this.bio = updateUserMetadata.updateBio.newBio
                    }

                    createUserPost(postUpdate, newUserPostDatum).bind()
                }
                else ->
                    shift(UnrecognizedEnumValue(updateUserMetadata.updateUserMetadataCase))
            }
            updateUserResponse {
                this.updateUserMetadata = UpdateUserResponseKt.updateUserMetadata {
                    this.userMetadata = user.toNonSensitiveUserMetadataProto(newUserPostDatum)
                }
            }
        }

    private suspend fun updateSensitiveUserMetadata(
        user: User,
        updateSensitiveUserMetadata: UpdateUserRequest.UpdateSensitiveUserMetadata
    ): Effect<PulpFictionRequestError, UpdateUserResponse> =
        effect {
            val userPostDatum = getMostRecentUserPostDatum(user.userId).bind()
            when (updateSensitiveUserMetadata.updateSensitiveUserMetadataCase) {
                UpdateUserRequest.UpdateSensitiveUserMetadata.UpdateSensitiveUserMetadataCase.UPDATE_EMAIL -> {
                    user.email.email = updateSensitiveUserMetadata.updateEmail.newEmail
                    database.insertOrUpdate(Emails) {
                        set(Emails.userId, user.userId)
                        set(Emails.email, user.email.email)
                        onConflict {
                            set(Emails.email, user.email.email)
                        }
                    }
                }
                UpdateUserRequest.UpdateSensitiveUserMetadata.UpdateSensitiveUserMetadataCase.UPDATE_PHONE_NUMBER -> {
                    user.phoneNumber.phoneNumber = updateSensitiveUserMetadata.updatePhoneNumber.newPhoneNumber
                    database.insertOrUpdate(PhoneNumbers) {
                        set(PhoneNumbers.userId, user.userId)
                        set(PhoneNumbers.phoneNumber, user.phoneNumber.phoneNumber)
                        onConflict {
                            set(PhoneNumbers.phoneNumber, user.phoneNumber.phoneNumber)
                        }
                    }
                }
                UpdateUserRequest.UpdateSensitiveUserMetadata.UpdateSensitiveUserMetadataCase.UPDATE_DATE_OF_BIRTH -> {
                    user.dateOfBirth.dateOfBirth =
                        updateSensitiveUserMetadata.updateDateOfBirth.newDateOfBirth.toLocalDate()
                    database.insertOrUpdate(DatesOfBirth) {
                        set(DatesOfBirth.userId, user.userId)
                        set(DatesOfBirth.dateOfBirth, user.dateOfBirth.dateOfBirth)
                        onConflict {
                            set(DatesOfBirth.dateOfBirth, user.dateOfBirth.dateOfBirth)
                        }
                    }
                }
                UpdateUserRequest.UpdateSensitiveUserMetadata.UpdateSensitiveUserMetadataCase.VERIFY_CONTACT_INFORMATION ->
                    shift(FunctionalityNotImplementedError())
                else -> shift(UnrecognizedEnumValue(updateSensitiveUserMetadata.updateSensitiveUserMetadataCase))
            }
            updateUserResponse {
                this.updateSensitiveUserMetadata = UpdateUserResponseKt.updateSensitiveUserMetadata {
                    this.sensitiveUserMetadata = user.toSensitiveUserMetadataProto(userPostDatum)
                }
            }
        }

    private suspend fun updateFollowingStatus(
        userId: UUID,
        updateUserFollowingStatus: UpdateUserFollowingStatus
    ):
        Effect<PulpFictionRequestError, UpdateUserResponse> =
            effect {
                val targetUserId = updateUserFollowingStatus.targetUserId.toUUID().bind()
                when (updateUserFollowingStatus.userFollowingStatus) {
                    UpdateUserFollowingStatus.UserFollowingStatus.NOT_FOLLOWING -> {
                        val follower = Follower {
                            this.userId = userId
                            this.followerId = targetUserId
                            this.createdAt = nowTruncated()
                        }
                        database.transactionToEffect {
                            effectWithDatabaseError { database.followers.add(follower) }.bind()
                        }.bind()
                    }
                    UpdateUserFollowingStatus.UserFollowingStatus.FOLLOWING -> {
                        database.transactionToEffect {
                            effectWithDatabaseError {
                                database.followers
                                    .removeIf { (it.userId eq userId) and (it.followerId eq targetUserId) }
                            }.bind()
                        }.bind()
                    }
                    else -> {
                        shift(
                            UnrecognizedEnumValue(
                                updateUserFollowingStatus.userFollowingStatus
                            )
                        )
                    }
                }
                updateUserResponse { }
            }

    suspend fun updateUser(request: UpdateUserRequest): Effect<PulpFictionRequestError, UpdateUserResponse> =
        effect {
            val userId = request.loginSession.userId
            val user = getUserFromUserId(userId).bind()

            when (request.updateUserRequestCase) {
                UpdateUserRequest.UpdateUserRequestCase.UPDATE_USER_METADATA ->
                    updateUserMetadata(user, request.updateUserMetadata).bind()
                UpdateUserRequest.UpdateUserRequestCase.UPDATE_SENSITIVE_USER_METADATA ->
                    updateSensitiveUserMetadata(user, request.updateSensitiveUserMetadata).bind()
                UpdateUserRequest.UpdateUserRequestCase.UPDATE_PASSWORD -> {
                    val authenticated = Password.check(
                        request.updatePassword.oldPassword,
                        user.hashedPassword
                    ).withBcrypt()
                    if (!authenticated) {
                        shift(InvalidUserPasswordError())
                    } else {
                        user.hashedPassword = Password.hash(request.updatePassword.newPassword).withBcrypt().result
                        user.flushChanges()
                    }
                    updateUserResponse {
                        this.updatePassword = updatePassword {}
                    }
                }
                UpdateUserRequest.UpdateUserRequestCase.UPDATE_USER_FOLLOWING_STATUS -> {
                    updateFollowingStatus(user.userId, request.updateUserFollowingStatus).bind()
                }
                UpdateUserRequest.UpdateUserRequestCase.RESET_PASSWORD -> {
                    shift(FunctionalityNotImplementedError())
                }
                else -> {
                    shift(UnrecognizedEnumValue(request.updateUserRequestCase))
                }
            }
        }

    private suspend fun getUserFromUserId(
        userId: String
    ): Effect<PulpFictionRequestError, User> = effect {
        val userUUID = userId.toUUID().bind()
        Users.select(database) { Users.userId eq userUUID }
            ?: shift(UserNotFoundError(userId))
    }

    suspend fun getPublicUserMetadata(
        request: GetUserRequest
    ): Effect<PulpFictionRequestError, UserMetadata> =
        getPublicUserMetadata(request.userId)

    private fun getMostRecentUserPostDatum(userId: UUID): Effect<PulpFictionRequestError, UserPostDatum> =
        effect {
            database.userPostData
                .filter { it.userId eq userId }
                .sortedBy { it.updatedAt.desc() }
                .firstOrNull()
                ?: shift(PostNotFoundError())
        }

    private suspend fun getPublicUserMetadata(
        userId: String
    ): Effect<PulpFictionRequestError, UserMetadata> = effect {
        val user = getUserFromUserId(userId).bind()
        when (val userPostDatumEither = getMostRecentUserPostDatum(user.userId).toEither()) {
            is Either.Left -> user.toNonSensitiveUserMetadataProto()
            is Either.Right -> user.toNonSensitiveUserMetadataProto(userPostDatumEither.value)
        }
    }

    suspend fun getFeed(
        request: GetFeedRequest,
        count: Int
    ): Effect<PulpFictionRequestError, List<PulpFictionProtos.Post>> = effect {

        val paginatedPosts = getPostsQuery(request)
            .bind()
            .orderBy(Posts.createdAt.desc())
            .limit(offset = count * MAX_PAGE_SIZE, limit = MAX_PAGE_SIZE)
        paginatedPosts.map { row ->
            val postId = row[Posts.postId] ?: shift(PostNotFoundError())
            val postUpdate = getPostUpdate(postId).bind()
            val loggedInUser = request.loginSession.userId.toUUID().bind()

            when (row[Posts.postType]) {
                PulpFictionProtos.Post.PostType.IMAGE -> {
                    buildImagePostFeed(
                        postId = postId,
                        loggedInUserId = loggedInUser,
                        postUpdate = postUpdate
                    ).bind()
                }
                PulpFictionProtos.Post.PostType.USER -> {
                    buildUserPostFeed(
                        postId = postId,
                        postUpdate = postUpdate
                    ).bind()
                }
                PulpFictionProtos.Post.PostType.COMMENT -> {
                    buildCommentPostFeed(
                        postId = postId,
                        loggedInUserId = loggedInUser,
                        postUpdate = postUpdate
                    ).bind()
                }
                else -> {
                    shift(FeedNotImplementedError(row[Posts.postType].toString()))
                }
            }
        }
    }

    private fun getPostsQuery(
        request: GetFeedRequest,
    ): Effect<PulpFictionRequestError, Query> = effect {
        val postsTable = database
            .from(Posts)
        val columns = listOf(Posts.postId, Posts.postCreatorId, Posts.postType)
        when (request.getFeedRequestCase) {
            GetFeedRequest.GetFeedRequestCase.GET_GLOBAL_POST_FEED_REQUEST -> {
                postsTable
                    .select(columns)
                    .where { Posts.postType eq PulpFictionProtos.Post.PostType.IMAGE }
            }
            GetFeedRequest.GetFeedRequestCase.GET_USER_POST_FEED_REQUEST -> {
                val userId = request.getUserPostFeedRequest.userId.toUUID().bind()
                postsTable
                    .select(columns)
                    .where {
                        (Posts.postCreatorId eq userId) and
                            (Posts.postType eq PulpFictionProtos.Post.PostType.IMAGE)
                    }
            }
            GetFeedRequest.GetFeedRequestCase.GET_FOLLOWING_POST_FEED_REQUEST -> {
                val userId = request.getFollowingPostFeedRequest.userId.toUUID().bind()
                database
                    .from(Followers)
                    .rightJoin(Posts, on = Followers.userId eq Posts.postCreatorId)
                    .select(columns)
                    .where {
                        (Followers.followerId eq userId) and
                            (Posts.postType eq PulpFictionProtos.Post.PostType.IMAGE)
                    }
            }
            GetFeedRequest.GetFeedRequestCase.GET_COMMENT_FEED_REQUEST -> {
                val postId = request.getCommentFeedRequest.postId.toUUID().bind()
                postsTable
                    .rightJoin(CommentData, on = CommentData.postId eq Posts.postId)
                    .select(columns)
                    .where {
                        CommentData.parentPostId eq postId
                    }
            }
            GetFeedRequest.GetFeedRequestCase.GET_FOLLOWERS_FEED_REQUEST -> {
                val userId = request.getFollowersFeedRequest.userId.toUUID().bind()
                database
                    .from(Followers)
                    .select(columns)
                    .where {
                        (Followers.userId eq userId) and
                            (Posts.postType eq PulpFictionProtos.Post.PostType.USER)
                    }
            }
            GetFeedRequest.GetFeedRequestCase.GET_FOLLOWING_FEED_REQUEST -> {
                val userId = request.getFollowingFeedRequest.userId.toUUID().bind()
                database
                    .from(Followers)
                    .select(columns)
                    .where {
                        (Followers.followerId eq userId) and
                            (Posts.postType eq PulpFictionProtos.Post.PostType.USER)
                    }
            }
            else -> {
                shift(RequestParsingError("Feed request received without valid instruction."))
            }
        }
    }

    fun checkPasswordValidAndGetUser(
        request: CreateLoginSessionRequest
    ): Effect<PulpFictionRequestError, User> = effect {
        val userLoginCandidate = when (request.createLoginSessionRequestCase) {
            CreateLoginSessionRequest.CreateLoginSessionRequestCase.EMAIL_LOGIN -> {
                Users.select(database) { Emails.email eq request.emailLogin.email }
                    ?: shift(EmailNotFoundError())
            }
            CreateLoginSessionRequest.CreateLoginSessionRequestCase.PHONE_NUMBER_LOGIN -> {
                Users.select(database) { PhoneNumbers.phoneNumber eq request.phoneNumberLogin.phoneNumber }
                    ?: shift(PhoneNumberNotFoundError())
            }
            else -> shift(UnrecognizedEnumValue(request.createLoginSessionRequestCase))
        }

        val hashedPass = userLoginCandidate.hashedPassword
        val authenticated = Password.check(request.password, hashedPass).withBcrypt()
        if (!authenticated) {
            shift(InvalidUserPasswordError())
        } else {
            userLoginCandidate
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

    private suspend fun buildImagePostFeed(
        postId: UUID,
        loggedInUserId: UUID,
        postUpdate: PostUpdate
    ):
        Effect<PulpFictionRequestError, PulpFictionProtos.Post> = effect {
            val loggedInUserPostInteractions = getLoggedInUserPostInteractions(postId, loggedInUserId).bind()
            val postInteractionAggregates = getPostInteractionAggregates(postId).bind()
            post {
                this.metadata = postUpdate.toProto()
                this.imagePost = getPostData(postId, ImagePostData).bind()
                    .toProto(
                        loggedInUserPostInteractions,
                        postInteractionAggregates
                    )
            }
        }

    private suspend fun buildCommentPostFeed(
        postId: UUID,
        loggedInUserId: UUID,
        postUpdate: PostUpdate
    ):
        Effect<PulpFictionRequestError, PulpFictionProtos.Post> = effect {
            val loggedInUserPostInteractions = getLoggedInUserPostInteractions(postId, loggedInUserId).bind()
            val postInteractionAggregates = getPostInteractionAggregates(postId).bind()
            post {
                this.metadata = postUpdate.toProto()
                this.comment = getPostData(postId, CommentData).bind()
                    .toProto(
                        loggedInUserPostInteractions,
                        postInteractionAggregates
                    )
            }
        }

    private suspend fun buildUserPostFeed(
        postId: UUID,
        postUpdate: PostUpdate
    ):
        Effect<PulpFictionRequestError, PulpFictionProtos.Post> = effect {

            post {
                this.metadata = postUpdate.toProto()
                this.userPost = getPostData(postId, UserPostData).bind().toProto()
            }
        }
}
