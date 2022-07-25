package co.firstorderlabs.pulpfiction.backendserver.utils

import arrow.core.Either
import arrow.core.Option
import arrow.core.Some
import arrow.core.continuations.Effect
import arrow.core.continuations.effect
import co.firstorderlabs.pulpfiction.backendserver.monitoring.metrics.collectors.StringLabelValue
import co.firstorderlabs.pulpfiction.backendserver.types.PulpFictionError
import co.firstorderlabs.pulpfiction.backendserver.types.RequestParsingError
import com.google.protobuf.Timestamp
import java.time.Instant
import java.time.LocalDate
import java.time.format.DateTimeFormatter
import java.util.UUID

fun <T> List<T>.firstOrOption(): Option<T> {
    return if (isEmpty()) arrow.core.none() else Some(this[0])
}

fun Instant.toTimestamp(): Timestamp {
    return Timestamp
        .newBuilder()
        .setSeconds(this.epochSecond)
        .setNanos(this.nano)
        .build()
}

suspend fun <A> Effect<PulpFictionError, A>.getResultAndHandleErrors(): A {
    return this.fold({ error: PulpFictionError ->
        throw error.toStatusException()
    }
    ) { it }
}

suspend fun <A> Effect<PulpFictionError, A>.onError(block: suspend (PulpFictionError) -> Unit): Effect<PulpFictionError, A> =
    this.handleErrorWith {
        block(it)
        effect { shift(it) }
    }

suspend fun <A> Effect<PulpFictionError, A>.finally(block: suspend () -> Unit): Effect<PulpFictionError, A> =
    this.redeemWith({
        block()
        effect { shift(it) }
    }) {
        block()
        effect { it }
    }

fun LocalDate.toYearMonthDay(): String = DateTimeFormatter.ISO_LOCAL_DATE.format(this)

fun String.toUUID(): Either<RequestParsingError, UUID> =
    Either.catch { UUID.fromString(this) }.mapLeft { RequestParsingError(it) }

fun <A> A.whenThen(condition: (a: A) -> Boolean, operation: (a: A) -> A): A =
    if (condition(this)) operation(this) else this

fun Throwable.toLabelValue(): StringLabelValue = StringLabelValue(this.toString())

fun <A> A.fluentPrintln(prepend: String = ""): A {
    println(prepend + this)
    return this
}
