package co.firstorderlabs.pulpfiction.backendserver.database.models

import co.firstorderlabs.protos.pulpfiction.PulpFictionProtos.Post.PostState
import co.firstorderlabs.protos.pulpfiction.PulpFictionProtos.Post.PostType
import me.liuwj.ktorm.database.Database
import me.liuwj.ktorm.entity.Entity
import me.liuwj.ktorm.entity.sequenceOf
import me.liuwj.ktorm.schema.Table
import me.liuwj.ktorm.schema.int
import me.liuwj.ktorm.schema.long
import me.liuwj.ktorm.schema.timestamp
import me.liuwj.ktorm.schema.uuid
import me.liuwj.ktorm.support.postgresql.pgEnum
import java.time.Instant
import java.util.UUID

interface Post : Entity<Post> {
    companion object : Entity.Factory<Post>()

    val id: Long
    var post_id: UUID
    var post_state: PostState
    var created_at: Instant
    var post_creator_id: UUID
    var post_type: PostType
    var post_version: Int
}

object Posts : Table<Post>("posts") {
    val id = long("id").primaryKey().bindTo { it.id }
    val post_id = uuid("post_id").bindTo { it.post_id }
    val post_state = pgEnum<PostState>("post_state").bindTo { it.post_state }
    val created_at = timestamp("created_at").bindTo { it.created_at }
    val post_creator_id = uuid("post_creator_id").bindTo { it.post_creator_id }
    val post_type = pgEnum<PostType>("post_type").bindTo { it.post_type }
    val post_version = int("post_version").bindTo { it.post_version }
}

val Database.posts get() = this.sequenceOf(Posts)
