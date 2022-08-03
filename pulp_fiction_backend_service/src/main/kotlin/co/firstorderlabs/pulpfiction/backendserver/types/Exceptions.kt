package co.firstorderlabs.pulpfiction.backendserver.types

import io.grpc.Status
import io.grpc.StatusException

sealed class PulpFictionError(msgMaybe: String?, causeMaybe: Throwable?) : Throwable(msgMaybe, causeMaybe) {
    constructor(msg: String) : this(msg, null)
    constructor(cause: Throwable) : this(null, cause)
    constructor() : this(null, null)

    abstract fun toStatusException(): StatusException
}

class DatabaseError(cause: Throwable) : PulpFictionError(cause) {
    override fun toStatusException(): StatusException =
        StatusException(Status.INTERNAL.withCause(this))
}

class RequestParsingError(msgMaybe: String?, causeMaybe: Throwable?) : PulpFictionError(msgMaybe, causeMaybe) {
    constructor(msg: String) : this(msg, null)
    constructor(cause: Throwable) : this(null, cause)
    constructor() : this(null, null)

    override fun toStatusException(): StatusException =
        StatusException(Status.INVALID_ARGUMENT.withCause(this))
}

class LoginSessionInvalidError() : PulpFictionError() {
    override fun toStatusException(): StatusException =
        StatusException(Status.UNAUTHENTICATED.withCause(this))
}

class S3UploadError(cause: Throwable) : PulpFictionError(cause) {
    override fun toStatusException(): StatusException =
        StatusException(Status.INTERNAL.withCause(this))
}

class S3DownloadError(cause: Throwable) : PulpFictionError(cause) {
    override fun toStatusException(): StatusException =
        StatusException(Status.INTERNAL.withCause(this))
}

class UserNotFoundError(userId: String) : PulpFictionError("User $userId not found.") {
    override fun toStatusException(): StatusException =
        StatusException(Status.NOT_FOUND.withCause(this))
}

class NoUserPostError(userId: String) :
    PulpFictionError("User $userId does not have a matching UserPost.") {
    override fun toStatusException(): StatusException =
        StatusException(Status.NOT_FOUND.withCause(this))
}

class InvalidUserPasswordError() : PulpFictionError() {
    override fun toStatusException(): StatusException =
        StatusException(Status.UNAUTHENTICATED.withCause(this))
}
