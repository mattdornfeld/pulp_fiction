package co.firstorderlabs.pulpfiction.backendserver.databasemodels

import org.ktorm.database.Database
import org.ktorm.entity.Entity
import org.ktorm.entity.sequenceOf
import org.ktorm.schema.Table
import org.ktorm.schema.uuid
import org.ktorm.schema.varchar

object PhoneNumbers : Table<PhoneNumber>("phone_numbers") {
    val userId = uuid("user_id").references(Users) { it.user }
    val phoneNumber = varchar("phone_number").bindTo { it.phoneNumber }
}

interface PhoneNumber : Entity<PhoneNumber> {
    companion object : Entity.Factory<PhoneNumber>()
    var user: User
    var phoneNumber: String
}

val Database.phoneNumbers get() = this.sequenceOf(PhoneNumbers)
