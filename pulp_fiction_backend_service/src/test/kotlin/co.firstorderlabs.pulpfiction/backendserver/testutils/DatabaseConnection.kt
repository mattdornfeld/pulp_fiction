package co.firstorderlabs.pulpfiction.backendserver.testutils

import co.firstorderlabs.pulpfiction.backendserver.configs.TestConfigs.POSTGRES_IMAGE
import co.firstorderlabs.pulpfiction.backendserver.database.MigrateDatabase
import co.firstorderlabs.pulpfiction.backendserver.database.models.CommentData
import co.firstorderlabs.pulpfiction.backendserver.database.models.Followers
import co.firstorderlabs.pulpfiction.backendserver.database.models.ImagePostData
import co.firstorderlabs.pulpfiction.backendserver.database.models.LoginSessions
import co.firstorderlabs.pulpfiction.backendserver.database.models.Posts
import co.firstorderlabs.pulpfiction.backendserver.database.models.Users
import org.ktorm.database.Database
import org.ktorm.support.postgresql.PostgreSqlDialect
import org.testcontainers.containers.PostgreSQLContainer

abstract class DatabaseConnection {
    protected abstract val postgreSQLContainer: PostgreSQLContainer<Nothing>

    open fun migrateDatabase() {
        MigrateDatabase(postgreSQLContainer.jdbcUrl, postgreSQLContainer.username, postgreSQLContainer.password)
            .migrateDatabase()
    }

    protected val database by lazy {
        Database.connect(
            url = postgreSQLContainer.jdbcUrl,
            user = postgreSQLContainer.username,
            password = postgreSQLContainer.password,
            dialect = PostgreSqlDialect(),
        )
    }

    protected val tables = listOf(CommentData, ImagePostData, Posts, Followers, LoginSessions, Users)

    protected fun createPostgreSQLContainer(): PostgreSQLContainer<Nothing> =
        PostgreSQLContainer<Nothing>(POSTGRES_IMAGE)
}
