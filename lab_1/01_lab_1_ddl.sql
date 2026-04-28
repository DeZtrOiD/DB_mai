
CREATE SCHEMA IF NOT EXISTS lab_1;

CREATE TABLE lab_1.users (
    user_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    birth_date DATE,
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL
);


CREATE TABLE lab_1.content_types (
    type_id SMALLINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    type_name VARCHAR(20) NOT NULL UNIQUE
);

CREATE TABLE lab_1.content_items (
    item_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    type_id SMALLINT NOT NULL REFERENCES lab_1.content_types(type_id) ON DELETE RESTRICT,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    language_code CHAR(2)
);


CREATE TABLE lab_1.genres (
    genre_id SMALLINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE lab_1.content_genres (
    item_id BIGINT NOT NULL REFERENCES lab_1.content_items(item_id) ON DELETE CASCADE,
    genre_id SMALLINT NOT NULL REFERENCES lab_1.genres(genre_id) ON DELETE CASCADE,
    PRIMARY KEY (item_id, genre_id)
);


CREATE TABLE lab_1.authors (
    author_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    birth_date DATE,
    CONSTRAINT uq_author_name_birth UNIQUE (name, birth_date)
);

CREATE TABLE lab_1.roles (
    role_id SMALLINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    role_name VARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE lab_1.content_credits (
    item_id BIGINT NOT NULL REFERENCES lab_1.content_items(item_id) ON DELETE CASCADE,
    author_id BIGINT NOT NULL REFERENCES lab_1.authors(author_id) ON DELETE RESTRICT,
    role_id SMALLINT NOT NULL REFERENCES lab_1.roles(role_id) ON DELETE RESTRICT,
    PRIMARY KEY (item_id, author_id, role_id)
);


CREATE TABLE lab_1.book_metadata (
    isbn VARCHAR(20) PRIMARY KEY,
    pages INTEGER,
    publication_date DATE
);

CREATE TABLE lab_1.book_details (
    item_id BIGINT PRIMARY KEY REFERENCES lab_1.content_items(item_id) ON DELETE CASCADE,
    isbn VARCHAR(20) NOT NULL UNIQUE REFERENCES lab_1.book_metadata(isbn) ON DELETE RESTRICT
);


CREATE TABLE lab_1.film_details (
    item_id BIGINT PRIMARY KEY REFERENCES lab_1.content_items(item_id) ON DELETE CASCADE,
    duration_minutes INTEGER,
    age_rating VARCHAR(10),
    publication_date DATE
);


CREATE TABLE lab_1.music_details (
    item_id BIGINT PRIMARY KEY REFERENCES lab_1.content_items(item_id) ON DELETE CASCADE,
    duration_seconds INTEGER,
    album VARCHAR(255),
    track_number INTEGER,
    publication_date DATE
);


CREATE TABLE lab_1.user_collections (
    user_id BIGINT NOT NULL REFERENCES lab_1.users(user_id) ON DELETE CASCADE,
    item_id BIGINT NOT NULL REFERENCES lab_1.content_items(item_id) ON DELETE CASCADE,
    PRIMARY KEY (user_id, item_id)
);


CREATE TABLE lab_1.playlists (
    playlist_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES lab_1.users(user_id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    is_public BOOLEAN NOT NULL DEFAULT FALSE,
    CONSTRAINT uq_playlist_user_name UNIQUE (user_id, name)
);

CREATE TABLE lab_1.playlist_items (
    playlist_id BIGINT NOT NULL REFERENCES lab_1.playlists(playlist_id) ON DELETE CASCADE,
    item_id BIGINT NOT NULL REFERENCES lab_1.content_items(item_id) ON DELETE CASCADE,
    PRIMARY KEY (playlist_id, item_id)
);


CREATE TABLE lab_1.ratings (
    user_id BIGINT NOT NULL REFERENCES lab_1.users(user_id) ON DELETE CASCADE,
    item_id BIGINT NOT NULL REFERENCES lab_1.content_items(item_id) ON DELETE CASCADE,
    rating_value SMALLINT NOT NULL,
    review_text TEXT,
    rated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    PRIMARY KEY (user_id, item_id)
);
