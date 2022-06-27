package co.firstorderlabs.pulpfiction.backendserver

import co.firstorderlabs.protos.pulpfiction.PulpFictionProtos
import kotlinx.coroutines.runBlocking
import org.junit.jupiter.api.Test

internal class PulpFictionBackendServerTest {
    @Test
    fun testGetFeed() {
        val pulpFictionBackendService = PulpFictionBackendServer.PulpFictionBackendService()
        runBlocking {
            pulpFictionBackendService.getFeed(PulpFictionProtos.GetFeedRequest.getDefaultInstance())
        }
    }
}
