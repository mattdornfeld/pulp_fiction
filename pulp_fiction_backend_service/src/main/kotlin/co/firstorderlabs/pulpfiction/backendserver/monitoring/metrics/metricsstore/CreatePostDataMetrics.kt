package co.firstorderlabs.pulpfiction.backendserver.monitoring.metrics.metricsstore

import arrow.core.continuations.Effect
import co.firstorderlabs.protos.pulpfiction.PulpFictionProtos.Post.PostType
import co.firstorderlabs.pulpfiction.backendserver.monitoring.metrics.collectors.LabelName
import co.firstorderlabs.pulpfiction.backendserver.monitoring.metrics.collectors.LabelValue
import co.firstorderlabs.pulpfiction.backendserver.monitoring.metrics.collectors.PulpFictionCounter
import co.firstorderlabs.pulpfiction.backendserver.monitoring.metrics.collectors.PulpFictionSummary
import co.firstorderlabs.pulpfiction.backendserver.types.PulpFictionError
import co.firstorderlabs.pulpfiction.backendserver.utils.finally
import co.firstorderlabs.pulpfiction.backendserver.utils.onError
import co.firstorderlabs.pulpfiction.backendserver.utils.toLabelValue

object CreatePostDataMetrics {
    val createPostDataTotal: PulpFictionCounter = PulpFictionCounter(
        "createPostDataTotal",
        "Measures the total number of CreatePost requests",
        arrayOf(LabelName.postType)
    )

    val createPostDataErrorTotal: PulpFictionCounter = PulpFictionCounter(
        "createPostDataErrorTotal",
        "Measures the total number of CreatePost requests that result in an error",
        arrayOf(LabelName.postType, LabelName.cause)
    )

    val createPostDataDurationSeconds: PulpFictionSummary = PulpFictionSummary(
        "createPostDataDurationSeconds",
        "Measures the latency create the post data for a request",
        arrayOf(LabelName.postType)
    )

    class PostTypeLabelValue(private val postType: PostType) :
        LabelValue {
        override fun getValue(): String = postType.name
    }

    fun PostType.toLabelValue(): PostTypeLabelValue = PostTypeLabelValue(this)

    suspend fun <A> Effect<PulpFictionError, A>.logCreatePostDataMetrics(
        postType: PostType,
    ): Effect<PulpFictionError, A> {
        val postTypeLabelValue = postType.toLabelValue()
        val timer = createPostDataDurationSeconds.withLabels(postTypeLabelValue).startTimer()
        createPostDataTotal.withLabels(postTypeLabelValue).inc()
        return this@logCreatePostDataMetrics
            .onError { createPostDataErrorTotal.withLabels(postTypeLabelValue, it.toLabelValue()).inc() }
            .finally { timer.close() }
    }
}
