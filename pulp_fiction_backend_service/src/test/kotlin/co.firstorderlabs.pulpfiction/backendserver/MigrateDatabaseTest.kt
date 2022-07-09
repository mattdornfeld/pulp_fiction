package co.firstorderlabs.pulpfiction.backendserver

import co.firstorderlabs.pulpfiction.backendserver.databasemodels.CommentData
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.CommentDatum
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.Follower
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.Followers
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.ImagePostData
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.ImagePostDatum
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.LoginSession
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.LoginSessions
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.Post
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.PostId
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.Posts
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.TestDatabaseModelGenerator.generateRandom
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.User
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.UserPostData
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.UserPostDatum
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.Users
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.commentData
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.followers
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.imagePostData
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.loginSessions
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.postIds
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.posts
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.userPostData
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.users
import co.firstorderlabs.pulpfiction.backendserver.testutils.TestContainerDependencies
import com.adobe.testing.s3mock.testcontainers.S3MockContainer
import org.junit.jupiter.api.AfterEach
import org.junit.jupiter.api.Assertions
import org.junit.jupiter.api.BeforeAll
import org.junit.jupiter.api.Test
import org.ktorm.dsl.deleteAll
import org.ktorm.dsl.from
import org.ktorm.dsl.map
import org.ktorm.dsl.select
import org.ktorm.entity.add
import org.testcontainers.containers.PostgreSQLContainer
import org.testcontainers.junit.jupiter.Container
import org.testcontainers.junit.jupiter.Testcontainers
import java.time.Instant

@Testcontainers
internal class MigrateDatabaseTest {
    companion object : TestContainerDependencies() {
        @Container
        override val postgreSQLContainer: PostgreSQLContainer<Nothing> = createPostgreSQLContainer()

        @Container
        override val s3MockContainer: S3MockContainer = createS3MockContainer()

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
        val post = Post.generateRandom()
        val user = User.generateRandom(post.postCreatorId)
        val postId = PostId {
            this.postId = post.postId
        }
        database.useTransaction {
            database.users.add(user)
            database.postIds.add(postId)
            database.posts.add(post)
        }

        val posts = database.from(Posts).select().map { Posts.createEntity(it) }
        Assertions.assertEquals(1, posts.size)
        Assertions.assertEquals(post, posts[0])
    }

    @Test
    fun testWriteToUsersTable() {
        val user = User.generateRandom()
        database.users.add(user)

        val users = database.from(Users).select().map { Users.createEntity(it) }
        Assertions.assertEquals(1, users.size)
        Assertions.assertEquals(user, users[0])
    }

    @Test
    fun testWriteToCommentDataTable() {
        val parentPost = Post.generateRandom()
        val parentPostUser = User.generateRandom(parentPost.postCreatorId)
        val commentPost = Post.generateRandom()
        val commentPostUser = User.generateRandom(commentPost.postCreatorId)
        val commmentDatum = CommentDatum.generateRandom(commentPost.postId, parentPost.postId)
        val parentPostId = PostId {
            this.postId = parentPost.postId
        }
        val commentPostId = PostId {
            this.postId = commentPost.postId
        }
        database.useTransaction {
            database.users.add(parentPostUser)
            database.users.add(commentPostUser)
            database.postIds.add(parentPostId)
            database.postIds.add(commentPostId)
            database.posts.add(parentPost)
            database.posts.add(commentPost)
            database.commentData.add(commmentDatum)
        }

        val commentData = database.from(CommentData).select().map { CommentData.createEntity(it) }
        Assertions.assertEquals(1, commentData.size)
        Assertions.assertEquals(commmentDatum, commentData[0])
    }

    @Test
    fun testWriteToImagePostDataTable() {
        val post = Post.generateRandom()
        val postId = post.toPostId()
        val user = User.generateRandom(post.postCreatorId)
        val imagePostDatum = ImagePostDatum.generateRandom(post.postId)
        database.useTransaction {
            database.users.add(user)
            database.postIds.add(postId)
            database.posts.add(post)
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
            createdAt = Instant.now()
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
        val post = Post.generateRandom()
        val user = User.generateRandom(post.postCreatorId)
        val postId = post.toPostId()
        val userPostDatum = UserPostDatum.generateRandom(post.postId, user.userId)
        database.useTransaction {
            database.users.add(user)
            database.postIds.add(postId)
            database.posts.add(post)
            database.userPostData.add(userPostDatum)
        }
        val userPostData = database.from(UserPostData).select().map { UserPostData.createEntity(it) }

        Assertions.assertEquals(userPostDatum, userPostData.first())
    }
}
