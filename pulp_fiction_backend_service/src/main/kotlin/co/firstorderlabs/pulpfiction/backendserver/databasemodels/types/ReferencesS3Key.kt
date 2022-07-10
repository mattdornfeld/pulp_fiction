package co.firstorderlabs.pulpfiction.backendserver.databasemodels.types

import software.amazon.awssdk.services.s3.model.Tag
import software.amazon.awssdk.services.s3.model.Tagging

/**
 * All data model Entity objects that reference a s3 key implement this interface
 */
interface ReferencesS3Key {
    companion object {
        const val JPG = "jpg"
    }

    fun toS3Key(): String

    fun tag(key: String, value: String): Tag = Tag
        .builder()
        .key(key)
        .value(value)
        .build()

    fun toTagging(): Tagging

    fun List<Tag>.toTagging(): Tagging = Tagging
        .builder()
        .tagSet(this).build()
}
