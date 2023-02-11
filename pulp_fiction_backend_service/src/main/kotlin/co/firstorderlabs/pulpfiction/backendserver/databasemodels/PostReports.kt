package co.firstorderlabs.pulpfiction.backendserver.databasemodels

import arrow.core.continuations.Effect
import arrow.core.continuations.effect
import co.firstorderlabs.pulpfiction.backendserver.types.PulpFictionRequestError
import org.ktorm.database.Database
import org.ktorm.dsl.eq
import org.ktorm.dsl.from
import org.ktorm.dsl.joinReferencesAndSelect
import org.ktorm.dsl.map
import org.ktorm.dsl.where
import org.ktorm.entity.Entity
import org.ktorm.entity.sequenceOf
import org.ktorm.schema.Table
import org.ktorm.schema.long
import org.ktorm.schema.timestamp
import org.ktorm.schema.uuid
import org.ktorm.schema.varchar
import java.time.Instant
import java.util.UUID

object PostReports : Table<PostReport>("post_reports") {
    val id = long("id").primaryKey().bindTo { it.id }
    val postId = uuid("post_id").references(Posts) { it.post }
    val updatedAt = timestamp("updated_at").bindTo { it.updatedAt }
    val reportedAt = timestamp("reported_at").bindTo { it.reportedAt }
    val postReporterUserId = uuid("post_reporter_user_id").bindTo { it.postReporterUserId }
    val reportReason = varchar("report_reason").bindTo { it.reportReason }
}

interface PostReport : Entity<PostReport> {
    companion object : Entity.Factory<PostReport>()

    var id: Long
    var post: Post
    var updatedAt: Instant
    var reportedAt: Instant
    var postReporterUserId: UUID
    var reportReason: String
}

val Database.postReports get() = this.sequenceOf(PostReports)

fun Database.getPostReports(postId: UUID): Effect<PulpFictionRequestError, List<PostReport>> =
    effect {
        this@getPostReports
            .from(PostReports)
            .joinReferencesAndSelect()
            .where(PostReports.postId eq postId)
            .map { PostReports.createEntity(it) }
    }
