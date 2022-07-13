package co.firstorderlabs.pulpfiction.backendserver.monitoring.metrics.metricsstore

import co.firstorderlabs.pulpfiction.backendserver.monitoring.metrics.collectors.LabelName
import co.firstorderlabs.pulpfiction.backendserver.monitoring.metrics.collectors.PulpFictionCounter
import co.firstorderlabs.pulpfiction.backendserver.monitoring.metrics.collectors.PulpFictionSummary

object S3Metrics {
    val s3RequestTotal: PulpFictionCounter = PulpFictionCounter(
        "s3RequestTotal",
        "Measures the total number of requests to s3",
        arrayOf(LabelName.endpointName, LabelName.s3Operation)
    )

    val s3RequestErrorTotal: PulpFictionCounter = PulpFictionCounter(
        "s3RequestErrorTotal",
        "Measures the total number of requests to s3 that result in an error",
        arrayOf(LabelName.endpointName, LabelName.s3Operation, LabelName.cause)
    )

    val s3OperationDurationSeconds: PulpFictionSummary = PulpFictionSummary(
        "s3OperationDurationSeconds",
        "Measures the time taken for an s3 operation",
        arrayOf(LabelName.endpointName, LabelName.s3Operation)
    )
}
