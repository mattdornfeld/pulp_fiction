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
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.catch
import kotlinx.coroutines.flow.onCompletion

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

    enum class EndpointName : LabelValue {
        createLoginSession,
        createPost,
        createUser,
        getFeed,
        getPost,
        getUser,
        updateLoginSession,
        updatePost,
        updateUser;

        override fun getValue(): String = name
    }

    suspend fun <A> Effect<PulpFictionRequestError, A>.logEndpointMetrics(
        endpointName: EndpointName,
    ): Effect<PulpFictionRequestError, A> {
        val timer = endpointRequestDurationSeconds.withLabels(endpointName).startTimer()
        endpointRequestTotal.withLabels(endpointName).inc()
        return this@logEndpointMetrics
            .onError { endpointRequestErrorTotal.withLabels(endpointName, it.toLabelValue()).inc() }
            .finally { timer.close() }
    }

    fun <T> Flow<T>.logEndpointMetrics(endpointName: EndpointName): Flow<T> {
        val timer = endpointRequestDurationSeconds.withLabels(endpointName).startTimer()
        endpointRequestTotal.withLabels(endpointName).inc()
        return this@logEndpointMetrics.catch {
            endpointRequestTotal.withLabels(endpointName, it.toLabelValue()).inc()
            throw it
        }
            .onCompletion { timer.close() }
    }
}
