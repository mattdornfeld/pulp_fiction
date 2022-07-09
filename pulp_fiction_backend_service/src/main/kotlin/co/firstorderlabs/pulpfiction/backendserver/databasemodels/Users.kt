package co.firstorderlabs.pulpfiction.backendserver.databasemodels

import arrow.core.Either
import arrow.core.Option
import arrow.core.Some
import arrow.core.continuations.either
import arrow.core.none
import co.firstorderlabs.protos.pulpfiction.PulpFictionProtos
import co.firstorderlabs.protos.pulpfiction.PulpFictionProtos.User.SensitiveUserMetadata
import co.firstorderlabs.protos.pulpfiction.PulpFictionProtos.User.UserMetadata
import co.firstorderlabs.protos.pulpfiction.UserKt.sensitiveUserMetadata
import co.firstorderlabs.protos.pulpfiction.UserKt.userMetadata
import co.firstorderlabs.protos.pulpfiction.user
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.types.ReferencesS3Key
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.types.ReferencesS3Key.Companion.JPG
import co.firstorderlabs.pulpfiction.backendserver.types.RequestParsingError
import co.firstorderlabs.pulpfiction.backendserver.utils.toTimestamp
import co.firstorderlabs.pulpfiction.backendserver.utils.toYearMonthDay
import org.ktorm.database.Database
import org.ktorm.entity.Entity
import org.ktorm.entity.sequenceOf
import org.ktorm.schema.Table
import org.ktorm.schema.date
import org.ktorm.schema.timestamp
import org.ktorm.schema.uuid
import org.ktorm.schema.varchar
import java.time.Instant
import java.time.LocalDate
import java.util.UUID

object Users : Table<User>("users") {
    val userId = uuid("user_id").primaryKey().bindTo { it.userId }
    val createdAt = timestamp("created_at").bindTo { it.createdAt }
    val currentDisplayName = varchar("current_display_name").bindTo { it.currentDisplayName }
    val email = varchar("email").bindTo { it.email }
    val phoneNumber = varchar("phone_number").bindTo { it.phoneNumber }
    val dateOfBirth = date("date_of_birth").bindTo { it.dateOfBirth }
    val hashedPassword = varchar("hashed_password").bindTo { it.hashedPassword }
}

interface User : Entity<User>, ReferencesS3Key {
    var userId: UUID
    var createdAt: Instant
    var currentDisplayName: String
    var phoneNumber: String
    var hashedPassword: String
    var email: String?
    var dateOfBirth: LocalDate?

    fun toNonSensitiveUserMetadataProto(): UserMetadata {
        val user = this
        return userMetadata {
            this.userId = user.userId.toString()
            this.createdAt = user.createdAt.toTimestamp()
            this.displayName = user.currentDisplayName
        }
    }

    fun toSensitiveUserMetadataProto(): SensitiveUserMetadata {
        val user = this
        return sensitiveUserMetadata {
            this.nonSensitiveUserMetadata = toNonSensitiveUserMetadataProto()
            this.phoneNumber = phoneNumber
            if (user.email != null) this.email = user.email!!
            if (user.dateOfBirth != null) this.dateOfBirth = user.dateOfBirth!!.toYearMonthDay()
        }
    }

    fun toUserProto(includeSensitiveUserMetadata: Boolean = false): PulpFictionProtos.User = user {
        if (includeSensitiveUserMetadata) {
            this.sensitiveUserMetadata = toSensitiveUserMetadataProto()
        } else {
            this.nonSensitiveUserMetadata = toNonSensitiveUserMetadataProto()
        }
    }

    override fun toS3Key(): String = "$USER_AVATAR_IMAGES_KEY_BASE/${userId}_$createdAt.$JPG"

    companion object : Entity.Factory<User>() {
        enum class TagKey {
            userId,
            postType,
            fileType,
        }

        const val USER_AVATAR_IMAGES_KEY_BASE = "user_avatar_images"

        fun getDateOfBirth(dateOfBirth: String?): Either<RequestParsingError, Option<LocalDate>> {
            if (dateOfBirth == null) {
                return Either.Right(none())
            }

            return try {
                val yearMonthDay = dateOfBirth.split("-").map { it.toInt() }
                val localDateMaybe = Some(LocalDate.of(yearMonthDay[0], yearMonthDay[1], yearMonthDay[2]))
                Either.Right(localDateMaybe)
            } catch (cause: Throwable) {
                Either.Left(RequestParsingError(cause))
            }
        }

        suspend fun generateFromRequest(
            request: PulpFictionProtos.CreateUserRequest
        ): Either<RequestParsingError, User> {
            val dateOfBirth = getDateOfBirth(request.dateOfBirth)
            return either {
                User {
                    this.userId = UUID.randomUUID()
                    this.createdAt = Instant.now()
                    this.currentDisplayName = request.displayName
                    this.phoneNumber = request.phoneNumber
                    this.hashedPassword = ""
                    this.email = request.email
                    this.dateOfBirth = dateOfBirth.bind().orNull()
                }
            }
        }
    }
}

val Database.users get() = this.sequenceOf(Users)
