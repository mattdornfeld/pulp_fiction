package co.firstorderlabs.pulpfiction.backendserver.utils

import arrow.core.Either
import arrow.core.Option
import arrow.core.Some
import arrow.core.continuations.Effect
import arrow.core.continuations.effect
import co.firstorderlabs.protos.pulpfiction.PulpFictionProtos
import co.firstorderlabs.protos.pulpfiction.PulpFictionProtos.Post.PostType
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

fun PulpFictionProtos.CreatePostRequest.getPostType(): Either<RequestParsingError, PostType> {
    return if (this.hasCreateCommentRequest()) {
        Either.Right(PostType.COMMENT)
    } else if (this.hasCreateImagePostRequest()) {
        Either.Right(PostType.IMAGE)
    } else {
        Either.Left(RequestParsingError("$this contains unsupported PostType"))
    }
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

/**
 * Runs an effectful computation in a try/catch and transforms any caught errors to the type specified by errorSupplier
 */
suspend fun <R : Throwable, A> effectWithError(
    errorSupplier: (Throwable) -> R,
    f: suspend arrow.core.continuations.EffectScope<R>.() -> A
): Effect<R, A> = effect {
    try {
        f(this)
    } catch (cause: Throwable) {
        shift(errorSupplier(cause))
    }
}

fun LocalDate.toYearMonthDay(): String = DateTimeFormatter.ISO_LOCAL_DATE.format(this)

fun String.toUUID(): Either<RequestParsingError, UUID> =
    Either.catch { UUID.fromString(this) }.mapLeft { RequestParsingError(it) }

fun <A> A.whenThen(condition: (a: A) -> Boolean, operation: (a: A) -> A): A =
    if (condition(this)) operation(this) else this
