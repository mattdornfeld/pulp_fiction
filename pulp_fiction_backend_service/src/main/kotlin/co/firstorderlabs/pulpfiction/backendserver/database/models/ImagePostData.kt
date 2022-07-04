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

object ImagePostData : Table<ImagePostDatum>("image_post_data") {
    val postId = uuid("post_id").bindTo { it.postId }
    val createdAt = timestamp("created_at").primaryKey().bindTo { it.createdAt }
    val imageUrl = varchar("image_url").bindTo { it.imageUrl }
    val caption = varchar("caption").bindTo { it.caption }
}

interface ImagePostDatum : Entity<ImagePostDatum> {
    companion object : Entity.Factory<ImagePostDatum>()
    var postId: UUID
    var createdAt: Instant
    var imageUrl: String
    var caption: String
}

val Database.image_post_data get() = this.sequenceOf(ImagePostData)
