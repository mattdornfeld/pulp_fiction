package co.firstorderlabs.pulpfiction.backendserver.databasemodels

import arrow.core.Either
import arrow.core.continuations.either
import co.firstorderlabs.protos.pulpfiction.LoginResponseKt.loginSession
import co.firstorderlabs.protos.pulpfiction.PostKt.postMetadata
import co.firstorderlabs.protos.pulpfiction.PulpFictionProtos.CreatePostRequest
import co.firstorderlabs.protos.pulpfiction.PulpFictionProtos.Post.PostMetadata
import co.firstorderlabs.protos.pulpfiction.PulpFictionProtos.Post.PostState
import co.firstorderlabs.protos.pulpfiction.PulpFictionProtos.Post.PostType
import co.firstorderlabs.pulpfiction.backendserver.types.PulpFictionRequestError
import co.firstorderlabs.pulpfiction.backendserver.types.RequestParsingError
import co.firstorderlabs.pulpfiction.backendserver.utils.nowTruncated
import co.firstorderlabs.pulpfiction.backendserver.utils.toTimestamp
import co.firstorderlabs.pulpfiction.backendserver.utils.toUUID
import org.ktorm.database.Database
import org.ktorm.entity.Entity
import org.ktorm.entity.sequenceOf
import org.ktorm.schema.Table
import org.ktorm.schema.enum
import org.ktorm.schema.timestamp
import org.ktorm.schema.uuid
import java.time.Instant
import java.util.UUID

object Posts : Table<Post>("posts") {
    val postId = uuid("post_id").primaryKey().bindTo { it.postId }
    val createdAt = timestamp("created_at").primaryKey().bindTo { it.createdAt }
    val postState = enum<PostState>("post_state").bindTo { it.postState }
    val postCreatorId = uuid("post_creator_id").bindTo { it.postCreatorId }
    val postType = enum<PostType>("post_type").bindTo { it.postType }
}

interface Post : Entity<Post> {
    var postId: UUID
    var createdAt: Instant
    var postState: PostState
    var postCreatorId: UUID
    var postType: PostType

    fun toProto(): PostMetadata = postMetadata {
        this.postId = this@Post.postId.toString()
        this.createdAt = this@Post.createdAt.toTimestamp()
        this.postState = this@Post.postState
        this.postType = this@Post.postType
        this.postCreatorId = this@Post.postCreatorId.toString()
    }

    fun toPostId(): PostId = PostId { this.postId = this@Post.postId }

    companion object : Entity.Factory<Post>() {
        private fun CreatePostRequest.getPostType(): Either<RequestParsingError, PostType> {
            return if (this.hasCreateCommentRequest()) {
                Either.Right(PostType.COMMENT)
            } else if (this.hasCreateImagePostRequest()) {
                Either.Right(PostType.IMAGE)
            } else if (this.hasCreateUserPostRequest()) {
                Either.Right(PostType.USER)
            } else {
                Either.Left(
                    RequestParsingError("${this.removeLoginSession()} contains unsupported PostType")
                )
            }
        }

        private fun CreatePostRequest.removeLoginSession(): CreatePostRequest =
            this
                .toBuilder()
                .setLoginSession(loginSession {})
                .build()

        suspend fun fromRequest(
            postId: UUID,
            request: CreatePostRequest
        ): Either<PulpFictionRequestError, Post> = either {
            val postCreatorId = request.loginSession.userId.toUUID().bind()
            Post {
                this.postId = postId
                this.createdAt = nowTruncated()
                this.postState = PostState.CREATED
                this.postCreatorId = postCreatorId
                this.postType = request.getPostType().bind()
            }
        }
    }
}

val Database.posts get() = this.sequenceOf(Posts)
