package co.firstorderlabs.pulpfiction.backendserver.testutils

import co.firstorderlabs.pulpfiction.backendserver.utils.nowTruncated
import co.firstorderlabs.pulpfiction.backendserver.utils.toInstant
import com.google.protobuf.ByteString
import com.google.protobuf.Timestamp
import org.junit.jupiter.api.Assertions
import java.time.Duration
import java.time.Instant
import java.util.Random

fun Random.nextByteString(size: Int): ByteString {
    val bytesArray = ByteArray(size)
    this.nextBytes(bytesArray)
    return ByteString.copyFrom(bytesArray)
}

fun Instant.isWithinLast(millis: Long): Boolean {
    val earlierInstant = nowTruncated().minusMillis(millis)
    return Duration.between(earlierInstant, this).toMillis() < millis
}

fun Timestamp.isWithinLast(millis: Long): Boolean = this.toInstant().isWithinLast(millis)

fun ByteArray.toByteString(): ByteString = ByteString.copyFrom(this)

fun <A, B> A.assertEquals(expected: B, actualSupplier: (A) -> B): A {
    Assertions.assertEquals(expected, actualSupplier(this))
    return this
}

fun <A, B> A.assertEquals(expected: B): A {
    Assertions.assertEquals(expected, this)
    return this
}

fun <A, B> A.assertNotEquals(notExpected: B): A {
    Assertions.assertNotEquals(notExpected, this)
    return this
}

fun <A> A.assertTrue(conditionSupplier: (A) -> Boolean): A {
    Assertions.assertTrue(conditionSupplier(this))
    return this
}

fun <A> A.assertFalse(conditionSupplier: (A) -> Boolean): A {
    Assertions.assertFalse(conditionSupplier(this))
    return this
}

fun <A, B> A.assertEquals(msg: String, expected: B, actualSupplier: (A) -> B): A {
    Assertions.assertEquals(expected, actualSupplier(this), msg)
    return this
}

fun <A> A.assertTrue(msg: String, conditionSupplier: (A) -> Boolean): A {
    Assertions.assertTrue(conditionSupplier(this), msg)
    return this
}

class EmptyOptionalError : java.lang.IllegalArgumentException()

fun <A> A?.getOrThrow(): A {
    when (this) {
        null -> throw EmptyOptionalError()
        else -> return this
    }
}
