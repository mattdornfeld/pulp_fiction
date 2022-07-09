package co.firstorderlabs.pulpfiction.backendserver.databasemodels

import co.firstorderlabs.protos.pulpfiction.PulpFictionProtos
import co.firstorderlabs.protos.pulpfiction.PulpFictionProtos.CreatePostRequest.CreateUserPostRequest
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.types.PostDatum
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.types.ReferencesS3Key
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.types.ReferencesS3Key.Companion.JPG
import org.ktorm.database.Database
import org.ktorm.entity.Entity
import org.ktorm.entity.sequenceOf
import org.ktorm.schema.Table
import org.ktorm.schema.timestamp
import org.ktorm.schema.uuid
import org.ktorm.schema.varchar
import software.amazon.awssdk.services.s3.model.Tagging
import java.time.Instant
import java.util.UUID

object UserPostData : Table<UserPostDatum>("user_post_data") {
    val postId = uuid("post_id").primaryKey().bindTo { it.postId }
    val createdAt = timestamp("created_at").primaryKey().bindTo { it.createdAt }
    val userId = uuid("user_id").bindTo { it.userId }
    val displayName = varchar("display_name").bindTo { it.displayName }
    val avatarImageS3Key = varchar("avatar_image_s3_key").bindTo { it.avatarImageS3Key }
}

interface UserPostDatum : Entity<UserPostDatum>, PostDatum, ReferencesS3Key {
    companion object : Entity.Factory<UserPostDatum>() {
        const val USER_AVATARS_KEY_BASE = "user_avatars"

        enum class TagKey {
            createdAt,
            postId,
            postType,
            fileType,
            userId,
        }

        fun createFromRequest(post: Post, request: CreateUserPostRequest) = UserPostDatum {
            this.postId = post.postId
            this.createdAt = post.createdAt
            this.userId = post.postCreatorId
            this.displayName = request.displayName
            this.avatarImageS3Key = toS3Key()
        }
    }

    var postId: UUID
    var createdAt: Instant
    var userId: UUID
    var displayName: String
    var avatarImageS3Key: String?

    override fun toS3Key(): String = "$USER_AVATARS_KEY_BASE/${postId}_$createdAt.$JPG"

    override fun toTagging(): Tagging = listOf(
        tag(TagKey.postId.name, this.postId.toString()),
        tag(TagKey.createdAt.name, this.createdAt.toString()),
        tag(TagKey.postType.name, PulpFictionProtos.Post.PostType.USER.name),
        tag(TagKey.userId.name, this.userId.toString()),
        tag(TagKey.fileType.name, JPG),
    ).toTagging()
}

val Database.userPostData get() = this.sequenceOf(UserPostData)
