package co.firstorderlabs.pulpfiction.backendserver

import com.google.common.collect.ImmutableMap
import com.google.common.collect.ImmutableMap.Builder
import com.google.common.flogger.FluentLogger
import com.google.common.flogger.LogSites
import com.google.common.flogger.MetadataKey
import java.nio.file.Path
import java.util.logging.Level

class StructuredLogger(
    private val tagsBuilder: Builder<MetadataKey<String>, String>
) {
    constructor() : this(Builder())

    companion object {
        private val logger: FluentLogger = FluentLogger.forEnclosingClass()

        private object Tags {
            val path: MetadataKey<String> = MetadataKey.single("path", String::class.java)
            val kmsKeyId: MetadataKey<String> = MetadataKey.single("kmsKeyId", String::class.java)
        }

        object TagClasses {
            @JvmInline
            value class KmsKeyId(val kmsKeyId: String)
        }
    }

    private fun buildTags(): ImmutableMap<MetadataKey<String>, String> =
        tagsBuilder.build()

    private fun buildLoggerApi(level: Level): FluentLogger.Api {
        val loggerApi =
            buildTags()
                .entries
                .stream()
                .reduce(
                    logger.at(level),
                    { logger, tag -> logger.with(tag.key, tag.value) },
                    { l1, _ -> l1 })

        return loggerApi
            .withInjectedLogSite(LogSites.callerOf(StructuredLogger::class.java))
    }

    fun withTag(path: Path): StructuredLogger {
        val builder = this.tagsBuilder.put(Tags.path, path.toString())
        return StructuredLogger(builder)
    }

    fun withTag(kmsKeyId: TagClasses.KmsKeyId): StructuredLogger {
        val builder = this.tagsBuilder.put(Tags.kmsKeyId, kmsKeyId.kmsKeyId)
        return StructuredLogger(builder)
    }

    fun info(msg: String) {
        buildLoggerApi(Level.INFO).log(msg)
    }
}