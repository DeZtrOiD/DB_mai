
CREATE EXTENSION IF NOT EXISTS pg_trgm;

DROP INDEX IF EXISTS idx_users_bd_uid;
DROP INDEX IF EXISTS idx_users_uid_bd;
DROP INDEX IF EXISTS idx_users_bd_desc;
DROP INDEX IF EXISTS idx_users_username;
DROP INDEX IF EXISTS idx_users_username_trgm;
DROP INDEX IF EXISTS idx_playlists_user;
DROP INDEX IF EXISTS idx_playlists_public;
DROP INDEX IF EXISTS idx_users_bd;

ANALYZE lab_4.users;
ANALYZE lab_4.playlists;

-- ============================================================================
-- ============================================================================
-- ============================================================================

-- ==========================================
-- 1. СЛОЖНЫЙ ФИЛЬТР (точное сравнение + диапазон)
-- ==========================================

-- 1.1 Без индекса
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT user_id, username, birth_date, email
FROM lab_4.users
WHERE birth_date = '1990-05-15' AND user_id > 500000;

-- 1.2 Создаём индекс
CREATE INDEX idx_users_bd_uid ON lab_4.users (birth_date, user_id);

-- 1.3 С индексом
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT user_id, username, birth_date, email
FROM lab_4.users
WHERE birth_date = '1990-05-15' AND user_id > 500000;

-- 1.4 Очистка для следующих сценариев (опционально)
DROP INDEX idx_users_bd_uid;

-- ============================================================================
-- ============================================================================
-- ============================================================================

-- ==========================================
-- 2. СОРТИРОВКА С ОГРАНИЧЕНИЕМ (ORDER BY + LIMIT)
-- ==========================================

-- 2.1 Без индекса
EXPLAIN (ANALYZE, BUFFERS)
SELECT user_id, username, birth_date
FROM lab_4.users
ORDER BY birth_date DESC
LIMIT 50;

-- 2.2 Создаём индекс
CREATE INDEX idx_users_bd_desc ON lab_4.users (birth_date DESC);

-- 2.3 С индексом
EXPLAIN (ANALYZE, BUFFERS)
SELECT user_id, username, birth_date
FROM lab_4.users
ORDER BY birth_date DESC
LIMIT 50;

DROP INDEX idx_users_bd_desc;

-- ============================================================================
-- ============================================================================
-- ============================================================================

-- ==========================================
-- 3. АЛЬТЕРНАТИВНЫЕ ВАРИАНТЫ ИНДЕКСИРОВАНИЯ
-- ==========================================

-- 3.0 Базовый запрос
EXPLAIN (ANALYZE, BUFFERS)
SELECT user_id, username, birth_date
FROM lab_4.users
WHERE birth_date >= '1985-01-01' AND username LIKE 'user_123%';

-- 3.1 Вариант А: (birth_date, username)
CREATE INDEX idx_users_bd_uid ON lab_4.users (birth_date, username);
EXPLAIN (ANALYZE, BUFFERS)
SELECT user_id, username, birth_date
FROM lab_4.users
WHERE birth_date >= '1985-01-01' AND username LIKE 'user_123%';
DROP INDEX idx_users_bd_uid;

-- 3.2 Вариант Б: (username, birth_date)
CREATE INDEX idx_users_uid_bd ON lab_4.users (username, birth_date);
EXPLAIN (ANALYZE, BUFFERS)
SELECT user_id, username, birth_date
FROM lab_4.users
WHERE birth_date >= '1985-01-01' AND username LIKE 'user_123%';
DROP INDEX idx_users_uid_bd;

-- ============================================================================
-- ============================================================================
-- ============================================================================

-- ==========================================
-- 4. ТЕКСТОВЫЙ ПОИСК (префикс, подстрока, суффикс)
-- ==========================================

-- 4.1 Префикс (B-tree работает)
EXPLAIN (ANALYZE, BUFFERS)
SELECT user_id FROM lab_4.users WHERE username LIKE 'user_50000%';

