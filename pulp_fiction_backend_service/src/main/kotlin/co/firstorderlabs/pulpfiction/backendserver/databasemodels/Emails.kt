package co.firstorderlabs.pulpfiction.backendserver.databasemodels

import org.ktorm.database.Database
import org.ktorm.entity.Entity
import org.ktorm.entity.sequenceOf
import org.ktorm.schema.Table
import org.ktorm.schema.uuid
import org.ktorm.schema.varchar
import java.util.UUID

object Emails : Table<Email>("emails") {
    val userId = uuid("user_id").primaryKey().bindTo { it.userId }
    val email = varchar("email").bindTo { it.email }
}

interface Email : Entity<Email> {
    companion object : Entity.Factory<Email>()
    var userId: UUID
    var email: String
}

val Database.emails get() = this.sequenceOf(Emails)
