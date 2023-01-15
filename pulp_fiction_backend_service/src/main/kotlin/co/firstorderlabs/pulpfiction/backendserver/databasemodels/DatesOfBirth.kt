package co.firstorderlabs.pulpfiction.backendserver.databasemodels

import org.ktorm.database.Database
import org.ktorm.entity.Entity
import org.ktorm.entity.sequenceOf
import org.ktorm.schema.Table
import org.ktorm.schema.date
import org.ktorm.schema.uuid
import java.time.LocalDate
import java.util.UUID

object DatesOfBirth : Table<DateOfBirth>("dates_of_birth") {
    val userId = uuid("user_id").primaryKey().bindTo { it.userId }
    val dateOfBirth = date("date_of_birth").bindTo { it.dateOfBirth }
}

interface DateOfBirth : Entity<DateOfBirth> {
    companion object : Entity.Factory<DateOfBirth>()

    var userId: UUID
    var dateOfBirth: LocalDate
}

val Database.datesOfBirth get() = this.sequenceOf(DatesOfBirth)
