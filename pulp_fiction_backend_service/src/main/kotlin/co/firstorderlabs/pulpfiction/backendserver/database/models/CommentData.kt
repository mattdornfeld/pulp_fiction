package co.firstorderlabs.pulpfiction.backendserver.database.models

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

interface CommentDatum : Entity<CommentDatum> {
    companion object : Entity.Factory<CommentDatum>()
    var postId: UUID
    var createdAt: Instant
    var body: String
    var parentPostId: UUID
    var parentCreatedAt: Instant
}

val Database.comment_data get() = this.sequenceOf(CommentData)
