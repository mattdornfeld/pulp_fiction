package co.firstorderlabs.pulpfiction.backendserver.configs

import software.amazon.awssdk.regions.Region

object S3Configs {
    const val CONTENT_DATA_S3_BUCKET_NAME = "pulp-fiction-content-data"
    val S3_BUCKET_REGION = Region.US_EAST_1
}
