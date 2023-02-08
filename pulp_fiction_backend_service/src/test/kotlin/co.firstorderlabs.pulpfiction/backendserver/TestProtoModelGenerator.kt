package co.firstorderlabs.pulpfiction.backendserver

import co.firstorderlabs.protos.pulpfiction.CreateLoginSessionRequestKt.phoneNumberLogin
import co.firstorderlabs.protos.pulpfiction.CreateLoginSessionResponseKt.loginSession
import co.firstorderlabs.protos.pulpfiction.CreatePostRequestKt.createCommentRequest
import co.firstorderlabs.protos.pulpfiction.CreatePostRequestKt.createImagePostRequest
import co.firstorderlabs.protos.pulpfiction.CreatePostRequestKt.createUserPostRequest
import co.firstorderlabs.protos.pulpfiction.CreateUserRequestKt.phoneNumberVerification
import co.firstorderlabs.protos.pulpfiction.GetFeedRequestKt.getCommentFeedRequest
import co.firstorderlabs.protos.pulpfiction.GetFeedRequestKt.getFollowingPostFeedRequest
import co.firstorderlabs.protos.pulpfiction.GetFeedRequestKt.getGlobalPostFeedRequest
import co.firstorderlabs.protos.pulpfiction.GetFeedRequestKt.getUserPostFeedRequest
import co.firstorderlabs.protos.pulpfiction.PulpFictionProtos
import co.firstorderlabs.protos.pulpfiction.PulpFictionProtos.CreateLoginSessionResponse.LoginSession
import co.firstorderlabs.protos.pulpfiction.PulpFictionProtos.CreatePostRequest
import co.firstorderlabs.protos.pulpfiction.PulpFictionProtos.CreatePostRequest.CreateCommentRequest
import co.firstorderlabs.protos.pulpfiction.PulpFictionProtos.CreatePostRequest.CreateImagePostRequest
import co.firstorderlabs.protos.pulpfiction.PulpFictionProtos.CreatePostRequest.CreateUserPostRequest
import co.firstorderlabs.protos.pulpfiction.PulpFictionProtos.CreateUserRequest
import co.firstorderlabs.protos.pulpfiction.PulpFictionProtos.GetFeedRequest
import co.firstorderlabs.protos.pulpfiction.PulpFictionProtos.Post.PostMetadata
import co.firstorderlabs.protos.pulpfiction.PulpFictionProtos.UpdatePostRequest
import co.firstorderlabs.protos.pulpfiction.PulpFictionProtos.UpdateUserRequest
import co.firstorderlabs.protos.pulpfiction.UpdatePostRequestKt.deletePost
import co.firstorderlabs.protos.pulpfiction.UpdatePostRequestKt.updateComment
import co.firstorderlabs.protos.pulpfiction.UpdatePostRequestKt.updateImagePost
import co.firstorderlabs.protos.pulpfiction.UpdateUserRequestKt.UpdateSensitiveUserMetadataKt.updateDateOfBirth
import co.firstorderlabs.protos.pulpfiction.UpdateUserRequestKt.UpdateSensitiveUserMetadataKt.updateEmail
import co.firstorderlabs.protos.pulpfiction.UpdateUserRequestKt.UpdateSensitiveUserMetadataKt.updatePhoneNumber
import co.firstorderlabs.protos.pulpfiction.UpdateUserRequestKt.UpdateUserMetadataKt.updateBio
import co.firstorderlabs.protos.pulpfiction.UpdateUserRequestKt.UpdateUserMetadataKt.updateDisplayName
import co.firstorderlabs.protos.pulpfiction.UpdateUserRequestKt.UpdateUserMetadataKt.updateUserAvatar
import co.firstorderlabs.protos.pulpfiction.UpdateUserRequestKt.updatePassword
import co.firstorderlabs.protos.pulpfiction.UpdateUserRequestKt.updateSensitiveUserMetadata
import co.firstorderlabs.protos.pulpfiction.UpdateUserRequestKt.updateUserFollowingStatus
import co.firstorderlabs.protos.pulpfiction.UpdateUserRequestKt.updateUserMetadata
import co.firstorderlabs.protos.pulpfiction.createLoginSessionRequest
import co.firstorderlabs.protos.pulpfiction.createPostRequest
import co.firstorderlabs.protos.pulpfiction.createUserRequest
import co.firstorderlabs.protos.pulpfiction.getFeedRequest
import co.firstorderlabs.protos.pulpfiction.getPostRequest
import co.firstorderlabs.protos.pulpfiction.updatePostRequest
import co.firstorderlabs.protos.pulpfiction.updateUserRequest
import co.firstorderlabs.pulpfiction.backendserver.testutils.nextByteString
import co.firstorderlabs.pulpfiction.backendserver.utils.nowTruncated
import co.firstorderlabs.pulpfiction.backendserver.utils.toInstant
import co.firstorderlabs.pulpfiction.backendserver.utils.toTimestamp
import io.github.serpro69.kfaker.Faker
import java.util.Random
import java.util.UUID

