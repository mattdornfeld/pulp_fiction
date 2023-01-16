package co.firstorderlabs.pulpfiction.backendserver.databasemodels.types

import arrow.core.Either
import co.firstorderlabs.protos.pulpfiction.PulpFictionProtos
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.Post
import co.firstorderlabs.pulpfiction.backendserver.databasemodels.PostUpdate
import co.firstorderlabs.pulpfiction.backendserver.types.RequestParsingError
import org.ktorm.entity.Entity
import org.ktorm.schema.Column
import org.ktorm.schema.Table
import java.time.Instant
import java.util.UUID

/**
 * All table models that store post data implement this abstract class
 */
abstract class PostData<A>(tableName: String) : Table<A>(tableName) where A : PostDatum, A : Entity<A> {
    abstract val postId: Column<UUID>
    abstract val updatedAt: Column<Instant>
}

/**
 * All entities associated with a table model that store post data implement this interface
 */
interface PostDatum {
    var post: Post
    var updatedAt: Instant

    fun getPostUpdateIdentifier(): PulpFictionProtos.Post.PostUpdateIdentifier =
        PostUpdate.getPostUpdateIdentifier(post.postId, updatedAt)
}

/**
 * Casts an object that implements PostDatum to the entity type associated with the supplied PostData<A> table. Returns a RequestParsingError if there is a failure.
 */
inline fun <reified A> PostDatum.safeCast(@Suppress("UNUSED_PARAMETER") table: PostData<A>): Either<RequestParsingError, A> where A : PostDatum, A : Entity<A> =
    when (this) {
        is A -> Either.Right(this)
        else -> Either.Left(RequestParsingError("${this::class::simpleName} is not of type ${A::class::simpleName}"))
    }
