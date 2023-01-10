package co.firstorderlabs.pulpfiction.backendserver.databasemodels

import arrow.core.Either
import arrow.core.continuations.either
import co.firstorderlabs.protos.pulpfiction.CreateLoginSessionResponseKt.loginSession
import co.firstorderlabs.protos.pulpfiction.CreatePostRequestKt.createUserPostRequest
import co.firstorderlabs.protos.pulpfiction.PulpFictionProtos
import co.firstorderlabs.protos.pulpfiction.PulpFictionProtos.User.UserMetadata
import co.firstorderlabs.protos.pulpfiction.UserKt.sensitiveUserMetadata
import co.firstorderlabs.protos.pulpfiction.UserKt.userMetadata
import co.firstorderlabs.protos.pulpfiction.createPostRequest
import co.firstorderlabs.pulpfiction.backendserver.types.RequestParsingError
import co.firstorderlabs.pulpfiction.backendserver.utils.nowTruncated
import co.firstorderlabs.pulpfiction.backendserver.utils.toInstant
import co.firstorderlabs.pulpfiction.backendserver.utils.toTimestamp
import com.password4j.Password
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
    val userId = uuid("user_id")
        .primaryKey()
        .bindTo { it.userId }
        .references(Emails) { it.email }
        .references(PhoneNumbers) { it.phoneNumber }
    val createdAt = timestamp("created_at").bindTo { it.createdAt }
    val currentDisplayName = varchar("current_display_name").bindTo { it.currentDisplayName }
    val dateOfBirth = date("date_of_birth").bindTo { it.dateOfBirth }
    val hashedPassword = varchar("hashed_password").bindTo { it.hashedPassword }

    val emails get() = userId.referenceTable as Emails
    val phoneNumbers get() = userId.referenceTable as PhoneNumbers
}

interface User : Entity<User> {
    var userId: UUID
    var createdAt: Instant
    var currentDisplayName: String
    var hashedPassword: String
    var dateOfBirth: LocalDate?
    var phoneNumber: PhoneNumber
    var email: Email

    fun toNonSensitiveUserMetadataProto(userPostDatum: UserPostDatum): UserMetadata {
        val user = this
        return userMetadata {
            this.userId = user.userId.toString()
            this.createdAt = user.createdAt.toTimestamp()
            this.displayName = user.currentDisplayName
            userPostDatum.avatarImageS3Key?.let { avatarImageUrl = it }
            this.latestUserPostUpdateIdentifier = userPostDatum.getPostUpdateIdentifier()
        }
    }

    fun toSensitiveUserMetadataProto(userPostDatum: UserPostDatum): PulpFictionProtos.User.SensitiveUserMetadata {
        val user = this
        return sensitiveUserMetadata {
            this.nonSensitiveUserMetadata = toNonSensitiveUserMetadataProto(userPostDatum)
            user.dateOfBirth?.let { this.dateOfBirth = it.toInstant().toTimestamp() }
            this.email = this@User.email.email
            this.phoneNumber = this@User.phoneNumber.phoneNumber
        }
    }

    fun toCreatePostRequest(request: PulpFictionProtos.CreatePostRequest.CreateUserPostRequest): PulpFictionProtos.CreatePostRequest =
        createPostRequest {
            this.loginSession = loginSession {
                this.userId = this@User.userId.toString()
            }
            this.createUserPostRequest = createUserPostRequest {
                this.userId = this@User.userId.toString()
                this.displayName = this@User.currentDisplayName
                this.avatarJpg = request.avatarJpg
                this.bio = request.bio
            }
        }

    companion object : Entity.Factory<User>() {
        suspend fun fromRequest(
            request: PulpFictionProtos.CreateUserRequest
        ): Either<RequestParsingError, User> {
            return either {
                User {
                    this.userId = UUID.randomUUID()
                    this.createdAt = nowTruncated()
                    this.hashedPassword = Password.hash(request.password).withBcrypt().result
                }
            }
        }
    }
}

val Database.users get() = this.sequenceOf(Users)