CREATE INDEX idx_users_username ON lab_4.users (username);
EXPLAIN (ANALYZE, BUFFERS)
SELECT user_id FROM lab_4.users WHERE username LIKE 'user_50000%';

-- 4.2 Подстрока (B-tree НЕ работает, нужен GIN + trigram)
EXPLAIN (ANALYZE, BUFFERS)
SELECT user_id FROM lab_4.users WHERE username LIKE '%12345%';

CREATE INDEX idx_users_username_trgm ON lab_4.users USING gin (username gin_trgm_ops);
EXPLAIN (ANALYZE, BUFFERS)
SELECT user_id FROM lab_4.users WHERE username LIKE '%12345%';

-- Очистка
DROP INDEX idx_users_username;
DROP INDEX idx_users_username_trgm;

-- ============================================================================
-- ============================================================================
-- ============================================================================

-- ==========================================
-- 5. СОЕДИНЕНИЕ ТАБЛИЦ (JOIN)
-- ==========================================

-- 5.1 Без индексов
EXPLAIN (ANALYZE, BUFFERS)
SELECT u.username, p.name, p.is_public
FROM lab_4.users u
JOIN lab_4.playlists p ON u.user_id = p.user_id
WHERE u.birth_date BETWEEN '1990-01-01' AND '2000-12-31'
  AND p.is_public = TRUE
LIMIT 100;

-- 5.2 Создаём индексы
CREATE INDEX idx_users_bd ON lab_4.users (birth_date);
CREATE INDEX idx_playlists_user ON lab_4.playlists (user_id);
CREATE INDEX idx_playlists_public ON lab_4.playlists (is_public);

-- 5.3 С индексами
EXPLAIN (ANALYZE, BUFFERS)
SELECT u.username, p.name, p.is_public
FROM lab_4.users u
JOIN lab_4.playlists p ON u.user_id = p.user_id
WHERE u.birth_date BETWEEN '1990-01-01' AND '2000-12-31'
  AND p.is_public = TRUE
LIMIT 100;

-- Очистка
DROP INDEX idx_users_bd;
DROP INDEX idx_playlists_user;
DROP INDEX idx_playlists_public;

-- ============================================================================
-- ============================================================================
-- ============================================================================

-- ==========================================
-- 6. НЕГАТИВНЫЙ СЦЕНАРИЙ (индекс не помогает)
-- ==========================================

-- 6.1 Без индекса (100% совпадений)
EXPLAIN (ANALYZE, BUFFERS)
SELECT user_id, username FROM lab_4.users WHERE birth_date > '1900-01-01';

-- 6.2 Создаём индекс
CREATE INDEX idx_users_bd ON lab_4.users (birth_date);

-- 6.3 С индексом (планировщик всё равно выберет Seq Scan)
EXPLAIN (ANALYZE, BUFFERS)
SELECT user_id, username FROM lab_4.users WHERE birth_date > '1900-01-01';

DROP INDEX idx_users_bd;

-- ============================================================================
-- ============================================================================
-- ============================================================================

-- ============================================================================
-- СЦЕНАРИЙ 7: Влияние индексов на INSERT / UPDATE
-- ============================================================================

-- [0] Очистка временных индексов
DROP INDEX IF EXISTS idx_bench_bd_uid;
DROP INDEX IF EXISTS idx_bench_bd_desc;
DROP INDEX IF EXISTS idx_bench_uid_bd;
DROP INDEX IF EXISTS idx_bench_username;
DROP INDEX IF EXISTS idx_bench_username_trgm;
DROP INDEX IF EXISTS idx_bench_bd;

BEGIN;
SET LOCAL synchronous_commit = off;

-- ============================================================================
-- [1] БАЗОВЫЙ ЗАМЕР: без дополнительных индексов
-- ============================================================================

-- [1.1] INSERT без индексов
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
INSERT INTO lab_4.users (username, birth_date, email, password_hash)
SELECT 
  'bench_no_idx_' || gs, 
  DATE '1990-01-01' + (gs % 5000), 
  'bench_no_idx_' || gs || '@test.com', 
  md5(gs::text)
