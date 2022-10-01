package co.firstorderlabs.pulpfiction.backendserver.databasemodels

import arrow.core.Either
import arrow.core.continuations.either
import co.firstorderlabs.protos.pulpfiction.PostKt.postMetadata
import co.firstorderlabs.protos.pulpfiction.PostKt.postUpdateIdentifier
import co.firstorderlabs.protos.pulpfiction.PulpFictionProtos.CreatePostRequest
import co.firstorderlabs.protos.pulpfiction.PulpFictionProtos.Post.PostMetadata
import co.firstorderlabs.protos.pulpfiction.PulpFictionProtos.Post.PostState
import co.firstorderlabs.protos.pulpfiction.PulpFictionProtos.Post.PostUpdateIdentifier
import co.firstorderlabs.protos.pulpfiction.PulpFictionProtos.User.UserMetadata
import co.firstorderlabs.pulpfiction.backendserver.types.PulpFictionRequestError
import co.firstorderlabs.pulpfiction.backendserver.utils.nowTruncated
import co.firstorderlabs.pulpfiction.backendserver.utils.toTimestamp
import org.ktorm.database.Database
import org.ktorm.entity.Entity
import org.ktorm.entity.sequenceOf
import org.ktorm.schema.Table
import org.ktorm.schema.enum
import org.ktorm.schema.timestamp
import org.ktorm.schema.uuid
import java.time.Instant
import java.util.UUID

object PostUpdates : Table<PostUpdate>("post_updates") {
    val postId = uuid("post_id").primaryKey().references(Posts) { it.post }
    val updatedAt = timestamp("updated_at").primaryKey().bindTo { it.updatedAt }
    val postState = enum<PostState>("post_state").bindTo { it.postState }
}

interface PostUpdate : Entity<PostUpdate> {
    var post: Post
    var updatedAt: Instant
    var postState: PostState

    fun getPostUpdateIdentifier(): PostUpdateIdentifier =
        Companion.getPostUpdateIdentifier(this@PostUpdate.post.postId, this@PostUpdate.updatedAt)

    fun toProto(postCreatorMetadata: UserMetadata): PostMetadata = postMetadata {
        this.postUpdateIdentifier = getPostUpdateIdentifier()
        this.createdAt = this@PostUpdate.post.createdAt.toTimestamp()
        this.postState = this@PostUpdate.postState
        this.postType = this@PostUpdate.post.postType
        this.postCreatorId = this@PostUpdate.post.postCreatorId.toString()
    }

    companion object : Entity.Factory<PostUpdate>() {
        suspend fun fromRequest(
            postId: UUID,
            request: CreatePostRequest
        ): Either<PulpFictionRequestError, PostUpdate> = either {
            PostUpdate {
                this.post = Post.fromRequest(postId, request).bind()
                this.updatedAt = nowTruncated()
                this.postState = PostState.CREATED
            }
        }

        fun getPostUpdateIdentifier(postId: UUID, updatedAt: Instant): PostUpdateIdentifier = postUpdateIdentifier {
            this.postId = postId.toString()
            this.updatedAt = updatedAt.toTimestamp()
        }
    }
}

val Database.postUpdates get() = this.sequenceOf(PostUpdates)
