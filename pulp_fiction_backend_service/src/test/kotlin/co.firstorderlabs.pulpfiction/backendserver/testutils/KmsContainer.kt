package co.firstorderlabs.pulpfiction.backendserver.testutils

import co.firstorderlabs.pulpfiction.backendserver.configs.TestConfigs.LOCAL_STACK_IMAGE
import org.testcontainers.containers.localstack.LocalStackContainer
import software.amazon.awssdk.regions.Region
import software.amazon.awssdk.services.kms.KmsClient

abstract class KmsContainer {
    protected abstract val localStackContainer: LocalStackContainer

    protected fun createLockStackContainer(): LocalStackContainer = LocalStackContainer(LOCAL_STACK_IMAGE)
        .withServices(LocalStackContainer.Service.KMS)

    protected val kmsClient: KmsClient by lazy {
        return@lazy KmsClient.builder()
            .region(Region.of(localStackContainer.region))
            .endpointOverride(localStackContainer.getEndpointOverride(LocalStackContainer.Service.KMS))
            .build()
    }
}