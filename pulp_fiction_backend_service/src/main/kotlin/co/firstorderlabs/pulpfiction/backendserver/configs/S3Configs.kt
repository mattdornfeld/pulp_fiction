package co.firstorderlabs.pulpfiction.backendserver.configs

import software.amazon.awssdk.regions.Region

object S3Configs {
    /**
     * Name of s3 bucket that contains the multimedia content data for the app. Note this cannot contain "-" symbols,
     * or it will not work properly with testcontainers.
     */
    const val CONTENT_DATA_S3_BUCKET_NAME = "pulp_fiction_content_data"
    val S3_BUCKET_REGION = Region.US_EAST_1
}
