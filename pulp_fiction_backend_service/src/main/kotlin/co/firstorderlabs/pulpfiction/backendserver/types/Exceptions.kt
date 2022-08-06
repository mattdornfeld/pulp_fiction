package co.firstorderlabs.pulpfiction.backendserver.types

import io.grpc.Status
import io.grpc.StatusException

sealed class PulpFictionRequestError(msgMaybe: String?, causeMaybe: Throwable?) : Throwable(msgMaybe, causeMaybe) {
    constructor(msg: String) : this(msg, null)
    constructor(cause: Throwable) : this(null, cause)
    constructor() : this(null, null)

    abstract fun toStatusException(): StatusException
}

class DatabaseError(cause: Throwable) : PulpFictionRequestError(cause) {
    override fun toStatusException(): StatusException =
        StatusException(Status.INTERNAL.withCause(this))
}

class RequestParsingError(msgMaybe: String?, causeMaybe: Throwable?) : PulpFictionRequestError(msgMaybe, causeMaybe) {
    constructor(msg: String) : this(msg, null)
    constructor(cause: Throwable) : this(null, cause)
    constructor() : this(null, null)

    override fun toStatusException(): StatusException =
        StatusException(Status.INVALID_ARGUMENT.withCause(this))
}

class LoginSessionInvalidError() : PulpFictionRequestError() {
    override fun toStatusException(): StatusException =
        StatusException(Status.UNAUTHENTICATED.withCause(this))
}

class S3UploadError(cause: Throwable) : PulpFictionRequestError(cause) {
    override fun toStatusException(): StatusException =
        StatusException(Status.INTERNAL.withCause(this))
}

class S3DownloadError(cause: Throwable) : PulpFictionRequestError(cause) {
    override fun toStatusException(): StatusException =
        StatusException(Status.INTERNAL.withCause(this))
}

class UserNotFoundError(msgMaybe: String) : PulpFictionRequestError(msgMaybe) {
    override fun toStatusException(): StatusException =
        StatusException(Status.UNAUTHENTICATED.withCause(this))
}

class InvalidUserPasswordError() : PulpFictionRequestError() {
    override fun toStatusException(): StatusException =
        StatusException(Status.UNAUTHENTICATED.withCause(this))
}

class ServiceStartupError() : PulpFictionRequestError() {
    override fun toStatusException(): StatusException =
        StatusException(Status.INTERNAL.withCause(this))
}
