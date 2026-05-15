

BEGIN;
SET maintenance_work_mem = '2GB';
SET LOCAL synchronous_commit = off;

TRUNCATE TABLE
  lab_4.ratings, lab_4.playlist_items, lab_4.playlists,
  lab_4.user_collections, lab_4.music_details, lab_4.film_details,
  lab_4.book_details, lab_4.book_metadata, lab_4.content_credits,
  lab_4.content_genres, lab_4.content_items, lab_4.authors,
  lab_4.roles, lab_4.genres, lab_4.users
RESTART IDENTITY CASCADE;

-- ===== ВСТАВКА СПРАВОЧНИКОВ =====
INSERT INTO lab_4.genres(name) VALUES
('Action'),('Adventure'),('Drama'),('Comedy'),('Romance'),
('Thriller'),('Fantasy'),('Mystery'),('Rock'),('Classical');

INSERT INTO lab_4.roles(role_name) VALUES
('Author'),('Director'),('Composer'),('Actor'),('Producer'),('Editor'),('Narrator');

INSERT INTO lab_4.authors(name, birth_date)
SELECT
  'Author ' || gs,
  DATE '1940-01-01' + (gs % 25000)
FROM generate_series(1, 210) gs;

-- ===== 1 000 000 ПОЛЬЗОВАТЕЛЕЙ =====
INSERT INTO lab_4.users(username, birth_date, email, password_hash)
SELECT
  'user_' || gs,
  DATE '1960-01-01' + (gs % 20000),
  'user_' || gs || '@mail.com',
  md5(gs::text)
FROM generate_series(1, 1000000) gs;

-- ===== 10 000 КОНТЕНТ-ЭЛЕМЕНТОВ =====
INSERT INTO lab_4.content_items(title, description, language_code)
SELECT
  'Content ' || gs,
  'Description for item ' || gs || '. ' || repeat('text ', 10),
  (ARRAY['en','ru','de','fr','es','ja','zh','ko','it','pt'])[(gs % 10) + 1]
FROM generate_series(1, 10000) gs;

-- ===== РАЗДЕЛЕНИЕ ПО ТИПАМ КОНТЕНТА =====
-- Книги (1-3333)
INSERT INTO lab_4.book_metadata(isbn, pages, publication_date)
SELECT '978-'||gs, 100+(gs%900), DATE '1950-01-01'+(gs%25000)
FROM generate_series(1, 3333) gs;
INSERT INTO lab_4.book_details(item_id, isbn)
SELECT gs, '978-'||gs FROM generate_series(1, 3333) gs;

-- Фильмы (3334-6666)
INSERT INTO lab_4.film_details(item_id, duration_minutes, age_rating, publication_date)
SELECT gs, 80+(gs%140), (ARRAY['G','PG','PG-13','R'])[(gs%4)+1],
       DATE '1960-01-01'+(gs%25000)
FROM generate_series(3334, 6666) gs;

-- Музыка (6667-10000)
INSERT INTO lab_4.music_details(item_id, duration_seconds, album, track_number, publication_date)
SELECT gs, 120+(gs%480), 'Album '||((gs-6667)/100+1), (gs%20)+1,
       DATE '1970-01-01'+(gs%25000)
FROM generate_series(6667, 10000) gs;

-- ===== СВЯЗИ =====
INSERT INTO lab_4.content_genres(item_id, genre_id)
SELECT i, ((i+g)%10)+1
FROM generate_series(1,10000) i
CROSS JOIN generate_series(1, (i%3)+1) g;

INSERT INTO lab_4.content_credits(item_id, author_id, role_id)
SELECT DISTINCT i, ((i+c)%200)+1, ((i+c)%7)+1
FROM generate_series(1,10000) i
CROSS JOIN generate_series(1, (i%3)+1) c;

-- ===== ПОЛЬЗОВАТЕЛЬСКИЕ ДАННЫЕ (разреженные) =====
INSERT INTO lab_4.user_collections(user_id, item_id)
SELECT u, ((u*37+i)%10000)+1
FROM generate_series(1,1000000) u
CROSS JOIN generate_series(1, (u%3)) i;

INSERT INTO lab_4.playlists(user_id, name, description, is_public)
SELECT u, 'Playlist '||u||'_'||p, 'desc', (p%2=0)
FROM generate_series(1,1000000) u
CROSS JOIN generate_series(1, (u%2)) p;

INSERT INTO lab_4.playlist_items(playlist_id, item_id)
SELECT p.playlist_id, ((p.playlist_id*17+i)%10000)+1
FROM lab_4.playlists p
CROSS JOIN generate_series(1, (p.playlist_id%6)+1) i;

INSERT INTO lab_4.ratings(user_id, item_id, rating_value, review_text)
SELECT DISTINCT ON (u, item_id) u, item_id, ((u+r)%10)+1,
       CASE WHEN (u+r)%5=0 THEN 'Review from user '||u ELSE NULL END
FROM (
  SELECT u, ((u*13+r)%10000)+1 AS item_id, r
  FROM generate_series(1,1000000) u
  CROSS JOIN generate_series(1, (u%5)) r
) t WHERE (u+r)%3=0;

COMMIT;

VACUUM ANALYZE;
ANALYZE lab_4.users;
ANALYZE lab_4.content_items;
ANALYZE lab_4.ratings;
ANALYZE lab_4.user_collections;

SELECT 'users' AS table_name, count(*) AS rows FROM lab_4.users
UNION ALL SELECT 'content_items', count(*) FROM lab_4.content_items
UNION ALL SELECT 'ratings', count(*) FROM lab_4.ratings;
