package co.firstorderlabs.pulpfiction.backendserver.database

import org.flywaydb.core.Flyway
import org.flywaydb.core.api.configuration.FluentConfiguration

data class MigrateDatabase(val url: String, val user: String, val password: String) {
    companion object {
        private const val MIGRATION_SCRIPTS_DIR = "classpath:db/migrations"
    }

    val fluentConfiguration: FluentConfiguration = Flyway
        .configure()
        .dataSource(url, user, password)
        .locations(MIGRATION_SCRIPTS_DIR)

    fun migrateDatabase(): MigrateDatabase {
        fluentConfiguration
            .locations(MIGRATION_SCRIPTS_DIR)
            .load()
            .migrate()

        return this
    }
}
