package co.firstorderlabs.pulpfiction.backendserver.databasemodels

import arrow.core.Either
import arrow.core.continuations.Effect
import arrow.core.continuations.effect
import arrow.core.continuations.either
import co.firstorderlabs.protos.pulpfiction.PostKt.comment
import co.firstorderlabs.protos.pulpfiction.PostKt.loggedInUserPostInteractions
import co.firstorderlabs.protos.pulpfiction.PulpFictionProtos
import co.firstorderlabs.protos.pulpfiction.PulpFictionProtos.Post.LoggedInUserPostInteractions
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.types.PostData
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.types.PostDatum
import co.firstorderlabs.pulpfiction.backendserver.types.PulpFictionRequestError
import co.firstorderlabs.pulpfiction.backendserver.types.RequestParsingError
import co.firstorderlabs.pulpfiction.backendserver.utils.nowTruncated
import co.firstorderlabs.pulpfiction.backendserver.utils.toUUID
import org.ktorm.database.Database
import org.ktorm.entity.Entity
import org.ktorm.entity.add
import org.ktorm.entity.sequenceOf
import org.ktorm.schema.timestamp
import org.ktorm.schema.uuid
import org.ktorm.schema.varchar
import java.util.UUID

object CommentData : PostData<CommentDatum>("comment_data") {
    override val postId = uuid("post_id")
        .primaryKey()
        .references(Posts) { it.post }
    override val updatedAt = timestamp("updated_at").primaryKey().bindTo { it.updatedAt }
    val body = varchar("body").bindTo { it.body }
    val parentPostId = uuid("parent_post_id").bindTo { it.parentPostId }
}

interface CommentDatum : Entity<CommentDatum>, PostDatum {
    var body: String
    var parentPostId: UUID

    companion object : Entity.Factory<CommentDatum>() {
        suspend fun fromRequest(
            postUpdate: PostUpdate,
            request: PulpFictionProtos.CreatePostRequest.CreateCommentRequest
        ): Either<RequestParsingError, CommentDatum> =
            either {
                CommentDatum {
                    this.post = postUpdate.post
                    this.updatedAt = postUpdate.updatedAt
                    this.body = request.body
                    this.parentPostId = request.parentPostId.toUUID().bind()
                }
            }
    }

    fun toProto(loggedInUserPostInteractions: LoggedInUserPostInteractions): PulpFictionProtos.Post.Comment = comment {
        this.body = this@CommentDatum.body
        this.parentPostId = this@CommentDatum.parentPostId.toString()
        this.interactionAggregates = this@CommentDatum.post.postInteractionAggregate.toProto()
        this.loggedInUserPostInteractions = loggedInUserPostInteractions
    }

    fun toProto(): PulpFictionProtos.Post.Comment =
        toProto(loggedInUserPostInteractions { })

    fun addToDatabase(database: Database) {
        database.postUpdates.add(this.getPostUpdate())
        database.commentData.add(this)
    }

    fun withBody(newBody: String): CommentDatum =
        CommentDatum {
            this.post = this@CommentDatum.post
            this.updatedAt = nowTruncated()
            this.body = newBody
            this.parentPostId = this@CommentDatum.parentPostId
        }
}

val Database.commentData get() = this.sequenceOf(CommentData)

fun Database.addCommentDatum(commentDatum: CommentDatum): Effect<PulpFictionRequestError, Unit> =
    effect {
        useTransaction {
            this@addCommentDatum.addPostUpdate(commentDatum.getPostUpdate()).bind()
            this@addCommentDatum.commentData.add(commentDatum)
        }
    }
