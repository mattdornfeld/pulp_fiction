CREATE TABLE post_reports
(
    id               BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    post_id          UUID      NOT NULL,
    updated_at       TIMESTAMP NOT NULL,
    reported_at      TIMESTAMP NOT NULL,
    post_reporter_user_id UUID      NOT NULL REFERENCES users (user_id),
    report_reason    VARCHAR   NOT NULL,
    FOREIGN KEY (post_id, updated_at) REFERENCES post_updates (post_id, updated_at)
);
