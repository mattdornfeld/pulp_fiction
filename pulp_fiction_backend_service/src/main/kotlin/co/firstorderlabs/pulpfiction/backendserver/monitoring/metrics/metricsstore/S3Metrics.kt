package co.firstorderlabs.pulpfiction.backendserver.monitoring.metrics.metricsstore

import arrow.core.continuations.Effect
import co.firstorderlabs.pulpfiction.backendserver.monitoring.metrics.collectors.LabelName
import co.firstorderlabs.pulpfiction.backendserver.monitoring.metrics.collectors.LabelValue
import co.firstorderlabs.pulpfiction.backendserver.monitoring.metrics.collectors.PulpFictionCounter
import co.firstorderlabs.pulpfiction.backendserver.monitoring.metrics.collectors.PulpFictionSummary
import co.firstorderlabs.pulpfiction.backendserver.types.PulpFictionRequestError
import co.firstorderlabs.pulpfiction.backendserver.utils.finally
import co.firstorderlabs.pulpfiction.backendserver.utils.onError
import co.firstorderlabs.pulpfiction.backendserver.utils.toLabelValue

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

    val s3RequestDurationSeconds: PulpFictionSummary = PulpFictionSummary(
        "s3RequestDurationSeconds",
        "Measures the time taken for an s3 operation",
        arrayOf(LabelName.endpointName, LabelName.s3Operation)
    )

    enum class S3Operation : LabelValue {
        uploadImagePost,
        uploadUserAvatar;

        override fun getValue(): String = name
    }

    suspend fun <A> Effect<PulpFictionRequestError, A>.logS3Metrics(
        endpointName: EndpointMetrics.EndpointName,
        s3Operation: S3Operation,
    ): Effect<PulpFictionRequestError, A> {
        val timer = s3RequestDurationSeconds.withLabels(endpointName, s3Operation).startTimer()
        s3RequestTotal.withLabels(endpointName, s3Operation).inc()
        return this@logS3Metrics
            .onError { s3RequestErrorTotal.withLabels(endpointName, s3Operation, it.toLabelValue()).inc() }
            .finally { timer.close() }
    }
}
