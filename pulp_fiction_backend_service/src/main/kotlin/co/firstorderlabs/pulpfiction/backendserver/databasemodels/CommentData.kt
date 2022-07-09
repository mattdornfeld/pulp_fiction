package co.firstorderlabs.pulpfiction.backendserver.databasemodels

import arrow.core.Either
import arrow.core.continuations.either
import co.firstorderlabs.protos.pulpfiction.PulpFictionProtos
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.types.PostDatum
import co.firstorderlabs.pulpfiction.backendserver.types.RequestParsingError
import co.firstorderlabs.pulpfiction.backendserver.utils.toUUID
import org.ktorm.database.Database
import org.ktorm.entity.Entity
import org.ktorm.entity.sequenceOf
import org.ktorm.schema.Table
import org.ktorm.schema.timestamp
import org.ktorm.schema.uuid
import org.ktorm.schema.varchar
import java.time.Instant
import java.util.UUID

object CommentData : Table<CommentDatum>("comment_data") {
    val postId = uuid("post_id").primaryKey().bindTo { it.postId }
    val createdAt = timestamp("created_at").primaryKey().bindTo { it.createdAt }
    val body = varchar("body").bindTo { it.body }
    val parentPostId = uuid("parent_post_id").bindTo { it.parentPostId }
}

interface CommentDatum : Entity<CommentDatum>, PostDatum {
    companion object : Entity.Factory<CommentDatum>() {
        suspend fun createFromRequest(post: Post, request: PulpFictionProtos.CreatePostRequest.CreateCommentRequest): Either<RequestParsingError, CommentDatum> =
            either {
                CommentDatum {
                    this.postId = post.postId
                    this.body = request.body
                    this.parentPostId = request.parentPostId.toUUID().bind()
                }
            }
    }

    var postId: UUID
    var createdAt: Instant
    var body: String
    var parentPostId: UUID
}

val Database.commentData get() = this.sequenceOf(CommentData)
