package co.firstorderlabs.pulpfiction.backendserver

import co.firstorderlabs.pulpfiction.backendserver.configs.AwsConfigs
import com.fasterxml.jackson.core.type.TypeReference
import com.fasterxml.jackson.databind.ObjectMapper
import com.google.common.io.ByteStreams
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

        private fun ByteArray.base64Encode(): ByteArray =
            base64Encoder.encode(this)

        private fun ByteArray.base64Decode(): ByteArray =
            base64Decoder.decode(this)

        private fun Path.toByteArray(): ByteArray {
            val fileInputStream = FileInputStream(this.toFile())
            return ByteStreams.toByteArray(fileInputStream)
        }

        private fun Path.toSdkBytes(): SdkBytes =
            this.toByteArray().toSdkBytes()

        private fun ByteArray.toSdkBytes(): SdkBytes =
            SdkBytes.fromByteArray(this)

        private fun SdkBytes.deserializeJsonToMap(): Map<String, String> =
            ObjectMapper()
                .readValue(
                    this.asByteArray(),
                    object : TypeReference<Map<String, String>>() {}
                )

        private fun DecryptResponse.deserializeJsonToMap(): Map<String, String> =
            this.plaintext().deserializeJsonToMap()

        fun File.deserializeJsonToMap(): Map<String, String> =
            this.toPath().toSdkBytes().deserializeJsonToMap()

        private fun EncryptResponse.writeToFile(path: Path): File {
            val file = path.toFile()
            val fileOutputStream = FileOutputStream(file)
            fileOutputStream.write(this.ciphertextBlob().asByteArray().base64Encode())
            return file
        }

        private fun Path.getEncryptedPath() =
            Paths.get("$this.encrypted")

        enum class Mode {
            encrypt,
            decrypt,
        }

        @JvmStatic
        fun main(args: Array<String>) {
            when (Mode.valueOf(args[0])) {
                Mode.encrypt -> {
                    val credentialsFilePath = Paths.get(args[1])
                    val keyId = args[2]
                    SecretsDecrypter()
                        .encryptJsonCredentialsFileWithKmsKey(keyId, credentialsFilePath)
                }
                Mode.decrypt -> {
                    val encryptedCredentialsFilePath = Paths.get(args[1])
                    val credentials = SecretsDecrypter()
                        .decryptJsonCredentialsFileWithKmsKey(encryptedCredentialsFilePath)
                    println(credentials)
                }
            }
        }
    }

    fun decryptJsonCredentialsFileWithKmsKey(encryptedJsonCredentialsFilePath: Path): Map<String, String> {
        val jsonCredentialsFileAsBytes = encryptedJsonCredentialsFilePath
            .toByteArray()
            .base64Decode()
            .toSdkBytes()

        val decryptRequest = DecryptRequest
            .builder()
            .ciphertextBlob(jsonCredentialsFileAsBytes)
            .build()

        return kmsClient.decrypt(decryptRequest).deserializeJsonToMap()
    }

    fun encryptJsonCredentialsFileWithKmsKey(keyId: String, jsonCredentialsFilePath: Path): File {
        val jsonCredentialsFileAsBytes = jsonCredentialsFilePath
            .toByteArray()
            .toSdkBytes()

        val encryptRequest = EncryptRequest
            .builder()
            .keyId(keyId)
            .plaintext(jsonCredentialsFileAsBytes)
            .build()

        return kmsClient
            .encrypt(encryptRequest)
            .writeToFile(jsonCredentialsFilePath.getEncryptedPath())
    }
}
