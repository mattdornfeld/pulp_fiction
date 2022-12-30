package co.firstorderlabs.pulpfiction.backendserver.configs

import java.time.Duration

object ServiceConfigs {
    const val SERVICE_PORT: Int = 9090
    const val MAX_PAGE_SIZE: Int = 500

    val MAX_AGE_LOGIN_SESSION: Duration = Duration.ofDays(30)
}
