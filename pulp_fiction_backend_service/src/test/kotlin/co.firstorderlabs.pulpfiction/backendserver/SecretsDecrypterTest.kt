package co.firstorderlabs.pulpfiction.backendserver

import co.firstorderlabs.pulpfiction.backendserver.SecretsDecrypter.Companion.deserializeJsonToMap
import co.firstorderlabs.pulpfiction.backendserver.testutils.KmsContainer
import co.firstorderlabs.pulpfiction.backendserver.testutils.ResourceFile
import co.firstorderlabs.pulpfiction.backendserver.testutils.assertEquals
import org.junit.jupiter.api.Test
import org.testcontainers.containers.localstack.LocalStackContainer
import org.testcontainers.junit.jupiter.Container
import org.testcontainers.junit.jupiter.Testcontainers

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
