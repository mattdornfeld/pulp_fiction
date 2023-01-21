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
import org.ktorm.dsl.eq
import org.ktorm.dsl.from
import org.ktorm.dsl.leftJoin
import org.ktorm.dsl.map
import org.ktorm.dsl.select
import org.ktorm.dsl.where
import org.ktorm.entity.Entity
import org.ktorm.entity.sequenceOf
import org.ktorm.schema.ColumnDeclaring
import org.ktorm.schema.Table
import org.ktorm.schema.timestamp
import org.ktorm.schema.uuid
import org.ktorm.schema.varchar
import java.time.Instant
import java.util.UUID

object Users : Table<User>("users") {
    val userId = uuid("user_id")
        .primaryKey()
        .bindTo { it.userId }
        .references(Emails) { it.email }
        .references(PhoneNumbers) { it.phoneNumber }
        .references(DisplayNames) { it.displayName }
        .references(DatesOfBirth) { it.dateOfBirth }
    val createdAt = timestamp("created_at").bindTo { it.createdAt }
    val hashedPassword = varchar("hashed_password").bindTo { it.hashedPassword }

    fun select(database: Database, condition: () -> ColumnDeclaring<Boolean>): User? =
        database
            .from(this)
            .leftJoin(Emails, on = userId eq Emails.userId)
            .leftJoin(PhoneNumbers, on = userId eq PhoneNumbers.userId)
            .leftJoin(DisplayNames, on = userId eq DisplayNames.userId)
            .leftJoin(DatesOfBirth, on = userId eq DatesOfBirth.userId)
            .select()
            .where(condition)
            .map { Users.createEntity(it) }
            .firstOrNull()
}

interface User : Entity<User> {
    var userId: UUID
    var createdAt: Instant
    var hashedPassword: String
    var phoneNumber: PhoneNumber
    var email: Email
    var displayName: DisplayName
    var dateOfBirth: DateOfBirth

    fun toNonSensitiveUserMetadataProto(userPostDatum: UserPostDatum): UserMetadata {
        return userMetadata {
            this.userId = this@User.userId.toString()
            this.createdAt = this@User.createdAt.toTimestamp()
            this.displayName = userPostDatum.displayName
            userPostDatum.avatarImageS3Key?.let { avatarImageUrl = it }
            this.bio = userPostDatum.bio
            this.latestUserPostUpdateIdentifier = userPostDatum.getPostUpdateIdentifier()
        }
    }

    fun toNonSensitiveUserMetadataProto(): UserMetadata {
        return userMetadata {
            this.userId = this@User.userId.toString()
            this.createdAt = this@User.createdAt.toTimestamp()
        }
    }

    fun toSensitiveUserMetadataProto(userPostDatum: UserPostDatum): PulpFictionProtos.User.SensitiveUserMetadata {
        val user = this
        return sensitiveUserMetadata {
            this.nonSensitiveUserMetadata = toNonSensitiveUserMetadataProto(userPostDatum)
            this.dateOfBirth = user.dateOfBirth.dateOfBirth.toInstant().toTimestamp()
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
                this.displayName = this@User.displayName.currentDisplayName
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
