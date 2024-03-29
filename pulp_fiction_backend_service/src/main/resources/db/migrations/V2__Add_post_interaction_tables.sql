CREATE TYPE POST_LIKE_TYPE AS ENUM ('NEUTRAL', 'LIKE', 'DISLIKE');

CREATE TABLE post_likes
(
    post_id            UUID           NOT NULL REFERENCES posts (post_id),
    post_liker_user_id UUID           NOT NULL REFERENCES users (user_id),
    post_like_type     POST_LIKE_TYPE NOT NULL,
    liked_at           TIMESTAMP      NOT NULL,
    PRIMARY KEY (post_id, post_liker_user_id),
    FOREIGN KEY (post_id) REFERENCES posts (post_id),
    FOREIGN KEY (post_liker_user_id) REFERENCES users (user_id)
);

CREATE TABLE post_interaction_aggregates
(
    post_id            UUID PRIMARY KEY,
    num_likes          BIGINT NOT NULL,
    num_dislikes       BIGINT NOT NULL,
    num_child_comments BIGINT NOT NULL,
    FOREIGN KEY (post_id) REFERENCES posts (post_id)
);
