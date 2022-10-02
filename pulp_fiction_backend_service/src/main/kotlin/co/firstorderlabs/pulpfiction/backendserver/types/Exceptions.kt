package co.firstorderlabs.pulpfiction.backendserver.types

import io.grpc.Status
import io.grpc.StatusException
import java.util.UUID

sealed class PulpFictionError(msgMaybe: String?, causeMaybe: Throwable?) : Throwable(msgMaybe, causeMaybe) {
    constructor(msg: String) : this(msg, null)
    constructor(cause: Throwable) : this(null, cause)
    constructor() : this(null, null)

    abstract fun processError(): Throwable
}

sealed class PulpFictionStartupError(msgMaybe: String?, causeMaybe: Throwable?) :
    PulpFictionError(msgMaybe, causeMaybe) {
    constructor(msg: String) : this(msg, null)
    constructor(cause: Throwable) : this(null, cause)
    constructor() : this(null, null)

    override fun processError(): Throwable = this
}

sealed class PulpFictionRequestError(msgMaybe: String?, causeMaybe: Throwable?) :
    PulpFictionError(msgMaybe, causeMaybe) {
    constructor(msg: String) : this(msg, null)
    constructor(cause: Throwable) : this(null, cause)
    constructor() : this(null, null)

    abstract fun toStatusException(): StatusException

    override fun processError(): Throwable = toStatusException()
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

class UserNotFoundError(userId: String) : PulpFictionRequestError("User $userId not found.") {
    constructor(userId: UUID) : this(userId.toString())

    override fun toStatusException(): StatusException =
        StatusException(Status.NOT_FOUND.withCause(this))
}

class InvalidUserPasswordError() : PulpFictionRequestError() {
    override fun toStatusException(): StatusException =
        StatusException(Status.UNAUTHENTICATED.withCause(this))
}

class PostNotFoundError() : PulpFictionRequestError() {
    override fun toStatusException(): StatusException =
        StatusException(Status.NOT_FOUND.withCause(this))
}

class FunctionalityNotImplementedError() : PulpFictionRequestError() {
    override fun toStatusException(): StatusException =
        StatusException(Status.UNIMPLEMENTED.withCause(this))
}

class ServiceStartupError(cause: Throwable) : PulpFictionStartupError(cause)

class IOError(cause: Throwable) : PulpFictionStartupError(cause)

class AwsError(cause: Throwable) : PulpFictionStartupError(cause)

class DatabaseConnectionError(cause: Throwable) : PulpFictionStartupError(cause)
