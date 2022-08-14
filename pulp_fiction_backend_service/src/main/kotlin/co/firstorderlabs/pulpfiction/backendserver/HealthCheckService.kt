package co.firstorderlabs.pulpfiction.backendserver

import io.grpc.health.v1.HealthCheckRequest
import io.grpc.health.v1.HealthCheckResponse
import io.grpc.health.v1.HealthGrpcKt
import io.grpc.health.v1.healthCheckResponse
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flow

class HealthCheckService : HealthGrpcKt.HealthCoroutineImplBase() {
    override suspend fun check(request: HealthCheckRequest): HealthCheckResponse = healthCheckResponse {
        this.status = HealthCheckResponse.ServingStatus.SERVING
    }

    override fun watch(request: HealthCheckRequest): Flow<HealthCheckResponse> = flow {
        while (true) {
            emit(check(request))
            delay(500)
        }
    }
}