FROM generate_series(1, 2000) gs;

-- [1.2] UPDATE без индексов
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
UPDATE lab_4.users 
SET email = 'updated_bench_' || user_id || '@test.com',
    password_hash = md5('new_pass_' || user_id)
WHERE user_id BETWEEN 900000 AND 901000;

-- ============================================================================
-- [2] ЗАМЕР: с одним B-tree индексом
-- ============================================================================

CREATE INDEX idx_bench_bd_uid ON lab_4.users (birth_date, user_id);

-- [2.1] INSERT с 1 B-tree
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
INSERT INTO lab_4.users (username, birth_date, email, password_hash)
SELECT 
  'bench_1btree_' || gs, 
  DATE '1990-01-01' + (gs % 5000), 
  'bench_1btree_' || gs || '@test.com', 
  md5(gs::text)
FROM generate_series(1, 2000) gs;

-- [2.2] UPDATE с 1 B-tree
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
UPDATE lab_4.users 
SET email = 'updated_bench_' || user_id || '@test.com',
    password_hash = md5('new_pass_' || user_id)
WHERE user_id BETWEEN 900000 AND 901000;

DROP INDEX idx_bench_bd_uid;

-- ============================================================================
-- [3] ЗАМЕР: с одним GIN индексом (trigram)
-- ============================================================================

CREATE INDEX idx_bench_username_trgm ON lab_4.users USING gin (username gin_trgm_ops);

-- [3.1] INSERT с 1 GIN
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
INSERT INTO lab_4.users (username, birth_date, email, password_hash)
SELECT 
  'bench_1gin_' || gs, 
  DATE '1990-01-01' + (gs % 5000), 
  'bench_1gin_' || gs || '@test.com', 
  md5(gs::text)
FROM generate_series(1, 2000) gs;

-- [3.2] UPDATE с 1 GIN
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
UPDATE lab_4.users 
SET email = 'updated_bench_' || user_id || '@test.com',
    password_hash = md5('new_pass_' || user_id)
WHERE user_id BETWEEN 900000 AND 901000;

DROP INDEX idx_bench_username_trgm;

-- ============================================================================
-- [4] ЗАМЕР: со ВСЕМИ индексами из сценариев 1-6
-- ============================================================================

CREATE INDEX idx_bench_bd_uid ON lab_4.users (birth_date, user_id);
CREATE INDEX idx_bench_bd_desc ON lab_4.users (birth_date DESC);
CREATE INDEX idx_bench_uid_bd ON lab_4.users (username, birth_date);
CREATE INDEX idx_bench_username ON lab_4.users (username);
CREATE INDEX idx_bench_username_trgm ON lab_4.users USING gin (username gin_trgm_ops);
CREATE INDEX idx_bench_bd ON lab_4.users (birth_date);

-- [4.1] INSERT со всеми индексами
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
INSERT INTO lab_4.users (username, birth_date, email, password_hash)
SELECT 
  'bench_all_idx_' || gs, 
  DATE '1990-01-01' + (gs % 5000), 
  'bench_all_idx_' || gs || '@test.com', 
  md5(gs::text)
FROM generate_series(1, 2000) gs;

-- [4.2] UPDATE со всеми индексами
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
UPDATE lab_4.users 
SET email = 'updated_bench_' || user_id || '@test.com',
    password_hash = md5('new_pass_' || user_id)
WHERE user_id BETWEEN 900000 AND 901000;

-- ============================================================================
-- [5] Откат изменений и очистка
-- ============================================================================

ROLLBACK;

DROP INDEX IF EXISTS idx_bench_bd_uid;
DROP INDEX IF EXISTS idx_bench_bd_desc;
DROP INDEX IF EXISTS idx_bench_uid_bd;
DROP INDEX IF EXISTS idx_bench_username;
DROP INDEX IF EXISTS idx_bench_username_trgm;
DROP INDEX IF EXISTS idx_bench_bd;