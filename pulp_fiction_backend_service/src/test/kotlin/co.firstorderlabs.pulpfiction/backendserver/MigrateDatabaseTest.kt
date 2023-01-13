package co.firstorderlabs.pulpfiction.backendserver

import co.firstorderlabs.pulpfiction.backendserver.databasemodels.CommentData
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.CommentDatum
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.Follower
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.Followers
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.ImagePostData
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.ImagePostDatum
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.LoginSession
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.LoginSessions
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.PostLike
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.PostLikes
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.PostUpdate
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.PostUpdates
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.TestDatabaseModelGenerator.generateRandom
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.User
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.UserPostData
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.UserPostDatum
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.commentData
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.emails
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.followers
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.imagePostData
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.loginSessions
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.phoneNumbers
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.postLikes
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.postUpdates
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.posts
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.userPostData
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.users
import co.firstorderlabs.pulpfiction.backendserver.testutils.S3AndPostgresContainers
import co.firstorderlabs.pulpfiction.backendserver.testutils.assertEquals
import co.firstorderlabs.pulpfiction.backendserver.testutils.getOrThrow
import co.firstorderlabs.pulpfiction.backendserver.utils.nowTruncated
import org.junit.jupiter.api.AfterEach
import org.junit.jupiter.api.Assertions
import org.junit.jupiter.api.BeforeAll
import org.junit.jupiter.api.Test
import org.ktorm.dsl.deleteAll
import org.ktorm.dsl.eq
import org.ktorm.dsl.from
import org.ktorm.dsl.joinReferencesAndSelect
import org.ktorm.dsl.map
import org.ktorm.dsl.select
import org.ktorm.entity.add
import org.ktorm.entity.find
import org.testcontainers.containers.PostgreSQLContainer
import org.testcontainers.containers.localstack.LocalStackContainer
import org.testcontainers.junit.jupiter.Container
import org.testcontainers.junit.jupiter.Testcontainers

@Testcontainers
internal class MigrateDatabaseTest {
    companion object : S3AndPostgresContainers() {
        @Container
        override val postgreSQLContainer: PostgreSQLContainer<Nothing> = createPostgreSQLContainer()

        @Container
        override val localStackContainer: LocalStackContainer = createLockStackContainer()

        @BeforeAll
        @JvmStatic
        override fun migrateDatabase() = super.migrateDatabase()
    }

    @AfterEach
    fun clearTables() {
        tables.forEach { database.deleteAll(it) }
    }

    @Test
    fun testWriteToPostsTable() {
        val expectedPostUpdate = PostUpdate.generateRandom()
        val user = User.generateRandom(expectedPostUpdate.post.postCreatorId)
        database.useTransaction {
            database.users.add(user)
            database.posts.add(expectedPostUpdate.post)
            database.postUpdates.add(expectedPostUpdate)
        }

        val postUpdates = database.from(PostUpdates).joinReferencesAndSelect().map { PostUpdates.createEntity(it) }
        println(expectedPostUpdate)
        println(postUpdates[0])
        Assertions.assertEquals(1, postUpdates.size)
        Assertions.assertEquals(expectedPostUpdate, postUpdates[0])
    }

    @Test
    fun testWriteToUsersTable() {
        val expectedUser = User.generateRandom()
        database.users.add(expectedUser)
        database.emails.add(expectedUser.email)
        database.phoneNumbers.add(expectedUser.phoneNumber)

        val user = database.users.find { it.userId eq expectedUser.userId }.getOrThrow()
        expectedUser.assertEquals(user)
    }

    @Test
    fun testWriteToCommentDataTable() {
        val parentPostUpdate = PostUpdate.generateRandom()
        val parentPostUser = User.generateRandom(parentPostUpdate.post.postCreatorId)
        val commentPostUpdate = PostUpdate.generateRandom()
        val commentPostUser = User.generateRandom(commentPostUpdate.post.postCreatorId)
        val commmentDatum = CommentDatum.generateRandom(commentPostUpdate.post.postId, parentPostUpdate.post.postId)
        database.useTransaction {
            database.users.add(parentPostUser)
            database.users.add(commentPostUser)
            database.posts.add(parentPostUpdate.post)
            database.posts.add(commentPostUpdate.post)
            database.postUpdates.add(parentPostUpdate)
            database.postUpdates.add(commentPostUpdate)
            database.commentData.add(commmentDatum)
        }

        val commentData = database.from(CommentData).select().map { CommentData.createEntity(it) }
        Assertions.assertEquals(1, commentData.size)
        Assertions.assertEquals(commmentDatum, commentData[0])
    }

    @Test
    fun testWriteToImagePostDataTable() {
        val postUpdate = PostUpdate.generateRandom()
        val user = User.generateRandom(postUpdate.post.postCreatorId)
        val imagePostDatum = ImagePostDatum.generateRandom(postUpdate.post.postId)
        database.useTransaction {
            database.users.add(user)
            database.posts.add(postUpdate.post)
            database.postUpdates.add(postUpdate)
            database.imagePostData.add(imagePostDatum)
        }

        val imagePostData = database.from(ImagePostData).select().map { ImagePostData.createEntity(it) }
        Assertions.assertEquals(1, imagePostData.size)
        Assertions.assertEquals(imagePostDatum, imagePostData[0])
    }

    @Test
    fun testWriteToFollowersTable() {
        val user1 = User.generateRandom()
        val user2 = User.generateRandom()
        val follower = Follower {
            userId = user1.userId
            followerId = user2.userId
            createdAt = nowTruncated()
        }
        database.useTransaction {
            database.users.add(user1)
            database.users.add(user2)
            database.followers.add(follower)
        }

        val followers = database.from(Followers).select().map { Followers.createEntity(it) }
        Assertions.assertEquals(1, followers.size)
        Assertions.assertEquals(follower, followers[0])
    }

    @Test
    fun testWriteToLoginSessionsTable() {
        val user = User.generateRandom()
        val loginSession = LoginSession.generateRandom(user.userId)
        database.useTransaction {
            database.users.add(user)
            database.loginSessions.add(loginSession)
        }
        val loginSessions = database.from(LoginSessions).select().map { LoginSessions.createEntity(it) }
        Assertions.assertEquals(1, loginSessions.size)
        Assertions.assertEquals(loginSession, loginSessions[0])
    }

    @Test
    fun testWriteToUserPostDataTable() {
        val postUpdate = PostUpdate.generateRandom()
        val user = User.generateRandom(postUpdate.post.postCreatorId)
        val userPostDatum = UserPostDatum.generateRandom(postUpdate.post.postId, user.userId)
        database.useTransaction {
            database.users.add(user)
            database.posts.add(postUpdate.post)
            database.postUpdates.add(postUpdate)
            database.userPostData.add(userPostDatum)
        }
        val userPostData = database.from(UserPostData).select().map { UserPostData.createEntity(it) }

        Assertions.assertEquals(userPostDatum, userPostData.first())
    }

    @Test
    fun testWriteToPostLikesTable() {
        val postUpdate = PostUpdate.generateRandom()
        val user = User.generateRandom(postUpdate.post.postCreatorId)
        val postLike = PostLike.generateRandom(user.userId, postUpdate.post.postId)
        database.useTransaction {
            database.users.add(user)
            database.posts.add(postUpdate.post)
            database.postUpdates.add(postUpdate)
            database.postLikes.add(postLike)
        }
        val postlikes = database.from(PostLikes).select().map { PostLikes.createEntity(it) }

        Assertions.assertEquals(postLike, postlikes.first())
    }
}
