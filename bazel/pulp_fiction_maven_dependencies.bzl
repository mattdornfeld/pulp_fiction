load("@rules_jvm_external//:defs.bzl", "maven_install")
load("@io_grpc_grpc_java//:repositories.bzl", "IO_GRPC_GRPC_JAVA_ARTIFACTS")

ARROW_VERSION = "1.1.2"
AWS_SDK_VERSION = "2.17.243"
FLOGGER_VERSION = '0.7.4'
GRPC_VERSION = "1.47.0"
JACKSON_VERSION = "2.13.3"
JUNIT_VERSION = "5.8.2"
KOTLIN_VERSION = "1.6.0"
KTORM_VERSION = "3.5.0"
PROTOBUF_VERSION = "3.18.0"
S3_MOCK_VERSION = "2.4.13"
TEST_CONTAINERS_VERSION = "1.17.2"

PULP_FICTION_MAVEN_DEPENDENCIES = IO_GRPC_GRPC_JAVA_ARTIFACTS + [
    "com.amazonaws:aws-java-sdk-s3:1.11.729",
    "com.google.guava:guava:31.1-jre",
    "com.google.protobuf:protobuf-java:" + PROTOBUF_VERSION,
    "com.google.protobuf:protobuf-kotlin:" + PROTOBUF_VERSION,
    "com.fasterxml.jackson.core:jackson-annotations:" + JACKSON_VERSION,
    "com.fasterxml.jackson.core:jackson-databind:" + JACKSON_VERSION,
    "com.fasterxml.jackson.dataformat:jackson-dataformat-yaml:" + JACKSON_VERSION,
    "com.password4j:password4j:1.6.0",
    "com.squareup:kotlinpoet:1.11.0",
    "io.arrow-kt:arrow-core-jvm:" + ARROW_VERSION,
    "io.arrow-kt:arrow-fx-coroutines-jvm:" + ARROW_VERSION,
    "io.github.serpro69:kotlin-faker:1.11.0",
    "io.grpc:grpc-kotlin-stub:1.3.0",
    "io.grpc:grpc-api:" + GRPC_VERSION,
    "io.grpc:grpc-netty-shaded:" + GRPC_VERSION,
    "io.grpc:grpc-protobuf:" + GRPC_VERSION,
    "io.grpc:grpc-stub:" + GRPC_VERSION,
    "io.prometheus:simpleclient:0.16.0",
    "org.flywaydb:flyway-core:8.5.13",
    "org.jetbrains.kotlin:kotlin-test-junit5:" + KOTLIN_VERSION,
    "org.jetbrains.kotlin:kotlin-test:" + KOTLIN_VERSION,
    "org.jetbrains.kotlinx:kotlinx-coroutines-core-jvm:" + KOTLIN_VERSION,
    "org.jetbrains.kotlinx:kotlinx-coroutines-core:" + KOTLIN_VERSION,
    "org.junit.jupiter:junit-jupiter-api:" + JUNIT_VERSION,
    "org.junit.jupiter:junit-jupiter-engine:" + JUNIT_VERSION,
    "org.junit.jupiter:junit-jupiter:" + JUNIT_VERSION,
    "org.junit.platform:junit-platform-console:1.8.2",
    "org.ktorm:ktorm-core:" + KTORM_VERSION,
    "org.ktorm:ktorm-support-postgresql:" + KTORM_VERSION,
    "org.postgresql:postgresql:42.2.24",
    "org.slf4j:slf4j-api:1.7.36",
    "org.slf4j:slf4j-simple:1.7.36",
    "org.testcontainers:junit-jupiter:" + TEST_CONTAINERS_VERSION,
    "org.testcontainers:postgresql:" + TEST_CONTAINERS_VERSION,
    "org.testcontainers:testcontainers:" + TEST_CONTAINERS_VERSION,
    "org.testcontainers:localstack:" + TEST_CONTAINERS_VERSION,
    "software.amazon.awssdk:apache-client:" + AWS_SDK_VERSION,
    "software.amazon.awssdk:core:" + AWS_SDK_VERSION,
    "software.amazon.awssdk:kms:" + AWS_SDK_VERSION,
    "software.amazon.awssdk:s3:" + AWS_SDK_VERSION,
    "com.google.flogger:flogger-slf4j-backend:" + FLOGGER_VERSION,
    "com.google.flogger:flogger:" + FLOGGER_VERSION,
]
