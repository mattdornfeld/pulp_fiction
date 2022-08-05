package co.firstorderlabs.pulpfiction.backendserver.configs

import java.nio.file.Path
import java.nio.file.Paths

object DatabaseConfigs {
    val URL: String = System.getenv("DATABASE_URL") ?: ""
    val ENCRYPTED_CREDENTIALS_FILE: Path =
        Paths.get("/var/pulp_fiction_backend_service/secrets/pulp_fiction_backend_service_database_credentials.json.encrypted")
}
