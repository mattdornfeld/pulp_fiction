package co.firstorderlabs.pulpfiction.backendserver

import arrow.core.continuations.Effect
import co.firstorderlabs.pulpfiction.backendserver.configs.AwsConfigs
import co.firstorderlabs.pulpfiction.backendserver.configs.AwsConfigs.CONTENT_DATA_S3_BUCKET_NAME
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.types.ReferencesS3Key
import co.firstorderlabs.pulpfiction.backendserver.types.PulpFictionRequestError
import co.firstorderlabs.pulpfiction.backendserver.types.S3UploadError
import co.firstorderlabs.pulpfiction.backendserver.utils.effectWithError
import com.google.protobuf.ByteString
import software.amazon.awssdk.core.sync.RequestBody
import software.amazon.awssdk.http.apache.ApacheHttpClient
import software.amazon.awssdk.services.s3.S3Client
import software.amazon.awssdk.services.s3.model.PutObjectRequest
import software.amazon.awssdk.services.s3.model.PutObjectResponse

class S3Messenger(val s3Client: S3Client) {
    companion object {
        fun createS3Client(): S3Client = S3Client
            .builder()
            .region(AwsConfigs.ACCOUNT_REGION)
            .httpClientBuilder(ApacheHttpClient.builder())
            .build()
    }

    suspend fun putAndTagObject(
        postData: ReferencesS3Key,
        imageJpg: ByteString
    ): Effect<PulpFictionRequestError, PutObjectResponse> = effectWithError({ S3UploadError(it) }) {
        val putObjectRequest = PutObjectRequest
            .builder()
            .bucket(CONTENT_DATA_S3_BUCKET_NAME)
            .key(postData.toS3Key())
            .tagging(postData.toTagging())
            .build()

        s3Client.putObject(
            putObjectRequest,
            RequestBody.fromBytes(imageJpg.toByteArray())
        )
    }
}
