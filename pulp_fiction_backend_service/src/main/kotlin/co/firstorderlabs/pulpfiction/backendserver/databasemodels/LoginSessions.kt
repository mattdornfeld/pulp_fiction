package co.firstorderlabs.pulpfiction.backendserver.databasemodels

import co.firstorderlabs.protos.pulpfiction.CreateLoginSessionResponseKt.loginSession
import co.firstorderlabs.protos.pulpfiction.PulpFictionProtos.CreateLoginSessionRequest
import co.firstorderlabs.protos.pulpfiction.PulpFictionProtos.CreateLoginSessionResponse
import co.firstorderlabs.protos.pulpfiction.PulpFictionProtos.User.UserMetadata
import co.firstorderlabs.pulpfiction.backendserver.utils.nowTruncated
import co.firstorderlabs.pulpfiction.backendserver.utils.toTimestamp
import org.ktorm.database.Database
import org.ktorm.entity.Entity
import org.ktorm.entity.sequenceOf
import org.ktorm.schema.Table
import org.ktorm.schema.long
import org.ktorm.schema.timestamp
import org.ktorm.schema.uuid
import org.ktorm.schema.varchar
import java.time.Instant
import java.util.UUID

object LoginSessions : Table<LoginSession>("login_sessions") {
    val id = long("id").primaryKey().bindTo { it.id }
    val userId = uuid("user_id").bindTo { it.userId }
    val createdAt = timestamp("created_at").bindTo { it.createdAt }
    val deviceId = varchar("device_id").bindTo { it.deviceId }
    val sessionToken = uuid("session_token").bindTo { it.sessionToken }
}

interface LoginSession : Entity<LoginSession> {
    val id: Long
    var userId: UUID
    var createdAt: Instant
    var deviceId: String
    var sessionToken: UUID

    fun toProto(userMetadata: UserMetadata): CreateLoginSessionResponse.LoginSession {
        val loginSession = this
        return loginSession {
            this.userId = loginSession.userId.toString()
            this.createdAt = loginSession.createdAt.toTimestamp()
            this.deviceId = loginSession.deviceId
            this.sessionToken = loginSession.sessionToken.toString()
            this.userMetadata = userMetadata
        }
    }

    companion object : Entity.Factory<LoginSession>() {
        fun fromRequest(user: User, request: CreateLoginSessionRequest): LoginSession =
            LoginSession {
                userId = user.userId
                createdAt = nowTruncated()
                deviceId = request.deviceId
                sessionToken = UUID.randomUUID()
            }
    }
}

val Database.loginSessions get() = this.sequenceOf(LoginSessions)
