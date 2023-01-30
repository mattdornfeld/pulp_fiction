package co.firstorderlabs.pulpfiction.backendserver.databasemodels

import co.firstorderlabs.protos.pulpfiction.PostKt.userPost
import co.firstorderlabs.protos.pulpfiction.PulpFictionProtos
import co.firstorderlabs.protos.pulpfiction.PulpFictionProtos.CreatePostRequest.CreateUserPostRequest
import co.firstorderlabs.protos.pulpfiction.UserKt.userMetadata
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.types.PostData
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.types.PostDatum
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.types.ReferencesS3Key
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.types.ReferencesS3Key.Companion.JPG
import co.firstorderlabs.pulpfiction.backendserver.utils.toTimestamp
import org.ktorm.database.Database
import org.ktorm.entity.Entity
import org.ktorm.entity.sequenceOf
import org.ktorm.schema.timestamp
import org.ktorm.schema.uuid
import org.ktorm.schema.varchar
import software.amazon.awssdk.services.s3.model.Tagging
import java.util.UUID

object UserPostData : PostData<UserPostDatum>("user_post_data") {
    override val postId = uuid("post_id")
        .primaryKey()
        .references(Posts) { it.post }
    override val updatedAt = timestamp("updated_at").primaryKey().bindTo { it.updatedAt }
    val userId = uuid("user_id").bindTo { it.userId }
    val displayName = varchar("display_name").bindTo { it.displayName }
    val avatarImageS3Key = varchar("avatar_image_s3_key").bindTo { it.avatarImageS3Key }
    val bio = varchar("bio").bindTo { it.bio }
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

        fun fromRequest(postUpdate: PostUpdate, request: CreateUserPostRequest) = UserPostDatum {
            this.post = postUpdate.post
            this.updatedAt = postUpdate.updatedAt
            this.userId = postUpdate.post.postCreatorId
            this.displayName = request.displayName
            this.avatarImageS3Key = toS3Key()
            this.bio = request.bio
        }
    }

    var userId: UUID
    var displayName: String
    var avatarImageS3Key: String?
    var bio: String

    override fun toS3Key(): String = "$USER_AVATARS_KEY_BASE/${post.postId}_$updatedAt.$JPG"

    override fun toTagging(): Tagging = listOf(
        tag(TagKey.postId.name, this.post.postId.toString()),
        tag(TagKey.createdAt.name, this.updatedAt.toString()),
        tag(TagKey.postType.name, PulpFictionProtos.Post.PostType.USER.name),
        tag(TagKey.userId.name, this.userId.toString()),
        tag(TagKey.fileType.name, JPG),
    ).toTagging()

    fun toProto(): PulpFictionProtos.Post.UserPost = userPost {
        val avatarImageS3Key = this@UserPostDatum.avatarImageS3Key
        this.userMetadata = userMetadata {
            this.userId = this@UserPostDatum.userId.toString()
            this.createdAt = this@UserPostDatum.updatedAt.toTimestamp()
            this.displayName = this@UserPostDatum.displayName
            avatarImageS3Key?.let { this.avatarImageUrl = it }
            this.latestUserPostUpdateIdentifier = this@UserPostDatum.getPostUpdateIdentifier()
            this.bio = this@UserPostDatum.bio
        }
    }
}

val Database.userPostData get() = this.sequenceOf(UserPostData)
