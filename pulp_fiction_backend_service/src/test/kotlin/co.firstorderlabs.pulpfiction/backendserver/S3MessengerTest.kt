package co.firstorderlabs.pulpfiction.backendserver

import arrow.core.continuations.Effect
import arrow.core.continuations.effect
import co.firstorderlabs.pulpfiction.backendserver.TestProtoModelGenerator.generateRandomCreatePostRequest
import co.firstorderlabs.pulpfiction.backendserver.TestProtoModelGenerator.withRandomCreateImagePostRequest
import co.firstorderlabs.pulpfiction.backendserver.TestProtoModelGenerator.withRandomCreateUserPostRequest
import co.firstorderlabs.pulpfiction.backendserver.configs.S3Configs.CONTENT_DATA_S3_BUCKET_NAME
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.ImagePostDatum
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.ImagePostDatum.Companion.IMAGE_POSTS_KEY_BASE
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.Post
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.UserPostDatum
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.types.ReferencesS3Key
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.types.ReferencesS3Key.Companion.JPG
import co.firstorderlabs.pulpfiction.backendserver.testutils.TestContainerDependencies
import co.firstorderlabs.pulpfiction.backendserver.testutils.assertEquals
import co.firstorderlabs.pulpfiction.backendserver.testutils.runBlockingEffect
import co.firstorderlabs.pulpfiction.backendserver.testutils.toByteString
import co.firstorderlabs.pulpfiction.backendserver.types.PulpFictionError
import co.firstorderlabs.pulpfiction.backendserver.types.S3DownloadError
import co.firstorderlabs.pulpfiction.backendserver.utils.effectWithError
import com.google.protobuf.ByteString
import org.junit.jupiter.api.Assertions
import org.junit.jupiter.api.Test
import org.testcontainers.containers.PostgreSQLContainer
import org.testcontainers.containers.localstack.LocalStackContainer
import org.testcontainers.junit.jupiter.Container
import org.testcontainers.junit.jupiter.Testcontainers
import software.amazon.awssdk.services.s3.model.GetObjectRequest
import software.amazon.awssdk.services.s3.model.GetObjectTaggingRequest
import software.amazon.awssdk.services.s3.model.Tag
import java.time.Instant
import java.util.UUID

suspend fun S3Messenger.getObject(
    s3Key: String,
): Effect<PulpFictionError, ByteString> = effectWithError({ S3DownloadError(it) }) {
    val getObjectRequest = GetObjectRequest.builder().bucket(CONTENT_DATA_S3_BUCKET_NAME).key(s3Key).build()
    s3Client.getObjectAsBytes(getObjectRequest).asByteArray().toByteString()
}

suspend fun S3Messenger.getObjectTags(
    s3Key: String
): Effect<PulpFictionError, List<Tag>> = effectWithError({ S3DownloadError(it) }) {
    val getObjectTaggingRequest =
        GetObjectTaggingRequest.builder().bucket(CONTENT_DATA_S3_BUCKET_NAME).key(s3Key).build()
    s3Client.getObjectTagging(getObjectTaggingRequest).tagSet()
}

suspend fun S3Messenger.getObject(
    post: ReferencesS3Key,
): Effect<PulpFictionError, ByteString> = getObject(post.toS3Key())

suspend fun S3Messenger.getObjectTags(
    post: ReferencesS3Key
): Effect<PulpFictionError, List<Tag>> = getObjectTags(post.toS3Key())

fun List<Tag>.toMap(): Map<String, String> = this.associate { it.key() to it.value() }

@Testcontainers
class S3MessengerTest {
    companion object : TestContainerDependencies() {
        @Container
        override val postgreSQLContainer: PostgreSQLContainer<Nothing> = createPostgreSQLContainer()

        @Container
        override val localStackContainer: LocalStackContainer = createLockStackContainer()

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

    private suspend fun uploadObjectAndAssertCorrect(
        referencesS3Key: ReferencesS3Key,
        objectAsByteString: ByteString,
        expectedTags: Map<String, String>
    ): Effect<PulpFictionError, Unit> = effect {
        s3Messenger
            .putAndTagObject(referencesS3Key, objectAsByteString)
            .bind()

        s3Messenger
            .getObject(referencesS3Key)
            .bind()
            .assertEquals(objectAsByteString) { it }

        s3Messenger
            .getObjectTags(referencesS3Key)
            .bind()
            .toMap()
            .assertEquals(expectedTags) { it }
    }

    @Test
    fun testUploadImageFromImagePost() {
        val createPostRequest = TestProtoModelGenerator
            .generateRandomLoginSession()
            .generateRandomCreatePostRequest()
            .withRandomCreateImagePostRequest()

        runBlockingEffect {
            val post = Post.fromRequest(UUID.randomUUID(), createPostRequest).bind()
            val imagePostDatum = ImagePostDatum.fromRequest(post, createPostRequest.createImagePostRequest)
            uploadObjectAndAssertCorrect(
                imagePostDatum,
                createPostRequest.createImagePostRequest.imageJpg,
                mapOf(
                    ImagePostDatum.Companion.TagKey.postId.name to post.postId.toString(),
                    ImagePostDatum.Companion.TagKey.createdAt.name to post.createdAt.toString(),
                    ImagePostDatum.Companion.TagKey.postType.name to post.postType.name,
                    ImagePostDatum.Companion.TagKey.fileType.name to JPG,
                )
            ).bind()
        }
    }

    @Test
    fun testUploadAvatarFromUserPost() {
        val createPostRequest = TestProtoModelGenerator
            .generateRandomLoginSession()
            .generateRandomCreatePostRequest()
            .withRandomCreateUserPostRequest()

        runBlockingEffect {
            val post = Post.fromRequest(UUID.randomUUID(), createPostRequest).bind()
            val userPostDatum = UserPostDatum.fromRequest(post, createPostRequest.createUserPostRequest)
            uploadObjectAndAssertCorrect(
                userPostDatum,
                createPostRequest.createUserPostRequest.avatarJpg,
                mapOf(
                    UserPostDatum.Companion.TagKey.postId.name to post.postId.toString(),
                    UserPostDatum.Companion.TagKey.createdAt.name to post.createdAt.toString(),
                    UserPostDatum.Companion.TagKey.postType.name to post.postType.name,
                    UserPostDatum.Companion.TagKey.fileType.name to JPG,
                    UserPostDatum.Companion.TagKey.userId.name to createPostRequest.loginSession.userId.toString()
                )
            ).bind()
        }
    }
}
