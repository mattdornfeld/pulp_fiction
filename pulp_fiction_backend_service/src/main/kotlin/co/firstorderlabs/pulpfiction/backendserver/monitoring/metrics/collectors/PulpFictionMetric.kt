package co.firstorderlabs.pulpfiction.backendserver.monitoring.metrics.collectors

import arrow.core.Option
import arrow.core.getOrElse
import io.prometheus.client.Collector
import java.util.concurrent.ThreadLocalRandom

enum class LabelName {
    cause,
    databaseOperation,
    endpointName,
    postType,
    s3Operation,
}

interface LabelValue {
    fun getValue(): String
}
typealias LabelNames = Array<LabelName>
typealias LabelValues = List<LabelValue>

class StringLabelValue(private val value: String) : LabelValue {
    override fun getValue(): String = value.take(100)
}

abstract class PulpFictionMetric<A : Collector, B : PulpFictionMetric<A, B>>(
    val name: String,
    protected val help: String,
    val labelNames: LabelNames,
    protected val sampleRate: Double,
    val labelValuesMaybe: Option<LabelValues>,
) {
    companion object {
        private val metricsRegistry: MutableMap<String, PulpFictionMetric<*, *>> = mutableMapOf()

        fun clearRegistry() = metricsRegistry.values.map { it.clear() }
    }

    protected val namespace: String = "pulpfiction"
    protected abstract val collector: A
    init {
        metricsRegistry[name] = this
    }

    protected fun shouldSample(): Boolean = ThreadLocalRandom.current().nextDouble() < sampleRate

    protected fun getLabelValuesAsStrings(): Array<String> =
        labelValuesMaybe
            .map { labelValues -> labelValues.map { it.getValue() }.toTypedArray() }
            .getOrElse { emptyArray() }

    abstract fun withLabels(vararg labelValues: LabelValue): B

    abstract fun clear()
}
