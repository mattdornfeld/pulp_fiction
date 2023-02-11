package co.firstorderlabs.pulpfiction.backendserver.databasemodels

import arrow.core.continuations.Effect
import arrow.core.continuations.effect
import arrow.core.getOrElse
import co.firstorderlabs.protos.pulpfiction.PostKt.imagePost
import co.firstorderlabs.protos.pulpfiction.PostKt.loggedInUserPostInteractions
import co.firstorderlabs.protos.pulpfiction.PulpFictionProtos
import co.firstorderlabs.protos.pulpfiction.PulpFictionProtos.CreatePostRequest.CreateImagePostRequest
import co.firstorderlabs.protos.pulpfiction.PulpFictionProtos.Post.PostType
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.types.PostData
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.types.PostDatum
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.types.ReferencesS3Key
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.types.ReferencesS3Key.Companion.JPG
import co.firstorderlabs.pulpfiction.backendserver.types.PostNotFoundError
import co.firstorderlabs.pulpfiction.backendserver.types.PulpFictionRequestError
import co.firstorderlabs.pulpfiction.backendserver.utils.firstOrOption
import co.firstorderlabs.pulpfiction.backendserver.utils.nowTruncated
import org.ktorm.database.Database
import org.ktorm.dsl.eq
import org.ktorm.dsl.from
import org.ktorm.dsl.joinReferencesAndSelect
import org.ktorm.dsl.map
import org.ktorm.dsl.where
import org.ktorm.entity.Entity
import org.ktorm.entity.add
import org.ktorm.entity.sequenceOf
import org.ktorm.schema.timestamp
import org.ktorm.schema.uuid
import org.ktorm.schema.varchar
import software.amazon.awssdk.services.s3.model.Tagging
import java.util.UUID

object ImagePostData : PostData<ImagePostDatum>("image_post_data") {
    override val postId = uuid("post_id")
        .primaryKey()
        .references(Posts) { it.post }
    override val updatedAt = timestamp("updated_at").primaryKey().bindTo { it.updatedAt }
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

        fun fromRequest(postUpdate: PostUpdate, request: CreateImagePostRequest): ImagePostDatum = ImagePostDatum {
            this.post = postUpdate.post
            this.updatedAt = postUpdate.updatedAt
            this.caption = request.caption
            this.imageS3Key = toS3Key()
        }
    }

    var imageS3Key: String
    var caption: String

    override fun toS3Key(): String = "$IMAGE_POSTS_KEY_BASE/${post.postId}_$updatedAt.$JPG"

    override fun toTagging(): Tagging = listOf(
        tag(TagKey.postId.name, this.post.postId.toString()),
        tag(TagKey.createdAt.name, this.updatedAt.toString()),
        tag(TagKey.postType.name, PostType.IMAGE.name),
        tag(TagKey.fileType.name, JPG),
    ).toTagging()

    fun toProto(
        loggedInUserPostInteractions: PulpFictionProtos.Post.LoggedInUserPostInteractions
    ): PulpFictionProtos.Post.ImagePost = imagePost {
        this.imageUrl = this@ImagePostDatum.imageS3Key // TODO (matt): Replace with url
        this.caption = this@ImagePostDatum.caption
        this.interactionAggregates = this@ImagePostDatum.post.postInteractionAggregate.toProto()
        this.loggedInUserPostInteractions = loggedInUserPostInteractions
    }

    fun toProto(): PulpFictionProtos.Post.ImagePost = toProto(loggedInUserPostInteractions {})

    fun withCaption(newCaption: String): ImagePostDatum =
        ImagePostDatum {
            this.post = this@ImagePostDatum.post
            this.updatedAt = nowTruncated()
            this.imageS3Key = this@ImagePostDatum.imageS3Key
            this.caption = newCaption
        }
}

val Database.imagePostData get() = this.sequenceOf(ImagePostData)

fun Database.getImagePostDatum(postId: UUID): Effect<PulpFictionRequestError, ImagePostDatum> = effect {
    this@getImagePostDatum
        .from(ImagePostData)
        .joinReferencesAndSelect()
        .where { ImagePostData.postId eq postId }
        .map { ImagePostData.createEntity(it) }
        .firstOrOption()
        .getOrElse { shift(PostNotFoundError(postId)) }
}

fun Database.addImagePostDatumUpdate(imagePostDatum: ImagePostDatum): Effect<PulpFictionRequestError, Unit> = effect {
    this@addImagePostDatumUpdate.postUpdates.add(imagePostDatum.getPostUpdate())
    this@addImagePostDatumUpdate.imagePostData.add(imagePostDatum)
}
