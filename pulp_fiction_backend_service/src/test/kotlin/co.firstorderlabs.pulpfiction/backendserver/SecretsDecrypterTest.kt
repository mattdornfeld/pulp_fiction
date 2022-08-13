package co.firstorderlabs.pulpfiction.backendserver

import co.firstorderlabs.pulpfiction.backendserver.SecretsDecrypter.Companion.deserializeJsonToMap
import co.firstorderlabs.pulpfiction.backendserver.testutils.KmsContainer
import co.firstorderlabs.pulpfiction.backendserver.testutils.ResourceFile
import co.firstorderlabs.pulpfiction.backendserver.testutils.assertEquals
import co.firstorderlabs.pulpfiction.backendserver.testutils.runBlockingEffect
import co.firstorderlabs.pulpfiction.backendserver.types.PulpFictionStartupError
import org.junit.jupiter.api.Test
import org.testcontainers.containers.localstack.LocalStackContainer
import org.testcontainers.junit.jupiter.Container
import org.testcontainers.junit.jupiter.Testcontainers

@Testcontainers
class SecretsDecrypterTest {
    companion object : KmsContainer() {
        @Container
        override val localStackContainer: LocalStackContainer = createLockStackContainer()

        private val secretsDecrypter: SecretsDecrypter by lazy { SecretsDecrypter(pulpFictionKmsClient.kmsClient) }
    }

    @Test
    fun testEncryptionAndDecryption() =
        runBlockingEffect<PulpFictionStartupError, Unit> {
            val kmsKeyId = pulpFictionKmsClient.createKey().bind()
            val jsonCredentialsFile = ResourceFile("test_credentials.json").toTempFile().bind()
            val encryptedJsonCredentialsFile =
                secretsDecrypter.encryptJsonCredentialsFileWithKmsKey(kmsKeyId, jsonCredentialsFile.toPath()).bind()
            val credentials =
                secretsDecrypter
                    .decryptJsonCredentialsFileWithKmsKey(kmsKeyId, encryptedJsonCredentialsFile.toPath())
                    .bind()
            val expectedCredentials = jsonCredentialsFile.deserializeJsonToMap().bind()
            expectedCredentials.assertEquals(credentials)
        }
}
