-- Сценарий 1: Добавление новой книги с метаданными и жанрами
-- 1.1 Успешное выполнение с фиксацией
BEGIN;
INSERT INTO lab_4.content_items(title, description, language_code) 
VALUES ('Книга Alpha', 'Описание тестовой книги', 'ru');

INSERT INTO lab_4.book_metadata(isbn, pages, publication_date) 
VALUES ('978-1-000-001', 250, CURRENT_DATE);

INSERT INTO lab_4.book_details(item_id, isbn) 
VALUES (currval('lab_4.content_items_item_id_seq'), '978-1-000-001');

INSERT INTO lab_4.content_genres(item_id, genre_id) 
VALUES (currval('lab_4.content_items_item_id_seq'), 1);
COMMIT;

-- 1.2 Полный откат из-за ошибки
BEGIN;
INSERT INTO lab_4.content_items(title, description, language_code) 
VALUES ('Книга Beta', 'Описание', 'en');

INSERT INTO lab_4.book_metadata(isbn, pages, publication_date) 
VALUES ('978-1-000-002', 300, CURRENT_DATE);

-- Имитация ошибки: генерация исключения прерывает выполнение
SELECT 1/0; 

-- PostgreSQL автоматически помечает транзакцию как aborted.
-- Явный ROLLBACK сбрасывает состояние и отменяет все предыдущие INSERT.
ROLLBACK;


-- 1.3 Частичный откат через точку сохранения
BEGIN;
INSERT INTO lab_4.content_items(title, description, language_code) 
VALUES ('Книга Gamma', 'Описание', 'de');

SAVEPOINT sp_metadata;

-- Ошибка: нарушается ограничение chk_book_metadata_pages_positive (pages <= 0)
INSERT INTO lab_4.book_metadata(isbn, pages, publication_date) 
VALUES ('978-1-000-003', -50, CURRENT_DATE);

-- Частичный откат: отменяется только INSERT в book_metadata
ROLLBACK TO sp_metadata;

-- Повторная вставка с корректными данными
INSERT INTO lab_4.book_metadata(isbn, pages, publication_date) 
VALUES ('978-1-000-003', 180, CURRENT_DATE);

INSERT INTO lab_4.book_details(item_id, isbn) 
VALUES (currval('lab_4.content_items_item_id_seq'), '978-1-000-003');
COMMIT;

-- Сценарий 2: Создание плейлиста и добавление треков
-- 2.1 Успешное выполнение
BEGIN;
INSERT INTO lab_4.playlists(user_id, name, description, is_public) 
VALUES (1, 'Мой первый плейлист', 'Тестовый список', FALSE)
RETURNING playlist_id;

INSERT INTO lab_4.playlist_items(playlist_id, item_id) VALUES (currval('lab_4.playlists_playlist_id_seq'), 1);
INSERT INTO lab_4.playlist_items(playlist_id, item_id) VALUES (currval('lab_4.playlists_playlist_id_seq'), 2);
INSERT INTO lab_4.playlist_items(playlist_id, item_id) VALUES (currval('lab_4.playlists_playlist_id_seq'), 3);
COMMIT;

-- 2.2 Полный откат
BEGIN;
INSERT INTO lab_4.playlists(user_id, name, description, is_public) 
VALUES (1, 'Плейлист для отката', 'Описание', TRUE)
RETURNING playlist_id;

INSERT INTO lab_4.playlist_items(playlist_id, item_id) 
VALUES (currval('lab_4.playlists_playlist_id_seq'), 1);

-- Нарушение уникальности composite PK при дублировании пары (playlist_id, item_id)
INSERT INTO lab_4.playlist_items(playlist_id, item_id) 
VALUES (currval('lab_4.playlists_playlist_id_seq'), 1);

ROLLBACK;

-- 2.3 Частичный откат
BEGIN;
INSERT INTO lab_4.playlists(user_id, name, description, is_public) 
VALUES (1, 'Плейлист с savepoint', 'Описание', TRUE)
RETURNING playlist_id;

SAVEPOINT sp_items;

INSERT INTO lab_4.playlist_items(playlist_id, item_id) VALUES (currval('lab_4.playlists_playlist_id_seq'), 5);
INSERT INTO lab_4.playlist_items(playlist_id, item_id) VALUES (currval('lab_4.playlists_playlist_id_seq'), 6);
-- Ошибка: дубликат PK
INSERT INTO lab_4.playlist_items(playlist_id, item_id) VALUES (currval('lab_4.playlists_playlist_id_seq'), 5);

