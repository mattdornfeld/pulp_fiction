package co.firstorderlabs.pulpfiction.backendserver.utils

import arrow.core.continuations.Effect
import arrow.core.continuations.effect

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
