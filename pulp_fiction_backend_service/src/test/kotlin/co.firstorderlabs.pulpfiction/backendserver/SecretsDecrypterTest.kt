package co.firstorderlabs.pulpfiction.backendserver

import co.firstorderlabs.pulpfiction.backendserver.SecretsDecrypter.Companion.deserializeJsonToMap
import co.firstorderlabs.pulpfiction.backendserver.testutils.KmsContainer
import co.firstorderlabs.pulpfiction.backendserver.testutils.assertEquals
import com.google.common.io.Resources
import org.junit.jupiter.api.Test
import org.testcontainers.containers.localstack.LocalStackContainer
import org.testcontainers.junit.jupiter.Container
import org.testcontainers.junit.jupiter.Testcontainers
import java.io.File
import java.nio.file.StandardCopyOption

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

@Testcontainers
class SecretsDecrypterTest {
    companion object : KmsContainer() {
        @Container
        override val localStackContainer: LocalStackContainer = createLockStackContainer()

        private val secretsDecrypter: SecretsDecrypter by lazy { SecretsDecrypter(kmsClient) }
    }

    @Test
    fun testEncryptionAndDecryption() {
        val keyId = kmsClient.createKey().keyMetadata().keyId()
        val jsonCredentialsFile = ResourceFile("test_credentials.json").toTempFile()
        val encryptedJsonCredentialsFile =
            secretsDecrypter.encryptJsonCredentialsFileWithKmsKey(keyId, jsonCredentialsFile.toPath())
        val credentials = secretsDecrypter.decryptJsonCredentialsFileWithKmsKey(encryptedJsonCredentialsFile.toPath())
        jsonCredentialsFile.assertEquals(credentials) { it.deserializeJsonToMap() }
    }
}
