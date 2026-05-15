
CREATE SCHEMA IF NOT EXISTS lab_4;

CREATE TABLE lab_4.users (
    user_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    birth_date DATE,
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL
);

CREATE TABLE lab_4.content_items (
    item_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    language_code CHAR(2)
);


CREATE TABLE lab_4.genres (
    genre_id SMALLINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE lab_4.content_genres (
    item_id BIGINT NOT NULL REFERENCES lab_4.content_items(item_id) ON DELETE CASCADE,
    genre_id SMALLINT NOT NULL REFERENCES lab_4.genres(genre_id) ON DELETE CASCADE,
    PRIMARY KEY (item_id, genre_id)
);


CREATE TABLE lab_4.authors (
    author_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    birth_date DATE,
    CONSTRAINT uq_author_name_birth UNIQUE (name, birth_date)
);

CREATE TABLE lab_4.roles (
    role_id SMALLINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    role_name VARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE lab_4.content_credits (
    item_id BIGINT NOT NULL REFERENCES lab_4.content_items(item_id) ON DELETE CASCADE,
    author_id BIGINT NOT NULL REFERENCES lab_4.authors(author_id) ON DELETE RESTRICT,
    role_id SMALLINT NOT NULL REFERENCES lab_4.roles(role_id) ON DELETE RESTRICT,
    PRIMARY KEY (item_id, author_id, role_id)
);


CREATE TABLE lab_4.book_metadata (
    isbn VARCHAR(20) PRIMARY KEY,
    pages INTEGER,
    publication_date DATE
);

CREATE TABLE lab_4.book_details (
    item_id BIGINT PRIMARY KEY REFERENCES lab_4.content_items(item_id) ON DELETE CASCADE,
    isbn VARCHAR(20) NOT NULL UNIQUE REFERENCES lab_4.book_metadata(isbn) ON DELETE RESTRICT
);


CREATE TABLE lab_4.film_details (
    item_id BIGINT PRIMARY KEY REFERENCES lab_4.content_items(item_id) ON DELETE CASCADE,
    duration_minutes INTEGER,
    age_rating VARCHAR(10),
    publication_date DATE
);


CREATE TABLE lab_4.music_details (
    item_id BIGINT PRIMARY KEY REFERENCES lab_4.content_items(item_id) ON DELETE CASCADE,
    duration_seconds INTEGER,
    album VARCHAR(255),
    track_number INTEGER,
    publication_date DATE
);


CREATE TABLE lab_4.user_collections (
    user_id BIGINT NOT NULL REFERENCES lab_4.users(user_id) ON DELETE CASCADE,
    item_id BIGINT NOT NULL REFERENCES lab_4.content_items(item_id) ON DELETE CASCADE,
    PRIMARY KEY (user_id, item_id)
);


CREATE TABLE lab_4.playlists (
    playlist_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES lab_4.users(user_id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    is_public BOOLEAN NOT NULL DEFAULT FALSE,
    CONSTRAINT uq_playlist_user_name UNIQUE (user_id, name)
);

CREATE TABLE lab_4.playlist_items (
    playlist_id BIGINT NOT NULL REFERENCES lab_4.playlists(playlist_id) ON DELETE CASCADE,
    item_id BIGINT NOT NULL REFERENCES lab_4.content_items(item_id) ON DELETE CASCADE,
    PRIMARY KEY (playlist_id, item_id)
);

CREATE TABLE lab_4.ratings (
    user_id BIGINT NOT NULL REFERENCES lab_4.users(user_id) ON DELETE CASCADE,
    item_id BIGINT NOT NULL REFERENCES lab_4.content_items(item_id) ON DELETE CASCADE,
    rating_value SMALLINT NOT NULL,
    review_text TEXT,
    rated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    PRIMARY KEY (user_id, item_id)
);


ALTER TABLE lab_4.users
  ADD CONSTRAINT chk_users_username_nonempty CHECK (btrim(username) <> ''),
  ADD CONSTRAINT chk_users_birth_date CHECK (birth_date IS NULL OR birth_date <= CURRENT_DATE),
  ADD CONSTRAINT chk_users_email_format CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'),
  ADD CONSTRAINT chk_users_password_hash_nonempty CHECK (btrim(password_hash) <> '');


ALTER TABLE lab_4.content_items
  ADD CONSTRAINT chk_content_items_title_nonempty CHECK (btrim(title) <> ''),
  ADD CONSTRAINT chk_content_items_language_code CHECK (language_code IS NULL OR language_code ~ '^[a-z]{2}$');

ALTER TABLE lab_4.genres
  ADD CONSTRAINT chk_genres_name_nonempty CHECK (btrim(name) <> '');

ALTER TABLE lab_4.authors
  ADD CONSTRAINT chk_authors_name_nonempty CHECK (btrim(name) <> ''),
  ADD CONSTRAINT chk_authors_birth_date CHECK (birth_date IS NULL OR birth_date <= CURRENT_DATE);

ALTER TABLE lab_4.roles
  ADD CONSTRAINT chk_roles_name_nonempty CHECK (btrim(role_name) <> '');

ALTER TABLE lab_4.book_metadata
  ADD CONSTRAINT chk_book_metadata_isbn_nonempty CHECK (btrim(isbn) <> ''),
  ADD CONSTRAINT chk_book_metadata_pages_positive CHECK (pages IS NULL OR pages > 0),
  ADD CONSTRAINT chk_book_metadata_pubdate CHECK (publication_date IS NULL OR publication_date <= CURRENT_DATE);

ALTER TABLE lab_4.film_details
  ADD CONSTRAINT chk_film_details_duration_positive CHECK (duration_minutes IS NULL OR duration_minutes > 0),
  ADD CONSTRAINT chk_film_details_age_rating CHECK (age_rating IS NULL OR age_rating IN ('G', 'PG', 'PG-13', 'R', 'NC-17')),
  ADD CONSTRAINT chk_film_details_pubdate CHECK (publication_date IS NULL OR publication_date <= CURRENT_DATE);

ALTER TABLE lab_4.music_details
  ADD CONSTRAINT chk_music_details_duration_positive CHECK (duration_seconds IS NULL OR duration_seconds > 0),
  ADD CONSTRAINT chk_music_details_track_positive CHECK (track_number IS NULL OR track_number > 0),
  ADD CONSTRAINT chk_music_details_album_nonempty CHECK (album IS NULL OR btrim(album) <> ''),
  ADD CONSTRAINT chk_music_details_pubdate CHECK (publication_date IS NULL OR publication_date <= CURRENT_DATE);

ALTER TABLE lab_4.playlists
  ADD CONSTRAINT chk_playlists_name_nonempty CHECK (btrim(name) <> '');

ALTER TABLE lab_4.ratings
  ADD CONSTRAINT chk_ratings_value CHECK (rating_value BETWEEN 1 AND 10);
