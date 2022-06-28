package co.firstorderlabs.pulpfiction.backendserver

import co.firstorderlabs.protos.pulpfiction.PulpFictionProtos
import kotlinx.coroutines.flow.flowOf
import org.junit.jupiter.api.Test

internal class PulpFictionBackendServerTest {
    @Test
    fun testGetFeed() {
        val pulpFictionBackendService = PulpFictionBackendServer.PulpFictionBackendService()
        pulpFictionBackendService.getFeed(flowOf(PulpFictionProtos.GetFeedRequest.getDefaultInstance()))
    }
}
