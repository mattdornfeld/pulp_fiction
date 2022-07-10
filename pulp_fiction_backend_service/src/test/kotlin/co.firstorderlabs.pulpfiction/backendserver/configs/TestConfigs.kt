package co.firstorderlabs.pulpfiction.backendserver.configs

import org.testcontainers.utility.DockerImageName

object TestConfigs {
    val POSTGRES_IMAGE: DockerImageName = DockerImageName.parse("postgres:12.9")
    val LOCAL_STACK_IMAGE: DockerImageName = DockerImageName.parse("localstack/localstack:0.11.2")
}
