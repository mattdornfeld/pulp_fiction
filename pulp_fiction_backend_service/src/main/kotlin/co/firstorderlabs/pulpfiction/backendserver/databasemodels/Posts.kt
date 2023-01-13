package co.firstorderlabs.pulpfiction.backendserver.databasemodels

import arrow.core.Either
import arrow.core.continuations.either
import co.firstorderlabs.protos.pulpfiction.CreateLoginSessionResponseKt.loginSession
import co.firstorderlabs.protos.pulpfiction.PulpFictionProtos
import co.firstorderlabs.pulpfiction.backendserver.types.PulpFictionRequestError
import co.firstorderlabs.pulpfiction.backendserver.types.RequestParsingError
import co.firstorderlabs.pulpfiction.backendserver.utils.nowTruncated
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
    val createdAt = timestamp("created_at").bindTo { it.createdAt }
    val postCreatorId = uuid("post_creator_id").bindTo { it.postCreatorId }
    val postType = enum<PulpFictionProtos.Post.PostType>("post_type").bindTo { it.postType }
}

interface Post : Entity<Post> {
    companion object : Entity.Factory<Post>() {
        private fun PulpFictionProtos.CreatePostRequest.getPostType(): Either<RequestParsingError, PulpFictionProtos.Post.PostType> {
            return if (this.hasCreateCommentRequest()) {
                Either.Right(PulpFictionProtos.Post.PostType.COMMENT)
            } else if (this.hasCreateImagePostRequest()) {
                Either.Right(PulpFictionProtos.Post.PostType.IMAGE)
            } else if (this.hasCreateUserPostRequest()) {
                Either.Right(PulpFictionProtos.Post.PostType.USER)
            } else {
                Either.Left(
                    RequestParsingError("${this.removeLoginSession()} contains unsupported PostType")
                )
            }
        }

        private fun PulpFictionProtos.CreatePostRequest.removeLoginSession(): PulpFictionProtos.CreatePostRequest =
            this
                .toBuilder()
                .setLoginSession(loginSession {})
                .build()

        suspend fun fromRequest(
            postId: UUID,
            request: PulpFictionProtos.CreatePostRequest
        ): Either<PulpFictionRequestError, Post> = either {
            val postCreatorId = request.loginSession.userId.toUUID().bind()
            Post {
                this.postId = postId
                this.createdAt = nowTruncated()
                this.postCreatorId = postCreatorId
                this.postType = request.getPostType().bind()
            }
        }
    }

    var postId: UUID
    var createdAt: Instant
    var postCreatorId: UUID
    var postType: PulpFictionProtos.Post.PostType
}

val Database.posts get() = this.sequenceOf(Posts)
