package co.firstorderlabs.pulpfiction.backendserver.monitoring.metrics.collectors

import arrow.core.None
import arrow.core.Option
import arrow.core.getOrElse
import arrow.core.none
import arrow.core.some
import io.prometheus.client.Summary

class PulpFictionSummary(
    name: String,
    help: String,
    labelNames: LabelNames,
    sampleRate: Double,
    labelValuesMaybe: Option<LabelValues>,
    collectorMaybe: Option<Summary>
) : PulpFictionMetric<Summary, PulpFictionSummary>(name, help, labelNames, sampleRate, labelValuesMaybe) {
    constructor(name: String, help: String, labelNames: Array<LabelName>) : this(
        name,
        help,
        labelNames,
        1.0,
        none(),
        none()
    )

    constructor(name: String, help: String) : this(name, help, emptyArray(), 1.0, none(), none())

    class PulpFictionTimer(private val timerMaybe: Option<Summary.Timer>) : AutoCloseable {
        constructor() : this(None)

        override fun close() {
            timerMaybe.map { it.observeDuration() }
        }
    }

    override val collector: Summary = collectorMaybe.getOrElse {
        Summary
            .build()
            .namespace(namespace)
            .name(name)
            .help(help)
            .labelNames(*labelNames.map { it.name }.toTypedArray())
            .quantile(0.25, 0.01)
            .quantile(0.5, 0.01)
            .quantile(0.75, 0.01)
            .quantile(0.90, 0.01)
            .quantile(0.95, 0.001)
            .quantile(0.99, 0.001)
            .register()
    }

    override fun withLabels(vararg labelValues: LabelValue): PulpFictionSummary =
        PulpFictionSummary(name, help, labelNames, sampleRate, labelValues.asList().some(), collector.some())

    override fun clear() = collector.clear()

    fun observe(value: Double) {
        collector.get().count
        if (shouldSample()) collector
            .labels(*getLabelValuesAsStrings())
            .observe(value)
    }

    fun startTimer(): PulpFictionTimer = if (shouldSample()) {
        val timer = collector
            .labels(*getLabelValuesAsStrings())
            .startTimer()
        PulpFictionTimer(timer.some())
    } else {
        PulpFictionTimer()
    }

    fun get(): Summary.Child.Value = collector.labels(*getLabelValuesAsStrings()).get()
}
