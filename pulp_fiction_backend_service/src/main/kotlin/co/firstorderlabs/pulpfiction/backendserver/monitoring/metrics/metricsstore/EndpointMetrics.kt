package co.firstorderlabs.pulpfiction.backendserver.monitoring.metrics.metricsstore

import co.firstorderlabs.pulpfiction.backendserver.PulpFictionBackendService
import co.firstorderlabs.pulpfiction.backendserver.monitoring.metrics.collectors.LabelName
import co.firstorderlabs.pulpfiction.backendserver.monitoring.metrics.collectors.PulpFictionCounter
import co.firstorderlabs.pulpfiction.backendserver.monitoring.metrics.collectors.PulpFictionSummary
import co.firstorderlabs.pulpfiction.backendserver.utils.toLabelValue

object EndpointMetrics {
    val endpointRequestTotal: PulpFictionCounter = PulpFictionCounter(
        "endpointRequestTotal",
        "Measures the total number of requests to an endpoint",
        arrayOf(LabelName.endpointName)
    )

    val endpointRequestErrorTotal: PulpFictionCounter = PulpFictionCounter(
        "endpointRequestErrorTotal",
        "Measures the total number of requests to an endpoint that result in an error",
        arrayOf(LabelName.endpointName, LabelName.cause)
    )

    val endpointRequestDurationSeconds: PulpFictionSummary = PulpFictionSummary(
        "endpointRequestDurationSeconds",
        "Measures the end to end server side endpoint latency",
        arrayOf(LabelName.endpointName)
    )

    suspend fun <R> logEndpointMetrics(endpointName: PulpFictionBackendService.EndpointName, block: suspend () -> R): R {
        return endpointRequestDurationSeconds.withLabels(endpointName).startTimer().use {
            endpointRequestTotal.withLabels(endpointName).inc()
            try {
                block()
            } catch (cause: Throwable) {
                endpointRequestErrorTotal.withLabels(endpointName, cause.toLabelValue()).inc()
                throw cause
            }
        }
    }
}
