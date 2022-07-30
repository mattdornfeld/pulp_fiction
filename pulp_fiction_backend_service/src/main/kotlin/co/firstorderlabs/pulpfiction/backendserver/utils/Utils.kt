package co.firstorderlabs.pulpfiction.backendserver.utils

import arrow.core.continuations.Effect
import arrow.core.continuations.effect
import java.time.Instant
import java.time.temporal.ChronoUnit

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

/**
 * Current Instant truncated to the nearest microsecond. Use this instead of Instant.now()
 * since ktorm sometimes truncates timestamps.
 */
fun nowTruncated(): Instant = Instant.now().truncatedTo(ChronoUnit.MICROS)
