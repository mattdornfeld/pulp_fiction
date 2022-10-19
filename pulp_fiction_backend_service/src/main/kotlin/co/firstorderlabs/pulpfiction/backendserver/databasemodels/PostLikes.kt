package co.firstorderlabs.pulpfiction.backendserver.databasemodels

import co.firstorderlabs.protos.pulpfiction.PulpFictionProtos
import org.ktorm.database.Database
import org.ktorm.entity.Entity
import org.ktorm.entity.sequenceOf
import org.ktorm.schema.Table
import org.ktorm.schema.enum
import org.ktorm.schema.timestamp
import org.ktorm.schema.uuid
import java.time.Instant
import java.util.UUID

object PostLikes : Table<PostLike>("post_likes") {
    val postId = uuid("post_id").primaryKey().bindTo { it.postId }
    val postLikerUserId = uuid("post_liker_user_id").bindTo { it.postLikerUserId }
    val postLikeType = enum<PulpFictionProtos.Post.PostLike>("post_like_type").bindTo { it.postLikeType }
    val likedAt = timestamp("liked_at").bindTo { it.likedAt }
}

interface PostLike : Entity<PostLike> {
    companion object : Entity.Factory<PostLike>()
    var postId: UUID
    var postLikerUserId: UUID
    var postLikeType: PulpFictionProtos.Post.PostLike
    var likedAt: Instant
}

val Database.postLikes get() = this.sequenceOf(PostLikes)