ROLLBACK TO sp_items;

-- Корректное добавление третьего трека
INSERT INTO lab_4.playlist_items(playlist_id, item_id) VALUES (currval('lab_4.playlists_playlist_id_seq'), 7);
COMMIT;


-- Сценарий 3: Оценка контента и добавление в коллекцию
-- 3.1 Успешное выполнение
BEGIN;
INSERT INTO lab_4.ratings(user_id, item_id, rating_value, review_text) 
VALUES (1, 1, 9, 'Отличный контент');

INSERT INTO lab_4.user_collections(user_id, item_id) 
VALUES (1, 1);
COMMIT;

-- 3.2 Полный откат
BEGIN;
-- Нарушение chk_ratings_value (rating_value > 10)
INSERT INTO lab_4.ratings(user_id, item_id, rating_value, review_text) 
VALUES (1, 2, 15, 'Слишком высокий рейтинг');

ROLLBACK;

-- 3.3 Частичный откат
BEGIN;
INSERT INTO lab_4.ratings(user_id, item_id, rating_value, review_text) 
VALUES (1, 3, 8, 'Хорошо');

SAVEPOINT sp_collection;

-- Нарушение PK в user_collections (если пара уже существует)
INSERT INTO lab_4.user_collections(user_id, item_id) VALUES (1, 3);

ROLLBACK TO sp_collection;

-- Корректное добавление в коллекцию другого элемента
INSERT INTO lab_4.user_collections(user_id, item_id) VALUES (1, 4);
COMMIT;



-- ===========================================================================
UPDATE lab_4.playlists SET name = 'Initial_State', is_public = FALSE WHERE playlist_id = 1;
COMMIT;

-- READ COMMITTED
-- A
BEGIN;
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

UPDATE lab_4.playlists 
SET name = 'RC_SessionA', is_public = TRUE 
WHERE playlist_id = 1;
-- [ПАУЗА]

-- B
BEGIN;
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

UPDATE lab_4.playlists 
SET name = 'RC_SessionB', is_public = FALSE 
WHERE playlist_id = 1;

-- [ПАУЗА] Запрос будет ждать. Вернитесь в Сессию А и выполните COMMIT;
SELECT name FROM lab_4.playlists WHERE playlist_id = 1;
-- Результат: 'RC_SessionA' (так как А закоммитил раньше, а B видит последние зафиксированные данные на момент начала оператора)

COMMIT;

-- ===========================================================================
UPDATE lab_4.playlists SET name = 'Initial_State', is_public = FALSE WHERE playlist_id = 1;
COMMIT;

-- REPEATABLE READ
-- A
BEGIN;
SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;

UPDATE lab_4.playlists 
SET name = 'RR_SessionA' 
WHERE playlist_id = 1;

-- [ПАУЗА] Перейдите в Сессию Б.

-- B
BEGIN;
SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;

SELECT name FROM lab_4.playlists WHERE playlist_id = 1;
-- Результат: старое значение

-- [ПАУЗА] Теперь перейдите в Сессию А и выполните COMMIT;
-- Вернитесь в Сессию Б.
-- 3. Повторное чтение в ТОЙ ЖЕ транзакции
SELECT name FROM lab_4.playlists WHERE playlist_id = 1;
-- Результат: ВСЁ ЕЩЁ старое значение! Snapshot не обновляется.
ROLLBACK;

-- ===========================================================================
UPDATE lab_4.playlists SET name = 'Initial_State', is_public = FALSE WHERE playlist_id = 1;
COMMIT;

-- SERIALIZABLE
-- A
BEGIN;
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;

UPDATE lab_4.playlists 
SET name = 'SER_SessionA' 
WHERE playlist_id = 1;

-- [ПАУЗА] Перейдите в Сессию Б.
COMMIT;
-- ОШИБКА: ERROR: could not serialize access due to concurrent update

-- B
BEGIN;
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;

UPDATE lab_4.playlists 
SET name = 'SER_SessionB' 
WHERE playlist_id = 1;
COMMIT; 

-- [ПАУЗА] Вернитесь в Сессию А.
