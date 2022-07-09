package co.firstorderlabs.pulpfiction.backendserver

import arrow.core.continuations.Effect
import arrow.core.continuations.effect
import co.firstorderlabs.pulpfiction.backendserver.TestProtoModelGenerator.generateRandomCreatePostRequest
import co.firstorderlabs.pulpfiction.backendserver.TestProtoModelGenerator.withRandomCreateImagePostRequest
import co.firstorderlabs.pulpfiction.backendserver.configs.S3Configs.CONTENT_DATA_S3_BUCKET_NAME
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.ImagePostDatum
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.ImagePostDatum.Companion.IMAGE_POSTS_KEY_BASE
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.Post
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.types.ReferencesS3Key
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.types.ReferencesS3Key.Companion.JPG
import co.firstorderlabs.pulpfiction.backendserver.testutils.TestContainerDependencies
import co.firstorderlabs.pulpfiction.backendserver.testutils.toByteString
import co.firstorderlabs.pulpfiction.backendserver.types.PulpFictionError
import co.firstorderlabs.pulpfiction.backendserver.types.S3DownloadError
import co.firstorderlabs.pulpfiction.backendserver.utils.effectWithError
import co.firstorderlabs.pulpfiction.backendserver.utils.getResultAndHandleErrors
import com.adobe.testing.s3mock.testcontainers.S3MockContainer
import com.google.protobuf.ByteString
import kotlinx.coroutines.runBlocking
import org.junit.jupiter.api.Assertions
import org.junit.jupiter.api.Test
import org.testcontainers.containers.PostgreSQLContainer
import org.testcontainers.junit.jupiter.Container
import org.testcontainers.junit.jupiter.Testcontainers
import software.amazon.awssdk.services.s3.model.GetObjectRequest
import software.amazon.awssdk.services.s3.model.GetObjectTaggingRequest
import software.amazon.awssdk.services.s3.model.Tag
import java.time.Instant
import java.util.UUID

suspend fun S3Messenger.downloadImage(
    post: ReferencesS3Key,
): Effect<PulpFictionError, ByteString> = effectWithError({ S3DownloadError(it) }) {
    val getObjectRequest = GetObjectRequest.builder().bucket(CONTENT_DATA_S3_BUCKET_NAME).key(post.toS3Key()).build()
    s3Client.getObjectAsBytes(getObjectRequest).asByteArray().toByteString()
}

suspend fun S3Messenger.getTagsForImageFromImage(
    post: ReferencesS3Key
): Effect<PulpFictionError, List<Tag>> = effectWithError({ S3DownloadError(it) }) {
    val getObjectTaggingRequest =
        GetObjectTaggingRequest.builder().bucket(CONTENT_DATA_S3_BUCKET_NAME).key(post.toS3Key()).build()
    s3Client.getObjectTagging(getObjectTaggingRequest).tagSet()
}

fun List<Tag>.toMap(): Map<String, String> = this.associate { it.key() to it.value() }

@Testcontainers
class S3MessengerTest {
    companion object : TestContainerDependencies() {
        @Container
        override val postgreSQLContainer: PostgreSQLContainer<Nothing> = createPostgreSQLContainer()

        @Container
        override val s3MockContainer: S3MockContainer = createS3MockContainer()

        private val s3Messenger by lazy {
            S3Messenger(s3Client)
        }
    }

    @Test
    fun testToS3Key() {
        val zeroUUID = UUID(0, 0)
        val post = ImagePostDatum {
            this.postId = zeroUUID
            this.createdAt = Instant.EPOCH
            this.imageS3Key = toS3Key()
        }

        Assertions.assertEquals(
            "$IMAGE_POSTS_KEY_BASE/${zeroUUID}_${Instant.EPOCH}.$JPG",
            post.imageS3Key
        )
    }

    @Test
    fun testUploadImageFromImagePost() {
        val createPostRequest = TestProtoModelGenerator
            .generateRandomLoginSession()
            .generateRandomCreatePostRequest()
            .withRandomCreateImagePostRequest()

        runBlocking {
            effect<PulpFictionError, Unit> {
                val post = Post.generateFromRequest(UUID.randomUUID(), createPostRequest).bind()
                val imagePostDatum = ImagePostDatum.createFromRequest(post, createPostRequest.createImagePostRequest)
                s3Messenger.putAndTagObject(imagePostDatum, createPostRequest.createImagePostRequest.imageJpg)
                    .bind()

                val imageJpg = s3Messenger.downloadImage(imagePostDatum).bind()
                Assertions.assertEquals(createPostRequest.createImagePostRequest.imageJpg, imageJpg)

                val imageTags = s3Messenger.getTagsForImageFromImage(imagePostDatum).bind().toMap()
                Assertions.assertEquals(
                    mapOf(
                        ImagePostDatum.Companion.TagKey.postId.name to post.postId.toString(),
                        ImagePostDatum.Companion.TagKey.createdAt.name to post.createdAt.toString(),
                        ImagePostDatum.Companion.TagKey.postType.name to post.postType.name,
                        ImagePostDatum.Companion.TagKey.fileType.name to JPG,
                    ),
                    imageTags
                )
            }.getResultAndHandleErrors()
        }
    }
}
