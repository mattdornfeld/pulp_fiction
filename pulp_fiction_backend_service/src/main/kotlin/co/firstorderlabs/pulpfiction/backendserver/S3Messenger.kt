package co.firstorderlabs.pulpfiction.backendserver

import arrow.core.continuations.Effect
import co.firstorderlabs.pulpfiction.backendserver.configs.S3Configs.CONTENT_DATA_S3_BUCKET_NAME
import co.firstorderlabs.pulpfiction.backendserver.database.models.Post
import co.firstorderlabs.pulpfiction.backendserver.types.PulpFictionError
import co.firstorderlabs.pulpfiction.backendserver.types.S3UploadError
import co.firstorderlabs.pulpfiction.backendserver.utils.effectWithError
import com.google.protobuf.ByteString
import software.amazon.awssdk.core.sync.RequestBody
import software.amazon.awssdk.http.apache.ApacheHttpClient
import software.amazon.awssdk.regions.Region
import software.amazon.awssdk.services.s3.S3Client
import software.amazon.awssdk.services.s3.model.PutObjectRequest
import software.amazon.awssdk.services.s3.model.PutObjectResponse
import software.amazon.awssdk.services.s3.model.PutObjectTaggingRequest
import software.amazon.awssdk.services.s3.model.PutObjectTaggingResponse
import software.amazon.awssdk.services.s3.model.Tag
import software.amazon.awssdk.services.s3.model.Tagging

data class S3Messenger(val s3Client: S3Client) {
    companion object {
        enum class TagKey {
            createdAt,
            postId,
            postType,
            postCreatorId,
            fileType,
        }

        const val IMAGE_POSTS_KEY_BASE = "image_posts"
        const val JPG = "jpg"

        fun Post.toS3Key(): String = "$IMAGE_POSTS_KEY_BASE/${postId}_$createdAt.$JPG"

        private fun List<Tag>.toTagging(): Tagging = Tagging
            .builder()
            .tagSet(this).build()

        private fun tag(key: String, value: String): Tag = Tag
            .builder()
            .key(key)
            .value(value)
            .build()

        private fun Post.toTagging(): Tagging = listOf(
            tag(TagKey.postId.name, this.postId.toString()),
            tag(TagKey.createdAt.name, this.createdAt.toString()),
            tag(TagKey.postType.name, this.postType.name),
            tag(TagKey.postCreatorId.name, this.postCreatorId.toString()),
            tag(TagKey.fileType.name, JPG),
        ).toTagging()

        fun createS3Client(): S3Client = S3Client
            .builder()
            .region(Region.US_EAST_1)
            .httpClientBuilder(ApacheHttpClient.builder())
            .build()
    }

    private suspend fun putObject(
        post: Post,
        imageJpgAsBytes: ByteString
    ): Effect<PulpFictionError, PutObjectResponse> = effectWithError({ S3UploadError(it) }) {
        val putObjectRequest = PutObjectRequest
            .builder()
            .bucket(CONTENT_DATA_S3_BUCKET_NAME)
            .key(post.toS3Key())
            .build()

        s3Client.putObject(
            putObjectRequest,
            RequestBody.fromBytes(imageJpgAsBytes.toByteArray())
        )
    }

    private suspend fun tagObject(post: Post): Effect<PulpFictionError, PutObjectTaggingResponse> =
        effectWithError({ S3UploadError(it) }) {
            val putObjectTaggingRequest = PutObjectTaggingRequest
                .builder()
                .bucket(CONTENT_DATA_S3_BUCKET_NAME)
                .key(post.toS3Key())
                .tagging(post.toTagging())
                .build()

            s3Client.putObjectTagging(putObjectTaggingRequest)
        }

    suspend fun uploadImageFromImagePost(
        post: Post,
        imageJpg: ByteString
    ): Effect<PulpFictionError, PutObjectResponse> = effectWithError({ S3UploadError(it) }) {
        val putObjectResponse = putObject(post, imageJpg).bind()
        // TODO (matt): s3mock is currently broken since it does not properly tag objects as part of the putObject
        // request. So right now we tag the object in a separate request. Remove this when the issue is fixed.
        // https://github.com/adobe/S3Mock/issues/673
        tagObject(post).bind()
        putObjectResponse
    }
}
