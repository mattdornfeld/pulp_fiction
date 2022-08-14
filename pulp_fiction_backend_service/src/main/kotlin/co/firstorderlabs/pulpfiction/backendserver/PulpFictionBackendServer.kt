package co.firstorderlabs.pulpfiction.backendserver

import co.firstorderlabs.pulpfiction.backendserver.configs.ServiceConfigs
import co.firstorderlabs.pulpfiction.backendserver.utils.getResultAndThrowException
import io.grpc.ServerBuilder
import kotlinx.coroutines.runBlocking

class PulpFictionBackendServer(private val port: Int) {
    constructor() : this(ServiceConfigs.SERVICE_PORT)

    companion object {
        private fun createPulpFictionBackendService(): PulpFictionBackendService = runBlocking {
            PulpFictionBackendService(
                DatabaseMessenger.createDatabaseConnection().getResultAndThrowException(),
                S3Messenger.createS3Client()
            )
        }

        @JvmStatic
        fun main(args: Array<String>) {
            PulpFictionBackendServer()
                .start()
                .blockUntilShutdown()
        }
    }

    private val server = ServerBuilder
        .forPort(port)
        .addService(createPulpFictionBackendService())
        .addService(HealthCheckService())
        .build()

    private fun start(): PulpFictionBackendServer {
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

    private fun blockUntilShutdown(): PulpFictionBackendServer {
        server.awaitTermination()
        return this
    }
}
