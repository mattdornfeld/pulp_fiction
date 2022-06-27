package co.firstorderlabs.pulpfiction.backendserver.database

import co.firstorderlabs.pulpfiction.backendserver.configs.TestConfigs.POSTGRES_IMAGE
import co.firstorderlabs.pulpfiction.backendserver.database.models.Post
import co.firstorderlabs.pulpfiction.backendserver.database.models.Posts
import co.firstorderlabs.pulpfiction.backendserver.database.models.TestDatabaseModelGenerator.generateRandom
import co.firstorderlabs.pulpfiction.backendserver.database.models.User
import co.firstorderlabs.pulpfiction.backendserver.database.models.Users
import co.firstorderlabs.pulpfiction.backendserver.database.models.posts
import co.firstorderlabs.pulpfiction.backendserver.database.models.users
import me.liuwj.ktorm.database.Database
import me.liuwj.ktorm.dsl.deleteAll
import me.liuwj.ktorm.dsl.from
import me.liuwj.ktorm.dsl.map
import me.liuwj.ktorm.dsl.select
import me.liuwj.ktorm.entity.add
import me.liuwj.ktorm.support.postgresql.PostgreSqlDialect
import org.junit.jupiter.api.AfterEach
import org.junit.jupiter.api.Assertions
import org.junit.jupiter.api.BeforeAll
import org.junit.jupiter.api.Test
import org.testcontainers.containers.PostgreSQLContainer
import org.testcontainers.junit.jupiter.Container
import org.testcontainers.junit.jupiter.Testcontainers

@Testcontainers
internal class MigrateDatabaseTest {
    companion object {
        @Container
        private val postgreSQLContainer = PostgreSQLContainer<Nothing>(POSTGRES_IMAGE)

        @BeforeAll
        @JvmStatic
        fun migrateDatabase() {
            MigrateDatabase(postgreSQLContainer.jdbcUrl, postgreSQLContainer.username, postgreSQLContainer.password)
                .migrateDatabase()
        }

        private val database by lazy {
            Database.connect(
                url = postgreSQLContainer.jdbcUrl,
                user = postgreSQLContainer.username,
                password = postgreSQLContainer.password,
                dialect = PostgreSqlDialect(),
            )
        }

        private val TABLES = listOf(Posts, Users)
    }

    @AfterEach
    fun clearTables() {
        TABLES.forEach { database.deleteAll(it) }
    }

    @Test
    fun testWriteToPostsTable() {
        database.posts.add(Post.generateRandom())
        val posts = database.from(Posts).select().map { Posts.createEntity(it) }
        Assertions.assertEquals(1, posts.size)
        Assertions.assertEquals(1, posts[0].id)
    }

    @Test
    fun testWriteToUsersTable() {
        database.users.add(User.generateRandom())
        val users = database.from(Users).select().map { Users.createEntity(it) }
        Assertions.assertEquals(1, users.size)
    }
}
