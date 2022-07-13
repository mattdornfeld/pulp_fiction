package co.firstorderlabs.pulpfiction.backendserver.monitoring.metrics.collectors

import arrow.core.Option
import arrow.core.getOrElse
import arrow.core.none
import arrow.core.some
import io.prometheus.client.Counter

class PulpFictionCounter(
    name: String,
    help: String,
    labelNames: Array<LabelName>,
    sampleRate: Double,
    labelValuesMaybe: Option<LabelValues>,
    collectorMaybe: Option<Counter>
) : PulpFictionMetric<Counter, PulpFictionCounter>(name, help, labelNames, sampleRate, labelValuesMaybe) {
    constructor(name: String, help: String, labelNames: LabelNames) : this(
        name,
        help,
        labelNames,
        1.0,
        none(),
        none()
    )

    constructor(name: String, help: String) : this(name, help, emptyArray(), 1.0, none(), none())

    override val collector: Counter = collectorMaybe.getOrElse {
        Counter
            .build()
            .namespace(namespace)
            .name(name)
            .help(help)
            .labelNames(*labelNames.map { it.name }.toTypedArray())
            .register()
    }

    override fun withLabels(vararg labelValues: LabelValue): PulpFictionCounter =
        PulpFictionCounter(name, help, labelNames, sampleRate, labelValues.asList().some(), collector.some())

    override fun clear() = collector.clear()

    fun inc(value: Double) {
        if (shouldSample()) collector
            .labels(*getLabelValuesAsStrings())
            .inc(value)
    }

    fun inc() = inc(1.0)

    fun get(): Double = collector.labels(*getLabelValuesAsStrings()).get()
}
