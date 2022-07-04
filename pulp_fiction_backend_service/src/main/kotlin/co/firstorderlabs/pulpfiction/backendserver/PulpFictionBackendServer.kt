package co.firstorderlabs.pulpfiction.backendserver

import co.firstorderlabs.pulpfiction.backendserver.configs.DatabaseConfigs
import co.firstorderlabs.pulpfiction.backendserver.configs.ServiceConfigs
import io.grpc.ServerBuilder
import org.ktorm.database.Database
import org.ktorm.support.postgresql.PostgreSqlDialect

class PulpFictionBackendServer(private val port: Int) {
    constructor() : this(ServiceConfigs.SERVICE_PORT)

    companion object {
        fun createDatabaseConnection(): Database {
            return Database.connect(
                url = DatabaseConfigs.URL,
                user = DatabaseConfigs.USER,
                password = DatabaseConfigs.PASSWORD,
                dialect = PostgreSqlDialect(),
            )
        }
    }

    private val server = ServerBuilder
        .forPort(port)
        .addService(PulpFictionBackendService(createDatabaseConnection()))
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

    fun main() {
        PulpFictionBackendServer()
            .start()
            .blockUntilShutdown()
    }
}
