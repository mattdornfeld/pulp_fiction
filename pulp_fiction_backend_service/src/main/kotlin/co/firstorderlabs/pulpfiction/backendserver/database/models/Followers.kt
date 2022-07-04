package co.firstorderlabs.pulpfiction.backendserver.database.models

import org.ktorm.database.Database
import org.ktorm.entity.Entity
import org.ktorm.entity.sequenceOf
import org.ktorm.schema.Table
import org.ktorm.schema.long
import org.ktorm.schema.timestamp
import org.ktorm.schema.uuid
import java.time.Instant
import java.util.UUID

object Followers : Table<Follower>("followers") {
    val id = long("id").primaryKey().bindTo { it.id }
    val userId = uuid("user_id").bindTo { it.userId }
    val followerId = uuid("follower_id").bindTo { it.followerId }
    val createdAt = timestamp("created_at").bindTo { it.createdAt }
}

interface Follower : Entity<Follower> {
    companion object : Entity.Factory<Follower>()
    val id: Long
    var userId: UUID
    var followerId: UUID
    var createdAt: Instant
}

val Database.followers get() = this.sequenceOf(Followers)
