package co.firstorderlabs.pulpfiction.backendserver

import co.firstorderlabs.protos.pulpfiction.PulpFictionGrpcKt
import co.firstorderlabs.protos.pulpfiction.PulpFictionProtos
import co.firstorderlabs.protos.pulpfiction.PulpFictionProtos.GetFeedResponse
import co.firstorderlabs.pulpfiction.backendserver.configs.ServiceConfigs
import io.grpc.ServerBuilder
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flow

class PulpFictionBackendServer(private val port: Int) {
    constructor() : this(ServiceConfigs.SERVICE_PORT)

    private val server = ServerBuilder
        .forPort(port)
        .addService(PulpFictionBackendService())
        .build()

    fun start(): PulpFictionBackendServer {
        server.start()
        println("Server started, listening on $port")
        Runtime.getRuntime().addShutdownHook(
            Thread {
                println("*** shutting down gRPC server since JVM is shutting down")
                this@PulpFictionBackendServer.stop()
                println("*** server shut down")
            }
        )

        return this
    }

    private fun stop(): PulpFictionBackendServer {
        server.shutdown()
        return this
    }

    fun blockUntilShutdown(): PulpFictionBackendServer {
        server.awaitTermination()
        return this
    }

    class PulpFictionBackendService : PulpFictionGrpcKt.PulpFictionCoroutineImplBase() {
        override fun getFeed(requests: Flow<PulpFictionProtos.GetFeedRequest>): Flow<GetFeedResponse> = flow {
            emit(GetFeedResponse.getDefaultInstance())
        }
    }

    fun main() {
        PulpFictionBackendServer()
            .start()
            .blockUntilShutdown()
    }
}
