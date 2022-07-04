CREATE TYPE POST_STATE AS ENUM ('CREATING', 'CREATED', 'DELETED');
CREATE TYPE POST_TYPE AS ENUM ('IMAGE', 'COMMENT', 'USER');

CREATE TABLE users
(
    user_id          UUID PRIMARY KEY,
    created_at       TIMESTAMP NOT NULL,
    display_name     VARCHAR   NOT NULL,
    email            VARCHAR   NOT NULL,
    phone_number     VARCHAR   NOT NULL,
    date_of_birth    DATE      NOT NULL,
    hashed_password  VARCHAR   NOT NULL,
    avatar_image_url VARCHAR
);

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

CREATE TABLE post_ids
(
    post_id UUID PRIMARY KEY
);

CREATE TABLE posts
(
    post_id         UUID       NOT NULL,
    created_at      TIMESTAMP  NOT NULL,
    post_state      POST_STATE NOT NULL,
    post_creator_id UUID       NOT NULL REFERENCES users (user_id),
    post_type       POST_TYPE  NOT NULL,
    PRIMARY KEY (post_id, created_at),
    FOREIGN KEY (post_id) REFERENCES post_ids(post_id)
);

CREATE TABLE comment_data
(
    post_id           UUID      NOT NULL,
    created_at        TIMESTAMP NOT NULL,
    body              VARCHAR   NOT NULL,
    parent_post_id    UUID      NOT NULL,
    PRIMARY KEY (post_id, created_at),
    FOREIGN KEY (post_id, created_at) REFERENCES posts (post_id, created_at),
    FOREIGN KEY (parent_post_id) REFERENCES post_ids (post_id)
);

CREATE TABLE image_post_data
(
    post_id    UUID      NOT NULL,
    created_at TIMESTAMP NOT NULL,
    image_url  VARCHAR   NOT NULL,
    caption    VARCHAR   NOT NULL,
    PRIMARY KEY (post_id, created_at),
    FOREIGN KEY (post_id, created_at) REFERENCES posts (post_id, created_at)
);