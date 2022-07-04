package co.firstorderlabs.pulpfiction.backendserver.testutils

import com.google.protobuf.ByteString
import com.google.protobuf.Timestamp
import java.time.Duration
import java.time.Instant
import java.util.Random

fun Random.nextByteString(size: Int): ByteString {
    val bytesArray = ByteArray(size)
    this.nextBytes(bytesArray)
    return ByteString.copyFrom(bytesArray)
}

fun Timestamp.toInstant(): Instant = Instant.ofEpochSecond(this.seconds, this.nanos.toLong())

fun Instant.isWithinLast(millis: Long): Boolean {
    val earlierInstant = Instant.now().minusMillis(millis)
    return Duration.between(earlierInstant, this).toMillis() < millis
}

fun Timestamp.isWithinLast(millis: Long): Boolean = this.toInstant().isWithinLast(millis)
