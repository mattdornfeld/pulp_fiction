package co.firstorderlabs.pulpfiction.backendserver.testutils

import co.firstorderlabs.pulpfiction.backendserver.MigrateDatabase
import co.firstorderlabs.pulpfiction.backendserver.configs.AwsConfigs
import co.firstorderlabs.pulpfiction.backendserver.configs.TestConfigs.LOCAL_STACK_IMAGE
import co.firstorderlabs.pulpfiction.backendserver.configs.TestConfigs.POSTGRES_IMAGE
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.CommentData
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.Followers
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.ImagePostData
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.LoginSessions
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.Posts
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.UserPostData
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.Users
import org.ktorm.database.Database
import org.ktorm.support.postgresql.PostgreSqlDialect
import org.testcontainers.containers.PostgreSQLContainer
import org.testcontainers.containers.localstack.LocalStackContainer
import software.amazon.awssdk.auth.credentials.AwsBasicCredentials
import software.amazon.awssdk.auth.credentials.StaticCredentialsProvider
import software.amazon.awssdk.http.apache.ApacheHttpClient
import software.amazon.awssdk.regions.Region
import software.amazon.awssdk.services.s3.S3Client
import software.amazon.awssdk.services.s3.model.CreateBucketRequest

abstract class S3AndPostgresContainers {
    protected abstract val postgreSQLContainer: PostgreSQLContainer<Nothing>
    protected abstract val localStackContainer: LocalStackContainer

    protected val database by lazy {
        Database.connect(
            url = postgreSQLContainer.jdbcUrl,
            user = postgreSQLContainer.username,
            password = postgreSQLContainer.password,
            dialect = PostgreSqlDialect(),
        )
    }

    protected val s3Client: S3Client by lazy {
        val s3Client = S3Client.builder()
            .region(Region.of(localStackContainer.region))
            .endpointOverride(localStackContainer.getEndpointOverride(LocalStackContainer.Service.S3))
            .httpClientBuilder(ApacheHttpClient.builder())
            .credentialsProvider(StaticCredentialsProvider.create(AwsBasicCredentials.create("test", "test")))
            .build()

        s3Client.createBucket(CreateBucketRequest.builder().bucket(AwsConfigs.CONTENT_DATA_S3_BUCKET_NAME).build())

        s3Client
    }

    protected val tables = listOf(CommentData, ImagePostData, UserPostData, Posts, Followers, LoginSessions, Users)

    open fun migrateDatabase() {
        MigrateDatabase(postgreSQLContainer.jdbcUrl, postgreSQLContainer.username, postgreSQLContainer.password)
            .migrateDatabase()
    }

    protected fun createPostgreSQLContainer(): PostgreSQLContainer<Nothing> =
        PostgreSQLContainer<Nothing>(POSTGRES_IMAGE)

    protected fun createLockStackContainer(): LocalStackContainer = LocalStackContainer(LOCAL_STACK_IMAGE)
        .withServices(LocalStackContainer.Service.S3)
}
