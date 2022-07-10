package co.firstorderlabs.pulpfiction.backendserver.testutils

import arrow.core.continuations.effect
import co.firstorderlabs.pulpfiction.backendserver.types.PulpFictionError
import co.firstorderlabs.pulpfiction.backendserver.utils.getResultAndHandleErrors
import kotlinx.coroutines.runBlocking

fun <A> runBlockingEffect(f: suspend arrow.core.continuations.EffectScope<PulpFictionError>.() -> A): A = runBlocking {
    effect<PulpFictionError, A> {
        f()
    }.getResultAndHandleErrors()
}
