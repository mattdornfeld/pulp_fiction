package co.firstorderlabs.pulpfiction.backendserver.database

import co.firstorderlabs.pulpfiction.backendserver.database.models.CommentData
import co.firstorderlabs.pulpfiction.backendserver.database.models.CommentDatum
import co.firstorderlabs.pulpfiction.backendserver.database.models.Follower
import co.firstorderlabs.pulpfiction.backendserver.database.models.Followers
import co.firstorderlabs.pulpfiction.backendserver.database.models.ImagePostData
import co.firstorderlabs.pulpfiction.backendserver.database.models.ImagePostDatum
import co.firstorderlabs.pulpfiction.backendserver.database.models.LoginSession
import co.firstorderlabs.pulpfiction.backendserver.database.models.LoginSessions
import co.firstorderlabs.pulpfiction.backendserver.database.models.Post
import co.firstorderlabs.pulpfiction.backendserver.database.models.PostId
import co.firstorderlabs.pulpfiction.backendserver.database.models.Posts
import co.firstorderlabs.pulpfiction.backendserver.database.models.TestDatabaseModelGenerator.generateRandom
import co.firstorderlabs.pulpfiction.backendserver.database.models.User
import co.firstorderlabs.pulpfiction.backendserver.database.models.Users
import co.firstorderlabs.pulpfiction.backendserver.database.models.comment_data
import co.firstorderlabs.pulpfiction.backendserver.database.models.followers
import co.firstorderlabs.pulpfiction.backendserver.database.models.image_post_data
import co.firstorderlabs.pulpfiction.backendserver.database.models.loginSessions
import co.firstorderlabs.pulpfiction.backendserver.database.models.postIds
import co.firstorderlabs.pulpfiction.backendserver.database.models.posts
import co.firstorderlabs.pulpfiction.backendserver.database.models.users
import co.firstorderlabs.pulpfiction.backendserver.testutils.DatabaseConnection
import org.junit.jupiter.api.AfterEach
import org.junit.jupiter.api.Assertions
import org.junit.jupiter.api.BeforeAll
import org.junit.jupiter.api.Test
import org.ktorm.dsl.deleteAll
import org.ktorm.dsl.from
import org.ktorm.dsl.map
import org.ktorm.dsl.select
import org.ktorm.entity.add
import org.testcontainers.junit.jupiter.Container
import org.testcontainers.junit.jupiter.Testcontainers
import java.time.Instant

@Testcontainers
internal class MigrateDatabaseTest {
    companion object : DatabaseConnection() {
        @Container
        override val postgreSQLContainer = createPostgreSQLContainer()

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
            database.comment_data.add(commmentDatum)
        }

        val commentData = database.from(CommentData).select().map { CommentData.createEntity(it) }
        Assertions.assertEquals(1, commentData.size)
        Assertions.assertEquals(commmentDatum, commentData[0])
    }

    @Test
    fun testWriteToImagePostDataTable() {
        val post = Post.generateRandom()
        val postId = PostId {
            this.postId = post.postId
        }
        val user = User.generateRandom(post.postCreatorId)
        val imagePostDatum = ImagePostDatum.generateRandom(post.postId)
        database.useTransaction {
            database.users.add(user)
            database.postIds.add(postId)
            database.posts.add(post)
            database.image_post_data.add(imagePostDatum)
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
}
