package co.firstorderlabs.pulpfiction.backendserver.testutils

import co.firstorderlabs.pulpfiction.backendserver.configs.S3Configs
import co.firstorderlabs.pulpfiction.backendserver.configs.S3Configs.CONTENT_DATA_S3_BUCKET_NAME
import co.firstorderlabs.pulpfiction.backendserver.configs.TestConfigs.POSTGRES_IMAGE
import co.firstorderlabs.pulpfiction.backendserver.configs.TestConfigs.S3_MOCK_IMAGE_TAG
import co.firstorderlabs.pulpfiction.backendserver.database.MigrateDatabase
import co.firstorderlabs.pulpfiction.backendserver.database.models.CommentData
import co.firstorderlabs.pulpfiction.backendserver.database.models.Followers
import co.firstorderlabs.pulpfiction.backendserver.database.models.ImagePostData
import co.firstorderlabs.pulpfiction.backendserver.database.models.LoginSessions
import co.firstorderlabs.pulpfiction.backendserver.database.models.Posts
import co.firstorderlabs.pulpfiction.backendserver.database.models.Users
import com.adobe.testing.s3mock.testcontainers.S3MockContainer
import org.ktorm.database.Database
import org.ktorm.support.postgresql.PostgreSqlDialect
import org.testcontainers.containers.PostgreSQLContainer
import software.amazon.awssdk.auth.credentials.AwsBasicCredentials
import software.amazon.awssdk.auth.credentials.StaticCredentialsProvider
import software.amazon.awssdk.http.apache.ApacheHttpClient
import software.amazon.awssdk.services.s3.S3Client
import java.net.URI

abstract class TestContainerDependencies {
    protected abstract val postgreSQLContainer: PostgreSQLContainer<Nothing>
    protected abstract val s3MockContainer: S3MockContainer

    protected val database by lazy {
        Database.connect(
            url = postgreSQLContainer.jdbcUrl,
            user = postgreSQLContainer.username,
            password = postgreSQLContainer.password,
            dialect = PostgreSqlDialect(),
        )
    }

    protected val s3Client by lazy {
        S3Client.builder()
            .region(S3Configs.S3_BUCKET_REGION)
            .endpointOverride(URI(s3MockContainer.httpEndpoint))
            .httpClientBuilder(ApacheHttpClient.builder())
            .credentialsProvider(StaticCredentialsProvider.create(AwsBasicCredentials.create("test", "test")))
            .build()
    }

    protected val tables = listOf(CommentData, ImagePostData, Posts, Followers, LoginSessions, Users)

    open fun migrateDatabase() {
        MigrateDatabase(postgreSQLContainer.jdbcUrl, postgreSQLContainer.username, postgreSQLContainer.password)
            .migrateDatabase()
    }

    protected fun createPostgreSQLContainer(): PostgreSQLContainer<Nothing> =
        PostgreSQLContainer<Nothing>(POSTGRES_IMAGE)

    protected fun createS3MockContainer() = S3MockContainer(S3_MOCK_IMAGE_TAG)
        .withInitialBuckets(CONTENT_DATA_S3_BUCKET_NAME)
}
