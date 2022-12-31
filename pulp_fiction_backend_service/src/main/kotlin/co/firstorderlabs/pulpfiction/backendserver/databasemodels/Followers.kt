package co.firstorderlabs.pulpfiction.backendserver.databasemodels

import arrow.core.Either
import arrow.core.continuations.either
import co.firstorderlabs.protos.pulpfiction.PulpFictionProtos
import co.firstorderlabs.pulpfiction.backendserver.types.RequestParsingError
import co.firstorderlabs.pulpfiction.backendserver.utils.nowTruncated
import co.firstorderlabs.pulpfiction.backendserver.utils.toUUID
import org.ktorm.database.Database
import org.ktorm.entity.Entity
import org.ktorm.entity.sequenceOf
import org.ktorm.schema.Table
import org.ktorm.schema.long
import org.ktorm.schema.timestamp
import org.ktorm.schema.uuid
import java.time.Instant
import java.util.UUID

object Followers : Table<Follower>("followers") {
    val id = long("id").primaryKey().bindTo { it.id }
    val userId = uuid("user_id").bindTo { it.userId }
    val followerId = uuid("follower_id").bindTo { it.followerId }
    val createdAt = timestamp("created_at").bindTo { it.createdAt }
}

interface Follower : Entity<Follower> {
    val id: Long
    var userId: UUID
    var followerId: UUID
    var createdAt: Instant
    companion object : Entity.Factory<Follower>() {
        suspend fun fromRequest(request: PulpFictionProtos.UpdateUserFollowingStatusRequest):
        Either<RequestParsingError, Follower> {
            return either {
                Follower {
                    this.userId = request.loginSession.userId.toUUID().bind()
                    this.followerId = request.userFollowingStatus.targetUserId.toUUID().bind()
                    this.createdAt = nowTruncated()
                }
            }
        }

        fun toProto(): PulpFictionProtos.UpdateUserFollowingStatusResponse {
            return PulpFictionProtos.updateUserFoll
            this.numLikes = numLikes
            this.numDislikes = numDislikes
            this.numChildComments = numChildComments
    }

    }

}

val Database.followers get() = this.sequenceOf(Followers)
