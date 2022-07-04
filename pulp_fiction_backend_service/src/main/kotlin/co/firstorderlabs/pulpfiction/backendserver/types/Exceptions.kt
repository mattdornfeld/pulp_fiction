package co.firstorderlabs.pulpfiction.backendserver.types

import io.grpc.Status
import io.grpc.StatusException

abstract class PulpFictionError(msgMaybe: String?, causeMaybe: Throwable?) : Throwable(msgMaybe, causeMaybe) {
    constructor(msg: String) : this(msg, null)
    constructor(cause: Throwable) : this(null, cause)
    constructor() : this(null, null)

    abstract fun toStatusException(): StatusException
}

class DatabaseError(cause: Throwable) : PulpFictionError(cause) {
    override fun toStatusException(): StatusException {
        return StatusException(Status.INTERNAL.withCause(this))
    }
}

class RequestParsingError(msgMaybe: String?, causeMaybe: Throwable?) : PulpFictionError(msgMaybe, causeMaybe) {
    constructor(msg: String) : this(msg, null)
    constructor(cause: Throwable) : this(null, cause)
    constructor() : this(null, null)

    override fun toStatusException(): StatusException {
        return StatusException(Status.INVALID_ARGUMENT.withCause(this))
    }
}

class LoginSessionInvalidError() : PulpFictionError() {
    override fun toStatusException(): StatusException {
        return StatusException(Status.UNAUTHENTICATED.withCause(this))
    }
}
