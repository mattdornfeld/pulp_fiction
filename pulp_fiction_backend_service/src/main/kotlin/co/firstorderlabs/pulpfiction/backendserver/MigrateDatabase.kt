package co.firstorderlabs.pulpfiction.backendserver

import org.flywaydb.core.Flyway
import org.flywaydb.core.api.configuration.FluentConfiguration

data class MigrateDatabase(val url: String, val user: String, val password: String) {
    companion object {
        private const val MIGRATION_SCRIPTS_DIR = "classpath:db/migrations"
    }

    private val fluentConfiguration: FluentConfiguration = Flyway
        .configure()
        .dataSource(url, user, password)
        .locations(MIGRATION_SCRIPTS_DIR)
        .mixed(true)

    fun migrateDatabase(): MigrateDatabase {
        fluentConfiguration
            .locations(MIGRATION_SCRIPTS_DIR)
            .load()
            .migrate()

        return this
    }
}
