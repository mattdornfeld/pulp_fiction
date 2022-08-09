package co.firstorderlabs.pulpfiction.backendserver.testutils

import arrow.core.continuations.Effect
import arrow.core.continuations.effect
import co.firstorderlabs.pulpfiction.backendserver.types.IOError
import co.firstorderlabs.pulpfiction.backendserver.types.PulpFictionError
import co.firstorderlabs.pulpfiction.backendserver.types.PulpFictionStartupError
import co.firstorderlabs.pulpfiction.backendserver.utils.effectWithError
import co.firstorderlabs.pulpfiction.backendserver.utils.getResultAndThrowException
import com.google.common.io.Resources
import kotlinx.coroutines.runBlocking
import java.io.File
import java.nio.file.StandardCopyOption

fun <R : PulpFictionError, A> runBlockingEffect(f: suspend arrow.core.continuations.EffectScope<R>.() -> A): A =
    runBlocking {
        effect<R, A> {
            f()
        }.getResultAndThrowException()
    }

data class ResourceFile(val fileName: String) {
    suspend fun toTempFile(): Effect<PulpFictionStartupError, File> = effectWithError({ IOError(it) }) {
        val inputStream = Resources.getResource(fileName).openStream()
        val tempFile = File.createTempFile(fileName.split(".")[0], fileName.split(".")[1])
        java.nio.file.Files.copy(
            inputStream,
            tempFile.toPath(),
            StandardCopyOption.REPLACE_EXISTING
        )

        tempFile
    }
}