object TestProtoModelGenerator {
    val faker = Faker()
    private val random = Random()

    fun generateRandomLoginSession(): PulpFictionProtos.CreateLoginSessionResponse.LoginSession = loginSession {
        this.sessionToken = UUID.randomUUID().toString()
        this.userId = UUID.randomUUID().toString()
        this.createdAt = nowTruncated().toTimestamp()
    }

    fun generateRandomCreateUserRequest(): CreateUserRequest = createUserRequest {
        this.password = faker.unique.toString()
        this.phoneNumberVerification = phoneNumberVerification {
            this.phoneNumber = faker.phoneNumber.phoneNumber()
        }
    }

    fun generateRandomLoginRequest(phoneNumber: String, password: String): PulpFictionProtos.CreateLoginSessionRequest =
        createLoginSessionRequest {
            this.deviceId = faker.unique.toString()
            this.password = password
            this.phoneNumberLogin = phoneNumberLogin {
                this.phoneNumber = phoneNumber
            }
        }

    fun generateRandomCreateCommentRequest(parentPostId: String): CreateCommentRequest = createCommentRequest {
        this.body = faker.lovecraft.unique.toString()
        this.parentPostId = parentPostId
    }

    fun generateRandomCreateImagePostRequest(): CreateImagePostRequest = createImagePostRequest {
        this.caption = faker.lovecraft.unique.toString()
        this.imageJpg = random.nextByteString(100)
    }

    fun generateRandomCreateUserPostRequest(loginSession: LoginSession): CreateUserPostRequest =
        createUserPostRequest {
            this.userId = loginSession.userId.toString()
            this.displayName = faker.name.firstName()
            this.avatarJpg = random.nextByteString(100)
        }

    fun generateRandomUpdateDisplayNameRequest(loginSession: LoginSession): UpdateUserRequest =
        updateUserRequest {
            this.loginSession = loginSession
            this.updateUserMetadata = updateUserMetadata {
                this.updateDisplayName = updateDisplayName {
                    this.newDisplayName = faker.name.firstName()
                }
            }
        }

    fun generateRandomUpdateBioRequest(loginSession: LoginSession): UpdateUserRequest =
        updateUserRequest {
            this.loginSession = loginSession
            this.updateUserMetadata = updateUserMetadata {
                this.updateBio = updateBio {
                    this.newBio = faker.lovecraft.unique.toString()
                }
            }
        }

    fun generateRandomUpdateUserAvatarRequest(loginSession: LoginSession): UpdateUserRequest =
        updateUserRequest {
            this.loginSession = loginSession
            this.updateUserMetadata = updateUserMetadata {
                this.updateUserAvatar = updateUserAvatar {
                    this.avatarJpg = random.nextByteString(100)
                }
            }
        }

    fun generateRandomUpdateDateOfBirthRequest(loginSession: LoginSession): UpdateUserRequest =
        updateUserRequest {
            this.loginSession = loginSession
            this.updateSensitiveUserMetadata = updateSensitiveUserMetadata {
                this.updateDateOfBirth = updateDateOfBirth {
                    this.newDateOfBirth = faker.person.birthDate(31).toInstant().toTimestamp()
                }
            }
        }

    fun generateRandomUpdateEmailRequest(loginSession: LoginSession): UpdateUserRequest = updateUserRequest {
        this.loginSession = loginSession
        this.updateSensitiveUserMetadata = updateSensitiveUserMetadata {
            this.updateEmail = updateEmail {
                this.newEmail = faker.internet.email()
            }
        }
    }

    fun generateRandomUpdatePhoneNumberRequest(loginSession: LoginSession): UpdateUserRequest = updateUserRequest {
        this.loginSession = loginSession
        this.updateSensitiveUserMetadata = updateSensitiveUserMetadata {
            this.updatePhoneNumber = updatePhoneNumber {
                this.newPhoneNumber = faker.phoneNumber.cellPhone()
            }
        }
    }

