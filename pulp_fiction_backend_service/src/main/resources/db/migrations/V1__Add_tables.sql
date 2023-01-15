CREATE TYPE POST_STATE AS ENUM ('CREATING', 'CREATED', 'DELETED');
CREATE TYPE POST_TYPE AS ENUM ('IMAGE', 'COMMENT', 'USER');

CREATE TABLE users
(
    user_id         UUID PRIMARY KEY,
    created_at      TIMESTAMP NOT NULL,
    hashed_password VARCHAR   NOT NULL
);

CREATE TABLE display_names
(
    user_id              UUID PRIMARY KEY REFERENCES users (user_id),
    current_display_name VARCHAR NOT NULL UNIQUE
);

CREATE TABLE dates_of_birth
(
    user_id       UUID PRIMARY KEY REFERENCES users (user_id),
    date_of_birth DATE NOT NULL
);

CREATE TABLE emails
(
    user_id UUID PRIMARY KEY REFERENCES users (user_id),
    email   VARCHAR NOT NULL
);

CREATE INDEX CONCURRENTLY emails_index ON emails USING HASH (email);

CREATE TABLE phone_numbers
(
    user_id      UUID PRIMARY KEY REFERENCES users (user_id),
    phone_number VARCHAR NOT NULL
);

CREATE INDEX CONCURRENTLY phone_numbers_index ON phone_numbers USING HASH (phone_number);

CREATE TABLE login_sessions
(
    id            BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id       UUID      NOT NULL REFERENCES users (user_id),
    created_at    TIMESTAMP NOT NULL,
    device_id     VARCHAR   NOT NULL,
    session_token UUID      NOT NULL
);

CREATE INDEX CONCURRENTLY login_sessions_user_id ON login_sessions (user_id);

CREATE TABLE followers
(
    id          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id     UUID      NOT NULL REFERENCES users (user_id),
    follower_id UUID      NOT NULL REFERENCES users (user_id),
    created_at  TIMESTAMP NOT NULL
);

CREATE INDEX CONCURRENTLY followers_user_id ON followers (user_id);

CREATE TABLE posts
(
    post_id         UUID PRIMARY KEY,
    created_at      TIMESTAMP NOT NULL,
    post_creator_id UUID      NOT NULL REFERENCES users (user_id),
    post_type       POST_TYPE NOT NULL
);

CREATE TABLE post_updates
(
    post_id    UUID       NOT NULL,
    updated_at TIMESTAMP  NOT NULL,
    post_state POST_STATE NOT NULL,
    PRIMARY KEY (post_id, updated_at),
    FOREIGN KEY (post_id) REFERENCES posts (post_id)
);

CREATE TABLE comment_data
(
    post_id        UUID      NOT NULL,
    updated_at     TIMESTAMP NOT NULL,
    body           VARCHAR   NOT NULL,
    parent_post_id UUID      NOT NULL,
    PRIMARY KEY (post_id, updated_at),
    FOREIGN KEY (post_id, updated_at) REFERENCES post_updates (post_id, updated_at),
    FOREIGN KEY (parent_post_id) REFERENCES posts (post_id)
);

CREATE TABLE image_post_data
(
    post_id      UUID      NOT NULL,
    updated_at   TIMESTAMP NOT NULL,
    image_s3_key VARCHAR   NOT NULL,
    caption      VARCHAR   NOT NULL,
    PRIMARY KEY (post_id, updated_at),
    FOREIGN KEY (post_id, updated_at) REFERENCES post_updates (post_id, updated_at)
);

CREATE TABLE user_post_data
(
    post_id             UUID      NOT NULL,
    updated_at          TIMESTAMP NOT NULL,
    user_id             UUID      NOT NULL REFERENCES users (user_id),
    display_name        VARCHAR   NOT NULL,
    avatar_image_s3_key VARCHAR   NOT NULL,
    bio                 VARCHAR   NOT NULL,
    PRIMARY KEY (post_id, updated_at),
    FOREIGN KEY (post_id, updated_at) REFERENCES post_updates (post_id, updated_at)
);
