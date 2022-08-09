package co.firstorderlabs.pulpfiction.backendserver.testutils

import arrow.core.continuations.Effect
import arrow.core.continuations.effect
import co.firstorderlabs.pulpfiction.backendserver.types.AwsError
import co.firstorderlabs.pulpfiction.backendserver.types.KmsKeyId
import co.firstorderlabs.pulpfiction.backendserver.types.PulpFictionStartupError
import org.testcontainers.containers.localstack.LocalStackContainer
import software.amazon.awssdk.auth.credentials.AwsBasicCredentials
import software.amazon.awssdk.auth.credentials.StaticCredentialsProvider
import software.amazon.awssdk.regions.Region
import software.amazon.awssdk.services.kms.KmsClient

class PulpFictionKmsClient(localStackContainer: LocalStackContainer) {
    val kmsClient: KmsClient = KmsClient.builder()
        .region(Region.of(localStackContainer.region))
        .endpointOverride(localStackContainer.getEndpointOverride(LocalStackContainer.Service.KMS))
        .credentialsProvider(StaticCredentialsProvider.create(AwsBasicCredentials.create("test", "test")))
        .build()

    fun createKey(): Effect<PulpFictionStartupError, KmsKeyId> = effect {
        try {
            KmsKeyId(kmsClient.createKey().keyMetadata().keyId())
        } catch (cause: Throwable) {
            shift(AwsError(cause))
        }
    }
}
