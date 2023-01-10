package co.firstorderlabs.pulpfiction.backendserver.databasemodels

import org.ktorm.database.Database
import org.ktorm.entity.Entity
import org.ktorm.entity.sequenceOf
import org.ktorm.schema.Table
import org.ktorm.schema.uuid
import org.ktorm.schema.varchar

object Emails : Table<Email>("emails") {
    val userId = uuid("user_id").references(Users) { it.user }
    val email = varchar("email").bindTo { it.email }
}

interface Email : Entity<Email> {
    companion object : Entity.Factory<Email>()
    var user: User
    var email: String
}

val Database.emails get() = this.sequenceOf(Emails)
