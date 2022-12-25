package co.firstorderlabs.pulpfiction.backendserver.utils

import arrow.core.Either
import arrow.core.Option
import arrow.core.Some
import arrow.core.continuations.Effect
import arrow.core.continuations.effect
import arrow.core.getOrElse
import co.firstorderlabs.pulpfiction.backendserver.monitoring.metrics.collectors.StringLabelValue
import co.firstorderlabs.pulpfiction.backendserver.types.PulpFictionError
import co.firstorderlabs.pulpfiction.backendserver.types.RequestParsingError
import com.google.protobuf.Timestamp
import java.time.Instant
import java.time.LocalDate
import java.time.ZoneId
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

val UTC_TIMEZONE: ZoneId = ZoneId.of("UTC")

fun LocalDate.toInstant(): Instant {
    return atStartOfDay(UTC_TIMEZONE).toInstant()
}

fun Timestamp.toInstant(): Instant = Instant.ofEpochSecond(this.seconds, this.nanos.toLong())

fun Timestamp.toLocalDate(): LocalDate {
    return this.toInstant().atZone(UTC_TIMEZONE).toLocalDate()
}

suspend fun <A, B : PulpFictionError> Effect<B, A>.getResultAndThrowException(): A {
    return this.fold({ error: B ->
        throw error.processError()
    }
    ) { it }
}

suspend fun <R : PulpFictionError, A> Effect<R, A>.onError(block: suspend (R) -> Unit): Effect<R, A> =
    this.handleErrorWith {
        block(it)
        effect { shift(it) }
    }

suspend fun <R : PulpFictionError, A> Effect<R, A>.finally(block: suspend () -> Unit): Effect<R, A> =
    this.redeemWith({
        block()
        effect { shift(it) }
    }) {
        block()
        effect { it }
    }

suspend fun <R : PulpFictionError, A, B> Effect<R, A>.map(block: suspend (A) -> B): Effect<R, B> =
    this.redeemWith({
        effect { shift(it) }
    }) {
        effect { block(it) }
    }

suspend fun <R : PulpFictionError, A, B> Effect<R, A>.flatMap(block: suspend (A) -> Effect<R, B>): Effect<R, B> =
    this.redeemWith({
        effect { shift(it) }
    }) { block(it) }

fun LocalDate.toYearMonthDay(): String = DateTimeFormatter.ISO_LOCAL_DATE.format(this)

fun String.toUUID(): Either<RequestParsingError, UUID> =
    Either.catch { UUID.fromString(this) }.mapLeft { RequestParsingError(it) }

fun Throwable.toLabelValue(): StringLabelValue = StringLabelValue(this.toString())

fun <A> A.fluentPrintln(prepend: String = ""): A {
    println(prepend + this)
    return this
}

fun <A, B> Map<A, B>.getOrThrow(key: A): B =
    this.getOrElse(key) { throw java.lang.IllegalArgumentException("$key not found in map") }

fun <A> A.whenThen(condition: (a: A) -> Boolean, operation: (a: A) -> A): A =
    if (condition(this)) operation(this) else this

fun <A, B> A.ifDefinedThen(maybeB: Option<B>, block: (a: A, b: B) -> A): A =
    maybeB.map { block(this, it) }.getOrElse { this }
