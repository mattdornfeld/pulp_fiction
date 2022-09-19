package co.firstorderlabs.pulpfiction.backendserver.databasemodels

import co.firstorderlabs.protos.pulpfiction.PostKt.imagePost
import co.firstorderlabs.protos.pulpfiction.PulpFictionProtos
import co.firstorderlabs.protos.pulpfiction.PulpFictionProtos.CreatePostRequest.CreateImagePostRequest
import co.firstorderlabs.protos.pulpfiction.PulpFictionProtos.Post.PostType
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.types.PostData
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.types.PostDatum
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.types.ReferencesS3Key
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.types.ReferencesS3Key.Companion.JPG
import org.ktorm.database.Database
import org.ktorm.entity.Entity
import org.ktorm.entity.sequenceOf
import org.ktorm.schema.timestamp
import org.ktorm.schema.uuid
import org.ktorm.schema.varchar
import software.amazon.awssdk.services.s3.model.Tagging
import java.time.Instant
import java.util.UUID

object ImagePostData : PostData<ImagePostDatum>("image_post_data") {
    override val postId = uuid("post_id").primaryKey().bindTo { it.postId }
    override val createdAt = timestamp("created_at").primaryKey().bindTo { it.createdAt }
    val imageS3Key = varchar("image_s3_key").bindTo { it.imageS3Key }
    val caption = varchar("caption").bindTo { it.caption }
}

interface ImagePostDatum : Entity<ImagePostDatum>, ReferencesS3Key, PostDatum {
    companion object : Entity.Factory<ImagePostDatum>() {
        enum class TagKey {
            createdAt,
            postId,
            postType,
            fileType,
        }

        const val IMAGE_POSTS_KEY_BASE = "image_posts"

        fun fromRequest(post: Post, request: CreateImagePostRequest): ImagePostDatum = ImagePostDatum {
            this.postId = post.postId
            this.createdAt = post.createdAt
            this.caption = request.caption
            this.imageS3Key = toS3Key()
        }
    }

    var postId: UUID
    var createdAt: Instant
    var imageS3Key: String
    var caption: String

    override fun toS3Key(): String = "$IMAGE_POSTS_KEY_BASE/${postId}_$createdAt.$JPG"

    override fun toTagging(): Tagging = listOf(
        tag(TagKey.postId.name, this.postId.toString()),
        tag(TagKey.createdAt.name, this.createdAt.toString()),
        tag(TagKey.postType.name, PostType.IMAGE.name),
        tag(TagKey.fileType.name, JPG),
    ).toTagging()

    fun toProto(postInteractions: PulpFictionProtos.Post.InteractionAggregates): PulpFictionProtos.Post.ImagePost = imagePost {
        this.imageUrl = this@ImagePostDatum.imageS3Key // TODO (matt): Replace with url
        this.caption = this@ImagePostDatum.caption
        this.interactionAggregates = postInteractions
    }
}

val Database.imagePostData get() = this.sequenceOf(ImagePostData)
