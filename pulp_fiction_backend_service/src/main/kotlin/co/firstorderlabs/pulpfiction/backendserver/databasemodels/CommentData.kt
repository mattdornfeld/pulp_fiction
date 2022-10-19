package co.firstorderlabs.pulpfiction.backendserver.databasemodels

import arrow.core.Either
import arrow.core.continuations.either
import co.firstorderlabs.protos.pulpfiction.PostKt.comment
import co.firstorderlabs.protos.pulpfiction.PulpFictionProtos
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.types.PostData
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.types.PostDatum
import co.firstorderlabs.pulpfiction.backendserver.types.RequestParsingError
import co.firstorderlabs.pulpfiction.backendserver.utils.toUUID
import org.ktorm.database.Database
import org.ktorm.entity.Entity
import org.ktorm.entity.sequenceOf
import org.ktorm.schema.timestamp
import org.ktorm.schema.uuid
import org.ktorm.schema.varchar
import java.time.Instant
import java.util.UUID

object CommentData : PostData<CommentDatum>("comment_data") {
    override val postId = uuid("post_id").primaryKey().bindTo { it.postId }
    override val updatedAt = timestamp("updated_at").primaryKey().bindTo { it.updatedAt }
    val body = varchar("body").bindTo { it.body }
    val parentPostId = uuid("parent_post_id").bindTo { it.parentPostId }
}

interface CommentDatum : Entity<CommentDatum>, PostDatum {
    companion object : Entity.Factory<CommentDatum>() {
        suspend fun fromRequest(
            postUpdate: PostUpdate,
            request: PulpFictionProtos.CreatePostRequest.CreateCommentRequest
        ): Either<RequestParsingError, CommentDatum> =
            either {
                CommentDatum {
                    this.postId = postUpdate.post.postId
                    this.updatedAt = postUpdate.updatedAt
                    this.body = request.body
                    this.parentPostId = request.parentPostId.toUUID().bind()
                }
            }
    }

    fun toProto(
        loggedInUserPostInteractions: PulpFictionProtos.Post.LoggedInUserPostInteractions,
        postInteractionAggregates: PulpFictionProtos.Post.InteractionAggregates
    ): PulpFictionProtos.Post.Comment = comment {
        this.body = this@CommentDatum.body
        this.parentPostId = this@CommentDatum.parentPostId.toString()
        this.interactionAggregates = postInteractionAggregates
        this.loggedInUserPostInteractions = loggedInUserPostInteractions
    }

    override var postId: UUID
    override var updatedAt: Instant
    var body: String
    var parentPostId: UUID
}

val Database.commentData get() = this.sequenceOf(CommentData)
