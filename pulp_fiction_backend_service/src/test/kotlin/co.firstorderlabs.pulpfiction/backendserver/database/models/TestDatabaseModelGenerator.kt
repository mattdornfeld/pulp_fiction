package co.firstorderlabs.pulpfiction.backendserver.database.models

import io.github.serpro69.kfaker.Faker
import java.time.Instant
import java.util.UUID
import java.util.concurrent.ThreadLocalRandom
import kotlin.random.Random

object TestDatabaseModelGenerator {
    private val faker = Faker()

    private inline fun <reified T : Enum<T>> generateRandomEnumValue(): T {
        val unrecognizedName = "UNRECOGNIZED"
        val enumValues2 = enumValues<T>().filter { !it.name.equals(unrecognizedName) }
        return enumValues2[Random.nextInt(enumValues2.size)]
    }

    private fun generateRandomInstant(): Instant = generateRandomInstant(Instant.EPOCH, Instant.now())

    private fun generateRandomInstant(start: Instant, end: Instant): Instant {
        val startSeconds = start.epochSecond
        val endSeconds = end.epochSecond
        val random = ThreadLocalRandom
            .current()
            .nextLong(startSeconds, endSeconds)

        return Instant.ofEpochSecond(random)
    }

    fun Post.Companion.generateRandom(): Post = Post {
        this.postId = UUID.randomUUID()
        this.postState = generateRandomEnumValue()
        this.createdAt = Instant.EPOCH
        this.postCreatorId = UUID.randomUUID()
        this.postType = generateRandomEnumValue()
    }

    fun User.Companion.generateRandom(): User = generateRandom(UUID.randomUUID())

    fun User.Companion.generateRandom(userId: UUID): User = User {
        this.userId = userId
        this.createdAt = Instant.now()
        this.displayName = faker.funnyName.name()
        this.email = faker.internet.email()
        this.phoneNumber = faker.phoneNumber.phoneNumber()
        this.dateOfBirth = faker.person.birthDate(30)
        this.avatarImageUrl = faker.internet.domain()
        this.hashedPassword = faker.unique.toString()
    }

    fun CommentDatum.Companion.generateRandom(postId: UUID, parentPostId: UUID): CommentDatum = CommentDatum {
        this.postId = postId
        this.createdAt = Instant.EPOCH
        this.body = faker.worldOfWarcraft.quotes()
        this.parentPostId = parentPostId
    }

    fun ImagePostDatum.Companion.generateRandom(postId: UUID): ImagePostDatum = ImagePostDatum {
        this.postId = postId
        this.createdAt = Instant.EPOCH
        this.imageUrl = faker.internet.domain()
        this.caption = faker.worldOfWarcraft.quotes()
    }

    fun LoginSession.Companion.generateRandom(userId: UUID): LoginSession = LoginSession {
        this.userId = userId
        createdAt = generateRandomInstant()
        deviceId = faker.unique.toString()
        sessionToken = UUID.randomUUID()
    }

    fun Follower.Companion.generateRandom(userId: UUID, followerId: UUID): Follower = Follower {
        this.userId = userId
        this.followerId = followerId
        this.createdAt = Instant.now()
    }
}
