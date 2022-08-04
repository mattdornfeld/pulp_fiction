package co.firstorderlabs.pulpfiction.backendserver

import co.firstorderlabs.pulpfiction.backendserver.configs.AwsConfigs
import com.fasterxml.jackson.core.type.TypeReference
import com.fasterxml.jackson.databind.ObjectMapper
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

class SecretsDecrypter(private val kmsClient: KmsClient) {
    constructor() : this(
        KmsClient
            .builder()
            .region(AwsConfigs.ACCOUNT_REGION)
            .build()
    )

    companion object {
        private fun Path.toSdkBytes(): SdkBytes {
            val fileInputStream = FileInputStream(this.toFile())
            return SdkBytes.fromInputStream(fileInputStream)
        }

        private fun SdkBytes.deserializeJsonToMap(): Map<String, String> =
            ObjectMapper()
                .readValue(this.asByteArray(), object : TypeReference<Map<String, String>>() {})

        private fun DecryptResponse.deserializeJsonToMap(): Map<String, String> =
            this.plaintext().deserializeJsonToMap()

        fun File.deserializeJsonToMap(): Map<String, String> =
            this.toPath().toSdkBytes().deserializeJsonToMap()

        private fun EncryptResponse.writeToFile(path: Path): File {
            val file = path.toFile()
            val fileOutputStream = FileOutputStream(file)
            fileOutputStream.write(this.ciphertextBlob().asByteArray())
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
        val decryptRequest = DecryptRequest
            .builder()
            .ciphertextBlob(encryptedJsonCredentialsFilePath.toSdkBytes())
            .build()

        return kmsClient.decrypt(decryptRequest).deserializeJsonToMap()
    }

    fun encryptJsonCredentialsFileWithKmsKey(keyId: String, jsonCredentialsFilePath: Path): File {
        val encryptRequest = EncryptRequest
            .builder()
            .keyId(keyId)
            .plaintext(jsonCredentialsFilePath.toSdkBytes())
            .build()

        return kmsClient
            .encrypt(encryptRequest)
            .writeToFile(jsonCredentialsFilePath.getEncryptedPath())
    }
}
