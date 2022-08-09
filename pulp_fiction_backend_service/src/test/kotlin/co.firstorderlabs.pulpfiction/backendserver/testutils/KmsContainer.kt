package co.firstorderlabs.pulpfiction.backendserver.testutils

import co.firstorderlabs.pulpfiction.backendserver.configs.TestConfigs.LOCAL_STACK_IMAGE
import org.testcontainers.containers.localstack.LocalStackContainer

abstract class KmsContainer {
    protected abstract val localStackContainer: LocalStackContainer

    protected fun createLockStackContainer(): LocalStackContainer = LocalStackContainer(LOCAL_STACK_IMAGE)
        .withServices(LocalStackContainer.Service.KMS)

    protected val pulpFictionKmsClient: PulpFictionKmsClient by lazy {
        PulpFictionKmsClient(localStackContainer)
    }
}
