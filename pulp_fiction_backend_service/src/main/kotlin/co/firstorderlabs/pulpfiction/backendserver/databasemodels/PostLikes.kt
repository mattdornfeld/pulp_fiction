package co.firstorderlabs.pulpfiction.backendserver.databasemodels

import arrow.core.Option
import arrow.core.continuations.Effect
import arrow.core.continuations.effect
import co.firstorderlabs.protos.pulpfiction.PulpFictionProtos
import co.firstorderlabs.pulpfiction.backendserver.types.PulpFictionRequestError
import co.firstorderlabs.pulpfiction.backendserver.utils.firstOrOption
import co.firstorderlabs.pulpfiction.backendserver.utils.nowTruncated
import org.ktorm.database.Database
import org.ktorm.dsl.and
import org.ktorm.dsl.eq
import org.ktorm.dsl.from
import org.ktorm.dsl.joinReferencesAndSelect
import org.ktorm.dsl.map
import org.ktorm.dsl.where
import org.ktorm.entity.Entity
import org.ktorm.entity.add
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

    fun updatePostLikeStatus(newPostLikeType: co.firstorderlabs.protos.pulpfiction.PulpFictionProtos.Post.PostLike) {
        postLikeType = newPostLikeType
        likedAt = nowTruncated()
    }
}

val Database.postLikes get() = this.sequenceOf(PostLikes)

fun Database.getPostLikeMaybe(
    postId: UUID,
    postLikerUserId: UUID
): Effect<PulpFictionRequestError, Option<PostLike>> =
    effect {
        this@getPostLikeMaybe.from(PostLikes)
            .joinReferencesAndSelect()
            .where { (PostLikes.postId eq postId) and (PostLikes.postLikerUserId eq postLikerUserId) }
            .map { PostLikes.createEntity(it) }
            .firstOrOption()
    }

fun Database.addPostLike(
    postId: UUID,
    userId: UUID,
    postLikeType: co.firstorderlabs.protos.pulpfiction.PulpFictionProtos.Post.PostLike
): Effect<PulpFictionRequestError, Unit> =
    effect {
        val postLike = PostLike {
            this.postId = postId
            this.postLikerUserId = userId
            this.likedAt = nowTruncated()
            this.postLikeType = postLikeType
        }

        this@addPostLike.postLikes.add(postLike)
    }
