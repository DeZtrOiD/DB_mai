
TRUNCATE TABLE
  lab_6.ratings,
  lab_6.playlist_items,
  lab_6.playlists,
  lab_6.user_collections,
  lab_6.music_details,
  lab_6.film_details,
  lab_6.book_details,
  lab_6.book_metadata,
  lab_6.content_credits,
  lab_6.content_genres,
  lab_6.content_items,
  lab_6.authors,
  lab_6.roles,
  lab_6.genres,
  lab_6.users
RESTART IDENTITY CASCADE;

INSERT INTO lab_6.genres(name)
VALUES
('Action'), ('Adventure'), ('Drama'), ('Comedy'), ('Romance'),
('Thriller'), ('Fantasy'), ('Mystery'), ('Rock'), ('Classical');

INSERT INTO lab_6.roles(role_name)
VALUES
('Author'), ('Director'), ('Composer'),
('Actor'), ('Producer'), ('Editor'), ('Narrator');

INSERT INTO lab_6.users (username, birth_date, email, password_hash)
SELECT
  'user_' || gs,
  DATE '1960-01-01' + (gs % 20000),
  'user_' || gs || '@mail.com',
  md5(gs::text)
FROM generate_series(1, 500) gs;

INSERT INTO lab_6.authors(name, birth_date)
SELECT
  'Author ' || gs,
  DATE '1940-01-01' + (gs % 25000)
FROM generate_series(1, 100) gs;

INSERT INTO lab_6.content_items(title, description, language_code)
SELECT
  'Content ' || gs,
  'Description ' || gs,
  (ARRAY['en','ru','de','fr','es'])[(gs % 5) + 1]
FROM generate_series(1, 1500) gs;

INSERT INTO lab_6.book_metadata(isbn, pages, publication_date)
SELECT
  '978-' || gs,
  100 + (gs % 500),
  DATE '1950-01-01' + (gs % 20000)
FROM generate_series(1, 500) gs;

INSERT INTO lab_6.book_details(item_id, isbn)
SELECT
  gs,
  '978-' || gs
FROM generate_series(1, 500) gs;

INSERT INTO lab_6.film_details(item_id, duration_minutes, age_rating, publication_date)
SELECT
  gs,
  80 + (gs % 100),
  (ARRAY['G','PG','PG-13','R'])[(gs % 4)+1],
  DATE '1960-01-01' + (gs % 20000)
FROM generate_series(501, 1000) gs;

INSERT INTO lab_6.music_details(item_id, duration_seconds, album, track_number, publication_date)
SELECT
  gs,
  120 + (gs % 300),
  'Album ' || ((gs-1000)/10),
  (gs % 10)+1,
  DATE '1970-01-01' + (gs % 20000)
FROM generate_series(1001, 1500) gs;

INSERT INTO lab_6.content_genres(item_id, genre_id)
SELECT
  i,
  ((i + g) % 10) + 1
FROM generate_series(1,1500) i
CROSS JOIN generate_series(1, (i % 3)+1) g;

INSERT INTO lab_6.content_credits(item_id, author_id, role_id)
SELECT DISTINCT
  i,
  ((i + c) % 100) + 1,
  ((i + c) % 7) + 1
FROM generate_series(1,1500) i
CROSS JOIN generate_series(1, (i % 3)+1) c;


INSERT INTO lab_6.user_collections(user_id, item_id)
SELECT
  u,
  ((u*37 + i) % 1500) + 1
FROM generate_series(1,500) u
CROSS JOIN generate_series(1, (u % 5)) i;

INSERT INTO lab_6.playlists(user_id, name, description, is_public)
SELECT
  u,
  'Playlist ' || u || '_' || p,
  'desc',
  (p % 2 = 0)
FROM generate_series(1,500) u
CROSS JOIN generate_series(1, (u % 3)) p;

INSERT INTO lab_6.playlist_items(playlist_id, item_id)
SELECT
  p.playlist_id,
  ((p.playlist_id * 17 + i) % 1500) + 1
FROM lab_6.playlists p
CROSS JOIN generate_series(1, (p.playlist_id % 5)+1) i;


INSERT INTO lab_6.ratings(user_id, item_id, rating_value, review_text)
SELECT DISTINCT ON (u, item_id)
  u,
  item_id,
  ((u + r) % 10) + 1,
  'review'
FROM (
  SELECT
    u,
    ((u*13 + r) % 1500) + 1 AS item_id,
    r
  FROM generate_series(1,500) u
  CROSS JOIN generate_series(1, (u % 10)) r
) t;
