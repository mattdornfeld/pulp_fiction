package co.firstorderlabs.pulpfiction.backendserver

import arrow.core.continuations.Effect
import arrow.core.continuations.effect
import co.firstorderlabs.pulpfiction.backendserver.configs.AwsConfigs
import co.firstorderlabs.pulpfiction.backendserver.types.AwsError
import co.firstorderlabs.pulpfiction.backendserver.types.IOError
import co.firstorderlabs.pulpfiction.backendserver.types.KmsKeyId
import co.firstorderlabs.pulpfiction.backendserver.types.PulpFictionStartupError
import co.firstorderlabs.pulpfiction.backendserver.utils.effectWithError
import co.firstorderlabs.pulpfiction.backendserver.utils.flatMap
import co.firstorderlabs.pulpfiction.backendserver.utils.getResultAndThrowException
import co.firstorderlabs.pulpfiction.backendserver.utils.map
import com.fasterxml.jackson.core.type.TypeReference
import com.fasterxml.jackson.databind.ObjectMapper
import com.google.common.io.ByteStreams
import kotlinx.coroutines.runBlocking
import software.amazon.awssdk.core.SdkBytes
import software.amazon.awssdk.services.kms.KmsClient
import software.amazon.awssdk.services.kms.model.DecryptRequest
import software.amazon.awssdk.services.kms.model.DecryptResponse
import software.amazon.awssdk.services.kms.model.EncryptRequest
import software.amazon.awssdk.services.kms.model.EncryptResponse
import java.io.File
import java.io.FileInputStream
import java.io.FileOutputStream
import java.nio.file.Path
import java.nio.file.Paths
import java.util.Base64

class SecretsDecrypter(private val kmsClient: KmsClient) {
    constructor() : this(
        KmsClient
            .builder()
            .region(AwsConfigs.ACCOUNT_REGION)
            .build()
    )

    companion object {
        private val base64Encoder: Base64.Encoder = Base64.getEncoder()
        private val base64Decoder: Base64.Decoder = Base64.getDecoder()
        private val logger: StructuredLogger = StructuredLogger()

        private fun ByteArray.base64Encode(): ByteArray =
            base64Encoder.encode(this)

        private fun ByteArray.base64Decode(): ByteArray =
            base64Decoder.decode(this)

        private suspend fun Path.toByteArray(): Effect<PulpFictionStartupError, ByteArray> =
            effectWithError({ IOError(it) }) {
                val fileInputStream = FileInputStream(this@toByteArray.toFile())
                ByteStreams.toByteArray(fileInputStream)
            }

        private suspend fun Path.toSdkBytes(): Effect<PulpFictionStartupError, SdkBytes> =
            this.toByteArray().map { it.toSdkBytes() }

        private fun ByteArray.toSdkBytes(): SdkBytes =
            SdkBytes.fromByteArray(this)

        private suspend fun SdkBytes.deserializeJsonToMap(): Effect<PulpFictionStartupError, Map<String, String>> =
            effectWithError({ IOError(it) }) {
                ObjectMapper()
                    .readValue(
                        this@deserializeJsonToMap.asByteArray(),
                        object : TypeReference<Map<String, String>>() {}
                    )
            }

        private suspend fun DecryptResponse.deserializeJsonToMap(): Effect<PulpFictionStartupError, Map<String, String>> =
            this.plaintext().deserializeJsonToMap()

        suspend fun File.deserializeJsonToMap(): Effect<PulpFictionStartupError, Map<String, String>> =
            this.toPath().toSdkBytes().flatMap { it.deserializeJsonToMap() }

        private suspend fun EncryptResponse.writeToFile(path: Path): Effect<PulpFictionStartupError, File> =
            effectWithError({ IOError(it) }) {
                val file = path.toFile()
                val fileOutputStream = FileOutputStream(file)
                fileOutputStream.write(this@writeToFile.ciphertextBlob().asByteArray().base64Encode())
                file
            }

        private fun KmsClient.decryptAndHandleError(decryptRequest: DecryptRequest): Effect<PulpFictionStartupError, DecryptResponse> =
            effect {
                try {
                    this@decryptAndHandleError.decrypt(decryptRequest)
                } catch (cause: Throwable) {
                    shift(AwsError(cause))
                }
            }

        private fun KmsClient.encryptAndHandleError(encryptRequest: EncryptRequest): Effect<PulpFictionStartupError, EncryptResponse> =
            effect {
                try {
                    this@encryptAndHandleError.encrypt(encryptRequest)
                } catch (cause: Throwable) {
                    shift(AwsError(cause))
                }
            }

        private fun Path.getEncryptedPath() =
            Paths.get("$this.encrypted")

        enum class Mode {
            encrypt,
            decrypt,
        }

        @JvmStatic
        fun main(args: Array<String>): Unit = runBlocking {
            when (Mode.valueOf(args[0])) {
                Mode.encrypt -> {
                    val credentialsFilePath = Paths.get(args[1])
                    val keyId = args[2]
                    SecretsDecrypter()
                        .encryptJsonCredentialsFileWithKmsKey(KmsKeyId(keyId), credentialsFilePath)
                        .getResultAndThrowException()
                }
                Mode.decrypt -> {
                    val encryptedCredentialsFilePath = Paths.get(args[1])
                    val credentials = SecretsDecrypter()
                        .decryptJsonCredentialsFileWithKmsKey(encryptedCredentialsFilePath)
                        .getResultAndThrowException()
                    println(credentials)
                }
            }
        }
    }

    fun decryptJsonCredentialsFileWithKmsKey(encryptedJsonCredentialsFilePath: Path): Effect<PulpFictionStartupError, Map<String, String>> =
        effect {
            val jsonCredentialsFileAsBytes = encryptedJsonCredentialsFilePath
                .toByteArray()
                .bind()
                .base64Decode()
                .toSdkBytes()

            val decryptRequest = DecryptRequest
                .builder()
                .ciphertextBlob(jsonCredentialsFileAsBytes)
                .build()

            logger
                .withTag(encryptedJsonCredentialsFilePath)
                .withTag(KmsKeyId(decryptRequest.keyId()))
                .info("Decrypting file with KMS key")

            kmsClient
                .decryptAndHandleError(decryptRequest)
                .flatMap { it.deserializeJsonToMap() }
                .bind()
        }

    fun encryptJsonCredentialsFileWithKmsKey(
        kmsKeyId: KmsKeyId,
        jsonCredentialsFilePath: Path
    ): Effect<PulpFictionStartupError, File> = effect {
        val jsonCredentialsFileAsBytes = jsonCredentialsFilePath
            .toByteArray()
            .map { it.toSdkBytes() }
            .bind()

        val encryptRequest = EncryptRequest
            .builder()
            .keyId(kmsKeyId.kmsKeyId)
            .plaintext(jsonCredentialsFileAsBytes)
            .build()

        logger
            .withTag(jsonCredentialsFilePath)
            .withTag(kmsKeyId)
            .info("Encrypting file with KMS key")

        kmsClient
            .encryptAndHandleError(encryptRequest)
            .flatMap { it.writeToFile(jsonCredentialsFilePath.getEncryptedPath()) }
            .bind()
    }
}