    fun generateRandomUpdateUserFollowingStatusRequest(
        loginSession: LoginSession,
        targetUserId: String,
        following: Boolean
    ): UpdateUserRequest =
        updateUserRequest {
            val userFollowingStatus = if (!following)
                UpdateUserRequest.UpdateUserFollowingStatus.UserFollowingStatus.NOT_FOLLOWING
            else UpdateUserRequest.UpdateUserFollowingStatus.UserFollowingStatus.FOLLOWING

            this.loginSession = loginSession
            this.updateUserFollowingStatus = updateUserFollowingStatus {
                this.userFollowingStatus = userFollowingStatus
                this.targetUserId = targetUserId
            }
        }

    fun generateRandomUpdatePasswordRequest(loginSession: LoginSession, currentPassword: String): UpdateUserRequest =
        updateUserRequest {
            this.loginSession = loginSession
            this.updatePassword = updatePassword {
                this.oldPassword = currentPassword
                this.newPassword = faker.unique.toString()
            }
        }

    fun generateRandomGetFollowingPostFeedRequest(loginSession: LoginSession): GetFeedRequest = getFeedRequest {
        this.loginSession = loginSession
        this.getFollowingPostFeedRequest = getFollowingPostFeedRequest {
            this.userId = loginSession.userId
        }
    }

    fun generateRandomGetGlobalPostFeedRequest(loginSession: LoginSession): GetFeedRequest = getFeedRequest {
        this.loginSession = loginSession
        this.getGlobalPostFeedRequest = getGlobalPostFeedRequest {
        }
    }

    fun generateRandomGetUserPostFeedRequest(loginSession: LoginSession, userId: String): GetFeedRequest =
        getFeedRequest {
            this.loginSession = loginSession
            this.getUserPostFeedRequest = getUserPostFeedRequest { this.userId = userId }
        }

    fun generateRandomGetCommentFeedRequest(loginSession: LoginSession, postId: String): GetFeedRequest =
        getFeedRequest {
            this.loginSession = loginSession
            this.getCommentFeedRequest = getCommentFeedRequest { this.postId = postId }
        }

    fun LoginSession.generateRandomCreatePostRequest(): CreatePostRequest = createPostRequest {
        this.loginSession = this@generateRandomCreatePostRequest
        this.createImagePostRequest = generateRandomCreateImagePostRequest()
    }

    fun CreatePostRequest.withRandomCreateUserPostRequest(): CreatePostRequest {
        val builder = this.toBuilder()
        builder.createUserPostRequest = generateRandomCreateUserPostRequest(this.loginSession)
        return builder.build()
    }

    fun CreatePostRequest.withRandomCreateImagePostRequest(): CreatePostRequest {
        val builder = this.toBuilder()
        builder.createImagePostRequest = generateRandomCreateImagePostRequest()
        return builder.build()
    }

    fun CreatePostRequest.withRandomCreateCommentRequest(parentPostId: String): CreatePostRequest {
        val builder = this.toBuilder()
        builder.createCommentRequest = generateRandomCreateCommentRequest(parentPostId)
        return builder.build()
    }

    fun LoginSession.buildGetPostRequest(postId: String): PulpFictionProtos.GetPostRequest = getPostRequest {
        this.loginSession = this@buildGetPostRequest
        this.postId = postId
    }

    fun LoginSession.buildGetPostRequest(postMetadata: PostMetadata): PulpFictionProtos.GetPostRequest =
        buildGetPostRequest(postMetadata.postUpdateIdentifier.postId)

    fun LoginSession.generateRandomGetPostRequest(): PulpFictionProtos.GetPostRequest =
        buildGetPostRequest(UUID.randomUUID().toString())

    fun LoginSession.generateUpdatePostRequest(postId: String): UpdatePostRequest =
        updatePostRequest {
            this.postId = postId
            this.loginSession = this@generateUpdatePostRequest
        }

    fun UpdatePostRequest.withRandomUpdateCommentRequest(): UpdatePostRequest {
        val builder = this.toBuilder()
        builder.updateComment = updateComment {
            this.newBody = faker.lovecraft.unique.toString()
        }
        return builder.build()
    }

    fun UpdatePostRequest.withDeletePostRequest(): UpdatePostRequest {
        val builder = this.toBuilder()
        builder.deletePost = deletePost {}
        return builder.build()
    }

    fun UpdatePostRequest.withRandomUpdateImagePostRequest(): UpdatePostRequest {
        val builder = this.toBuilder()
        builder.updateImagePost = updateImagePost {
            this.newCaption = faker.lovecraft.unique.toString()
        }
        return builder.build()
    }
}
