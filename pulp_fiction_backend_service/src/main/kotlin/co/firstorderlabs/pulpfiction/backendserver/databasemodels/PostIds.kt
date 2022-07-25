package co.firstorderlabs.pulpfiction.backendserver.databasemodels

import co.firstorderlabs.pulpfiction.backendserver.databasemodels.Posts.bindTo
import org.ktorm.database.Database
import org.ktorm.entity.Entity
import org.ktorm.entity.sequenceOf
import org.ktorm.schema.Table
import org.ktorm.schema.uuid
import java.util.UUID

object PostIds : Table<PostId>("post_ids") {
    val postId = uuid("post_id").primaryKey().bindTo { it.postId }
}

interface PostId : Entity<PostId> {
    companion object : Entity.Factory<PostId>() {
        fun generate(): PostId = PostId {
            postId = UUID.randomUUID()
        }
    }

    var postId: UUID
}

val Database.postIds get() = this.sequenceOf(PostIds)
