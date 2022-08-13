package co.firstorderlabs.pulpfiction.backendserver.configs

import co.firstorderlabs.pulpfiction.backendserver.types.DatabaseUrl
import co.firstorderlabs.pulpfiction.backendserver.types.KmsKeyId
import co.firstorderlabs.pulpfiction.backendserver.utils.getOrThrow
import java.nio.file.Path
import java.nio.file.Paths

object DatabaseConfigs {
    val databaseUrl: DatabaseUrl = run {
        val connectionProtocol = "jdbc:postgresql"
        val databaseEndpoint = System.getenv().getOrThrow("DATABASE_ENDPOINT")
        val databasePort = 5432
        val databaseName = "pulpfiction_backend_service"
        DatabaseUrl("$connectionProtocol://$databaseEndpoint:$databasePort/$databaseName")
    }
    val ENCRYPTED_CREDENTIALS_FILE: Path =
        Paths.get("/var/pulp_fiction_backend_service/secrets/pulp_fiction_backend_service_database_credentials.json.encrypted")
    val KMS_KEY_ID: KmsKeyId by lazy { KmsKeyId(System.getenv().getOrThrow("KMS_KEY_ID")) }
}
