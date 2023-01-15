package co.firstorderlabs.pulpfiction.backendserver.databasemodels

import org.ktorm.database.Database
import org.ktorm.entity.Entity
import org.ktorm.entity.sequenceOf
import org.ktorm.schema.Table
import org.ktorm.schema.uuid
import org.ktorm.schema.varchar
import java.util.UUID

object DisplayNames : Table<DisplayName>("display_names") {
    val userId = uuid("user_id").primaryKey().bindTo { it.userId }
    val currentDisplayName = varchar("current_display_name").bindTo { it.currentDisplayName }
}

interface DisplayName : Entity<DisplayName> {
    companion object : Entity.Factory<DisplayName>()

    var userId: UUID
    var currentDisplayName: String
}

val Database.displayNames get() = this.sequenceOf(DisplayNames)
