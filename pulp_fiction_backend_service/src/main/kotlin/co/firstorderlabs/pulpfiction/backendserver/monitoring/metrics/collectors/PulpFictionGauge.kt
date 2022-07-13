package co.firstorderlabs.pulpfiction.backendserver.monitoring.metrics.collectors

import arrow.core.Option
import arrow.core.getOrElse
import arrow.core.none
import arrow.core.some
import io.prometheus.client.Gauge

class PulpFictionGauge(
    name: String,
    help: String,
    labelNames: LabelNames,
    sampleRate: Double,
    labelValuesMaybe: Option<LabelValues>,
    collectorMaybe: Option<Gauge>,
) : PulpFictionMetric<Gauge, PulpFictionGauge>(name, help, labelNames, sampleRate, labelValuesMaybe) {
    constructor(name: String, help: String, labelNames: LabelNames) : this(name, help, labelNames, 1.0, none(), none())
    constructor(name: String, help: String) : this(name, help, emptyArray(), 1.0, none(), none())

    override val collector: Gauge = collectorMaybe.getOrElse {
        Gauge
            .build()
            .namespace(namespace)
            .name(name)
            .help(help)
            .labelNames(*labelNames.map { it.name }.toTypedArray())
            .register()
    }

    override fun withLabels(vararg labelValues: LabelValue): PulpFictionGauge =
        PulpFictionGauge(name, help, labelNames, sampleRate, labelValues.asList().some(), collector.some())

    override fun clear() = collector.clear()

    fun set(value: Double) {
        if (shouldSample()) collector
            .labels(*getLabelValuesAsStrings())
            .set(value)
    }

    fun get(): Double = collector.labels(*getLabelValuesAsStrings()).get()
}
