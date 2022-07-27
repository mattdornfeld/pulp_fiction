package co.firstorderlabs.pulpfiction.backendserver.monitoring.metrics.metricsstore

import arrow.core.continuations.Effect
import co.firstorderlabs.pulpfiction.backendserver.monitoring.metrics.collectors.LabelName
import co.firstorderlabs.pulpfiction.backendserver.monitoring.metrics.collectors.LabelValue
import co.firstorderlabs.pulpfiction.backendserver.monitoring.metrics.collectors.PulpFictionCounter
import co.firstorderlabs.pulpfiction.backendserver.monitoring.metrics.collectors.PulpFictionSummary
import co.firstorderlabs.pulpfiction.backendserver.types.PulpFictionError
import co.firstorderlabs.pulpfiction.backendserver.utils.finally
import co.firstorderlabs.pulpfiction.backendserver.utils.onError
import co.firstorderlabs.pulpfiction.backendserver.utils.toLabelValue

object DatabaseMetrics {
    val databaseRequestTotal: PulpFictionCounter = PulpFictionCounter(
        "databaseRequestTotal",
        "Measures the total number of requests to the database",
        arrayOf(LabelName.endpointName, LabelName.databaseOperation)
    )

    val databaseRequestErrorTotal: PulpFictionCounter = PulpFictionCounter(
        "databaseRequestErrorTotal",
        "Measures the total number of requests to the database that result in an error",
        arrayOf(LabelName.endpointName, LabelName.databaseOperation, LabelName.cause)
    )

    val databaseQueryDurationSeconds: PulpFictionSummary = PulpFictionSummary(
        "databaseQueryDurationSeconds",
        "Measures the time taken for a query to the database",
        arrayOf(LabelName.endpointName, LabelName.databaseOperation)
    )

    enum class DatabaseOperation : LabelValue {
        checkLoginSessionValid,
        checkUserPasswordValid,
        createPost,
        createUser,
        login,
        getPost;

        override fun getValue(): String = name
    }

    suspend fun <A> Effect<PulpFictionError, A>.logDatabaseMetrics(
        endpointName: EndpointMetrics.EndpointName,
        databaseOperation: DatabaseOperation
    ): Effect<PulpFictionError, A> {
        val timer = databaseQueryDurationSeconds.withLabels(endpointName, databaseOperation).startTimer()
        databaseRequestTotal.withLabels(endpointName, databaseOperation).inc()
        return this@logDatabaseMetrics
            .onError { databaseRequestErrorTotal.withLabels(endpointName, databaseOperation, it.toLabelValue()).inc() }
            .finally { timer.close() }
    }
}
