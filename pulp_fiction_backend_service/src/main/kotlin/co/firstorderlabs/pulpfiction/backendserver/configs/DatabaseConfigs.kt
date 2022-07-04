package co.firstorderlabs.pulpfiction.backendserver.configs

object DatabaseConfigs {
    val URL: String = System.getenv("DATABASE_URL") ?: ""
    val USER: String = System.getenv("DATABASE_PASSWORD") ?: ""
    val PASSWORD: String = System.getenv("PASSWORD") ?: ""
}
