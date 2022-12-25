package co.firstorderlabs.pulpfiction.backendserver.testutils

import arrow.core.continuations.Effect
import arrow.core.continuations.effect
import co.firstorderlabs.pulpfiction.backendserver.DatabaseMessenger
import co.firstorderlabs.pulpfiction.backendserver.MigrateDatabase
import co.firstorderlabs.pulpfiction.backendserver.SecretsDecrypter
import co.firstorderlabs.pulpfiction.backendserver.configs.AwsConfigs
import co.firstorderlabs.pulpfiction.backendserver.configs.TestConfigs.LOCAL_STACK_IMAGE
import co.firstorderlabs.pulpfiction.backendserver.configs.TestConfigs.POSTGRES_IMAGE
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.CommentData
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.Followers
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.ImagePostData
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.LoginSessions
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.PostInteractionAggregates
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.PostLikes
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.PostUpdates
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.Posts
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.UserPostData
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.Users
import co.firstorderlabs.pulpfiction.backendserver.types.DatabaseUrl
import co.firstorderlabs.pulpfiction.backendserver.types.PulpFictionStartupError
import co.firstorderlabs.pulpfiction.backendserver.utils.getOrThrow
import co.firstorderlabs.pulpfiction.backendserver.utils.getResultAndThrowException
import kotlinx.coroutines.runBlocking
import org.ktorm.database.Database
import org.testcontainers.containers.PostgreSQLContainer
import org.testcontainers.containers.localstack.LocalStackContainer
import software.amazon.awssdk.auth.credentials.AwsBasicCredentials
import software.amazon.awssdk.auth.credentials.StaticCredentialsProvider
import software.amazon.awssdk.http.apache.ApacheHttpClient
import software.amazon.awssdk.regions.Region
import software.amazon.awssdk.services.s3.S3Client
import software.amazon.awssdk.services.s3.model.CreateBucketRequest
import java.time.Duration

abstract class S3AndPostgresContainers {
    protected abstract val postgreSQLContainer: PostgreSQLContainer<Nothing>
    protected abstract val localStackContainer: LocalStackContainer

    private val pulpFictionKmsClient: PulpFictionKmsClient by lazy(LazyThreadSafetyMode.PUBLICATION) {
        PulpFictionKmsClient(localStackContainer)
    }

    private val secretsDecrypter: SecretsDecrypter by lazy(LazyThreadSafetyMode.PUBLICATION) {
        SecretsDecrypter(pulpFictionKmsClient.kmsClient)
    }

    protected val database by lazy(LazyThreadSafetyMode.PUBLICATION) {
        runBlocking {
            createDatabaseConnection(postgreSQLContainer).getResultAndThrowException()
        }
    }

    private suspend fun createDatabaseConnection(postgreSQLContainer: PostgreSQLContainer<Nothing>): Effect<PulpFictionStartupError, Database> =
        effect {
            val kmsKeyId = pulpFictionKmsClient.createKey().bind()
            val jsonCredentialsFile = ResourceFile("test_credentials.json").toTempFile().bind()
            val encryptedJsonCredentialsFile =
                secretsDecrypter.encryptJsonCredentialsFileWithKmsKey(kmsKeyId, jsonCredentialsFile.toPath()).bind()

            val databaseCredentials =
                secretsDecrypter.decryptJsonCredentialsFileWithKmsKey(
                    kmsKeyId,
                    encryptedJsonCredentialsFile.toPath()
                ).bind()
            postgreSQLContainer
                .withUsername(databaseCredentials.getOrThrow(DatabaseMessenger.DATABASE_CREDENTIALS_USERNAME_KEY))
            postgreSQLContainer.withPassword(databaseCredentials.getOrThrow(DatabaseMessenger.DATABASE_CREDENTIALS_PASSWORD_KEY))

            DatabaseMessenger.createDatabaseConnection(
                DatabaseUrl(postgreSQLContainer.jdbcUrl),
                databaseCredentials
            )
                .bind()
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

    protected val tables = listOf(
        CommentData,
        ImagePostData,
        PostLikes,
        UserPostData,
        PostUpdates,
        Followers,
        LoginSessions,
        PostInteractionAggregates,
        Posts,
        Users
    )

    open fun migrateDatabase() {
        MigrateDatabase(postgreSQLContainer.jdbcUrl, postgreSQLContainer.username, postgreSQLContainer.password)
            .migrateDatabase()
    }

    protected fun createPostgreSQLContainer(): PostgreSQLContainer<Nothing> =
        PostgreSQLContainer<Nothing>(POSTGRES_IMAGE).withStartupTimeout(Duration.ofSeconds(90))

    protected fun createLockStackContainer(): LocalStackContainer = LocalStackContainer(LOCAL_STACK_IMAGE)
        .withServices(LocalStackContainer.Service.S3)
        .withServices(LocalStackContainer.Service.KMS)
        .withStartupTimeout(Duration.ofSeconds(90))
}
