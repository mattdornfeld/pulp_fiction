package co.firstorderlabs.pulpfiction.backendserver.databasemodels

import arrow.core.Either
import arrow.core.continuations.Effect
import arrow.core.continuations.effect
import arrow.core.continuations.either
import arrow.core.getOrElse
import co.firstorderlabs.protos.pulpfiction.PostKt.postMetadata
import co.firstorderlabs.protos.pulpfiction.PostKt.postUpdateIdentifier
import co.firstorderlabs.protos.pulpfiction.PulpFictionProtos.CreatePostRequest
import co.firstorderlabs.protos.pulpfiction.PulpFictionProtos.Post.PostMetadata
import co.firstorderlabs.protos.pulpfiction.PulpFictionProtos.Post.PostState
import co.firstorderlabs.protos.pulpfiction.PulpFictionProtos.Post.PostUpdateIdentifier
import co.firstorderlabs.pulpfiction.backendserver.types.PostNotFoundError
import co.firstorderlabs.pulpfiction.backendserver.types.PulpFictionRequestError
import co.firstorderlabs.pulpfiction.backendserver.utils.firstOrOption
import co.firstorderlabs.pulpfiction.backendserver.utils.nowTruncated
import co.firstorderlabs.pulpfiction.backendserver.utils.toTimestamp
import org.ktorm.database.Database
import org.ktorm.dsl.desc
import org.ktorm.dsl.eq
import org.ktorm.dsl.from
import org.ktorm.dsl.joinReferencesAndSelect
import org.ktorm.dsl.limit
import org.ktorm.dsl.map
import org.ktorm.dsl.orderBy
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

    fun toProto(): PostMetadata = postMetadata {
        this.postUpdateIdentifier = getPostUpdateIdentifier()
        this.createdAt = this@PostUpdate.post.createdAt.toTimestamp()
        this.postState = this@PostUpdate.postState
        this.postType = this@PostUpdate.post.postType
        this.postCreatorId = this@PostUpdate.post.postCreatorId.toString()
    }

    fun withState(postState: PostState): PostUpdate =
        PostUpdate {
            this.post = this@PostUpdate.post
            this.updatedAt = nowTruncated()
            this.postState = postState
        }

    fun createPostReport(postReporterUserId: UUID, reportReason: String): PostReport =
        PostReport {
            this.post = this@PostUpdate.post
            this.updatedAt = this@PostUpdate.updatedAt
            this.reportedAt = nowTruncated()
            this.postReporterUserId = postReporterUserId
            this.reportReason = reportReason
        }

    companion object : Entity.Factory<PostUpdate>() {
        fun fromPost(post: Post): PostUpdate =
            PostUpdate {
                this.post = post
                this.updatedAt = nowTruncated()
                this.postState = PostState.CREATED
            }

        suspend fun fromRequest(
            postId: UUID,
            request: CreatePostRequest
        ): Either<PulpFictionRequestError, PostUpdate> = either {
            fromPost(Post.fromRequest(postId, request).bind())
        }

        fun getPostUpdateIdentifier(postId: UUID, updatedAt: Instant): PostUpdateIdentifier = postUpdateIdentifier {
            this.postId = postId.toString()
            this.updatedAt = updatedAt.toTimestamp()
        }
    }
}

val Database.postUpdates get() = this.sequenceOf(PostUpdates)

fun Database.addPostUpdate(postUpdate: PostUpdate): Effect<PulpFictionRequestError, Unit> =
    effect {
        useTransaction {
            this@addPostUpdate.addPost(postUpdate.post).bind()
            this@addPostUpdate.postUpdates.add(postUpdate)
        }
    }

fun Database.getLatestNotDeletedPostUpdate(postId: UUID): Effect<PulpFictionRequestError, PostUpdate> =
    this.getLatestPostUpdate(postId) { it.postState != PostState.DELETED }

fun Database.getLatestPostUpdate(
    postId: UUID,
    postQueryFilter: (PostUpdate) -> Boolean = { true }
): Effect<PulpFictionRequestError, PostUpdate> =
    effect {
        this@getLatestPostUpdate
            .from(PostUpdates)
            .joinReferencesAndSelect()
            .where(PostUpdates.postId eq postId)
            .orderBy(PostUpdates.updatedAt.desc())
            .limit(1)
            .map { PostUpdates.createEntity(it) }
            .filter(postQueryFilter)
            .firstOrOption()
            .getOrElse { shift(PostNotFoundError(postId)) }
    }
