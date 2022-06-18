package co.firstorderlabs.pulpfiction

import co.firstorderlabs.protos.pulpfiction.PulpFictionProtos
import kotlinx.coroutines.runBlocking
import org.junit.Test

internal class PulpFictionBackendServerTest {
    @Test
    fun testGetFeed() {
        val pulpFictionBackendService = PulpFictionBackendServer.PulpFictionBackendService()
        runBlocking {
            pulpFictionBackendService.getFeed(PulpFictionProtos.GetFeedRequest.getDefaultInstance())
        }
    }
}
