package co.firstorderlabs.pulpfiction.backendserver.monitoring.metrics.metricsstore

import co.firstorderlabs.pulpfiction.backendserver.monitoring.metrics.collectors.LabelName
import co.firstorderlabs.pulpfiction.backendserver.monitoring.metrics.collectors.PulpFictionCounter
import co.firstorderlabs.pulpfiction.backendserver.monitoring.metrics.collectors.PulpFictionSummary

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
}
