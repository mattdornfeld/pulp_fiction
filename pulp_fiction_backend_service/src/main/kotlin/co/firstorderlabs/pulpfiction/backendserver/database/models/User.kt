package co.firstorderlabs.pulpfiction.backendserver.database.models

import me.liuwj.ktorm.database.Database
import me.liuwj.ktorm.entity.Entity
import me.liuwj.ktorm.entity.sequenceOf
import me.liuwj.ktorm.schema.Table
import me.liuwj.ktorm.schema.date
import me.liuwj.ktorm.schema.uuid
import me.liuwj.ktorm.schema.varchar
import java.time.LocalDate
import java.util.UUID

interface User : Entity<User> {
    companion object : Entity.Factory<User>()

    var user_id: UUID
    var display_name: String
    var email: String
    var phone_number: String
    var date_of_birth: LocalDate
    var avatar_image_url: String?
}

object Users : Table<User>("users") {
    val user_id = uuid("user_id").primaryKey().bindTo { it.user_id }
    val display_name = varchar("display_name").bindTo { it.display_name }
    val email = varchar("email").bindTo { it.email }
    val phone_number = varchar("phone_number").bindTo { it.phone_number }
    val date_of_birth = date("date_of_birth").bindTo { it.date_of_birth }
    val avatar_image_url = varchar("avatar_image_url").bindTo { it.avatar_image_url }
}

val Database.users get() = this.sequenceOf(Users)
