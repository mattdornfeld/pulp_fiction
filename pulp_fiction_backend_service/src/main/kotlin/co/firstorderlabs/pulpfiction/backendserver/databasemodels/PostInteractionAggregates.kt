package co.firstorderlabs.pulpfiction.backendserver.databasemodels

import co.firstorderlabs.protos.pulpfiction.PostKt.interactionAggregates
import co.firstorderlabs.protos.pulpfiction.PulpFictionProtos
import org.ktorm.database.Database
import org.ktorm.entity.Entity
import org.ktorm.entity.sequenceOf
import org.ktorm.schema.Table
import org.ktorm.schema.long
import org.ktorm.schema.uuid
import java.util.UUID

object PostInteractionAggregates : Table<PostInteractionAggregate>("post_interaction_aggregates") {
    val postId = uuid("post_id").primaryKey().bindTo { it.postId }
    val numLikes = long("num_likes").bindTo { it.numLikes }
    val numDislikes = long("num_dislikes").bindTo { it.numDislikes }
    val numChildComments = long("num_child_comments").bindTo { it.numChildComments }
}

interface PostInteractionAggregate : Entity<PostInteractionAggregate> {
    companion object : Entity.Factory<PostInteractionAggregate>() {
        fun create(postId: UUID): PostInteractionAggregate = PostInteractionAggregate {
            this.postId = postId
            this.numLikes = 0
            this.numDislikes = 0
            this.numChildComments = 0
        }
    }

    var postId: UUID
    var numLikes: Long
    var numDislikes: Long
    var numChildComments: Long

    fun toProto(): PulpFictionProtos.Post.InteractionAggregates = interactionAggregates {
        this.numLikes = numLikes
        this.numDislikes = numDislikes
        this.numChildComments = numChildComments
    }
}

val Database.postInteractionAggregates get() = this.sequenceOf(PostInteractionAggregates)
