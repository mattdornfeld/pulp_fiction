package co.firstorderlabs.pulpfiction.backendserver.database.models

import io.github.serpro69.kfaker.Faker
import java.time.Instant
import java.util.UUID
import java.util.concurrent.ThreadLocalRandom
import kotlin.random.Random

object TestDatabaseModelGenerator {
    private val faker = Faker()

    inline fun <reified T : Enum<T>> generateRandomEnumValue(): T {
        val unrecognizedName = "UNRECOGNIZED"
        val enumValues2 = enumValues<T>().filter { !it.name.equals(unrecognizedName) }
        return enumValues2[Random.nextInt(enumValues2.size)]
    }

    fun generateRandomInstant(): Instant {
        return generateRandomInstant(Instant.EPOCH, Instant.now())
    }

    fun generateRandomInstant(start: Instant, end: Instant): Instant {
        val startSeconds = start.epochSecond
        val endSeconds = end.epochSecond
        val random = ThreadLocalRandom
            .current()
            .nextLong(startSeconds, endSeconds)

        return Instant.ofEpochSecond(random)
    }

    fun Post.Companion.generateRandom(): Post {
        return Post {
            post_id = UUID.randomUUID()
            post_state = generateRandomEnumValue()
            created_at = generateRandomInstant()
            post_creator_id = UUID.randomUUID()
            post_type = generateRandomEnumValue()
            post_version = Random.nextInt()
        }
    }

    fun User.Companion.generateRandom(): User {
        return User {
            user_id = UUID.randomUUID()
            display_name = faker.funnyName.name()
            email = faker.internet.email()
            phone_number = faker.phoneNumber.phoneNumber()
            date_of_birth = faker.person.birthDate(30)
            avatar_image_url = faker.internet.domain()
        }
    }
}
