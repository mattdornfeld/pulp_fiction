package co.firstorderlabs.pulpfiction.backendserver.testutils

import arrow.core.continuations.effect
import co.firstorderlabs.pulpfiction.backendserver.types.PulpFictionRequestError
import co.firstorderlabs.pulpfiction.backendserver.utils.getResultAndHandleErrors
import com.google.common.io.Resources
import kotlinx.coroutines.runBlocking
import java.io.File
import java.nio.file.StandardCopyOption

fun <A> runBlockingEffect(f: suspend arrow.core.continuations.EffectScope<PulpFictionRequestError>.() -> A): A = runBlocking {
    effect<PulpFictionRequestError, A> {
        f()
    }.getResultAndHandleErrors()
}

data class ResourceFile(val fileName: String) {
    fun toTempFile(): File {
        val inputStream = Resources.getResource(fileName).openStream()
        val tempFile = File.createTempFile(fileName.split(".")[0], fileName.split(".")[1])
        java.nio.file.Files.copy(
            inputStream,
            tempFile.toPath(),
            StandardCopyOption.REPLACE_EXISTING
        )

        return tempFile
    }
}
