package co.firstorderlabs.pulpfiction.backendserver.configs

import software.amazon.awssdk.regions.Region

object AwsConfigs {
    const val CONTENT_DATA_S3_BUCKET_NAME: String = "pulp-fiction-content-data"
    val ACCOUNT_REGION: Region = Region.US_EAST_1
}
