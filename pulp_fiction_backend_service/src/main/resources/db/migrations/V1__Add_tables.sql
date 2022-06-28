CREATE TYPE POST_STATE AS ENUM ('CREATING', 'CREATED', 'DELETED');
CREATE TYPE POST_TYPE AS ENUM ('IMAGE', 'COMMENT', 'USER');

CREATE TABLE posts (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    post_id UUID NOT NULL,
    post_state POST_STATE NOT NULL,
    created_at TIMESTAMP NOT NULL,
    post_creator_id UUID NOT NULL,
    post_type POST_TYPE NOT NULL,
    post_version INT NOT NULL
);

CREATE TABLE users (
    user_id UUID PRIMARY KEY,
    display_name VARCHAR NOT NULL,
    email VARCHAR not null,
    phone_number VARCHAR not null,
    date_of_birth DATE not null,
    avatar_image_url VARCHAR
)
