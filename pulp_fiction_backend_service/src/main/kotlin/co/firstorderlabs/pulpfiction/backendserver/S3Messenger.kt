package co.firstorderlabs.pulpfiction.backendserver

import arrow.core.continuations.Effect
import co.firstorderlabs.pulpfiction.backendserver.configs.S3Configs.CONTENT_DATA_S3_BUCKET_NAME
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.types.ReferencesS3Key
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

class S3Messenger(val s3Client: S3Client) {
    companion object {
        fun createS3Client(): S3Client = S3Client
            .builder()
            .region(Region.US_EAST_1)
            .httpClientBuilder(ApacheHttpClient.builder())
            .build()
    }

    private suspend fun putObject(
        postData: ReferencesS3Key,
        imageJpg: ByteString
    ): Effect<PulpFictionError, PutObjectResponse> = effectWithError({ S3UploadError(it) }) {
        val putObjectRequest = PutObjectRequest
            .builder()
            .bucket(CONTENT_DATA_S3_BUCKET_NAME)
            .key(postData.toS3Key())
            .build()

        s3Client.putObject(
            putObjectRequest,
            RequestBody.fromBytes(imageJpg.toByteArray())
        )
    }

    private suspend fun tagObject(postData: ReferencesS3Key): Effect<PulpFictionError, PutObjectTaggingResponse> =
        effectWithError({ S3UploadError(it) }) {
            val putObjectTaggingRequest = PutObjectTaggingRequest
                .builder()
                .bucket(CONTENT_DATA_S3_BUCKET_NAME)
                .key(postData.toS3Key())
                .tagging(postData.toTagging())
                .build()

            s3Client.putObjectTagging(putObjectTaggingRequest)
        }

    suspend fun putAndTagObject(
        postData: ReferencesS3Key,
        objectAsBytes: ByteString
    ): Effect<PulpFictionError, PutObjectResponse> = effectWithError({ S3UploadError(it) }) {
        val putObjectResponse = putObject(postData, objectAsBytes).bind()
        // TODO (matt): s3mock is currently broken since it does not properly tag objects as part of the putObject
        // request. So right now we tag the object in a separate request. Remove this when the issue is fixed.
        // https://github.com/adobe/S3Mock/issues/673
        tagObject(postData).bind()
        putObjectResponse
    }
}
