# Исследование индексирования и оптимизации запросов в PostgreSQL


---

# 1. Результаты исследования

## 1.1 Сценарий 1: Сложный фильтр (точное сравнение + диапазон)

**Текст запроса:**
```sql
SELECT user_id, username, birth_date, email
FROM lab_4.users
WHERE birth_date = '1990-05-15' AND user_id > 500000;
```

**Гипотеза:**  
Составной B-tree индекс `(birth_date, user_id)` ускорит запрос, так как позволит сначала отфильтровать строки по точному значению `birth_date`, затем эффективно применить диапазонное условие `user_id > 500000`, избежав полного сканирования таблицы.

**Созданный индекс:**
```sql
CREATE INDEX idx_users_bd_uid ON lab_4.users (birth_date, user_id);
```

**План выполнения до оптимизации:**
```
Gather  (cost=1000.42..19510.35 rows=25 width=43) (actual time=20.877..127.603 rows=25 loops=1)
  Workers Planned: 2
  Workers Launched: 2
  Buffers: shared hit=1250 read=8005
  ->  Parallel Index Scan using users_pkey on users  (cost=0.42..18507.85 rows=10 width=43) (actual time=20.639..108.385 rows=8 loops=3)
        Index Cond: (user_id > 500000)
        Filter: (birth_date = '1990-05-15'::date)
        Rows Removed by Filter: 166658
        Buffers: shared hit=1250 read=8005
Planning:
  Buffers: shared hit=23 read=3
Planning Time: 0.742 ms
Execution Time: 127.668 ms
```

**План выполнения после оптимизации:**
```
Bitmap Heap Scan on users  (cost=4.68..101.81 rows=25 width=43) (actual time=0.090..0.215 rows=25 loops=1)
  Recheck Cond: ((birth_date = '1990-05-15'::date) AND (user_id > 500000))
  Heap Blocks: exact=25
  Buffers: shared hit=25 read=4
  ->  Bitmap Index Scan on idx_users_bd_uid  (cost=0.00..4.67 rows=25 width=0) (actual time=0.076..0.076 rows=25 loops=1)
        Index Cond: ((birth_date = '1990-05-15'::date) AND (user_id > 500000))
        Buffers: shared read=4
Planning:
  Buffers: shared hit=18 read=1
Planning Time: 0.407 ms
Execution Time: 0.249 ms
```

**Сравнение времени выполнения:**

| Метрика | До оптимизации | После оптимизации | Изменение |
|---------|---------------|-----------------|-----------|
| Execution Time | 127.668 мс | 0.249 мс | Ускорение в 512 раз |
| Buffers read | 8005 | 4 | Уменьшение в 2001 раз |
| Rows Removed by Filter | 166658 | 0 | Фильтрация в индексе |

**Анализ изменений в плане:**  
Планировщик заменил параллельное сканирование по первичному ключу с последующей фильтрацией на `Bitmap Heap Scan`. Индекс позволил сразу найти нужные строки без чтения лишних страниц и без последующей фильтрации в памяти.

**Вывод:**  
Гипотеза подтвердилась. Составной индекс `(birth_date, user_id)` эффективен для запросов с точным сравнением и диапазоном. Порядок колонок критичен: сначала условие равенства (высокая селективность), затем диапазонное условие.

---

## 1.2. Сценарий 2: Сортировка с ограничением (ORDER BY + LIMIT)

**Текст запроса:**
```sql
SELECT user_id, username, birth_date
FROM lab_4.users
ORDER BY birth_date DESC
LIMIT 50;
```

**Гипотеза:**  
Индекс по `birth_date DESC` устранит узел `Sort`, так как данные в индексе уже отсортированы. Это позволит выполнить запрос через `Index Scan` с немедленным ограничением `LIMIT`.

**Созданный индекс:**
```sql
CREATE INDEX idx_users_bd_desc ON lab_4.users (birth_date DESC);
```

**План выполнения до оптимизации:**
```
Limit  (cost=32342.07..32347.90 rows=50 width=23) (actual time=1844.978..1850.102 rows=50 loops=1)
  Buffers: shared hit=6806 read=6602
  ->  Gather Merge  (cost=32342.07..129571.16 rows=833334 width=23) (actual time=1844.975..1850.093 rows=50 loops=1)
        Workers Planned: 2
        Workers Launched: 2
        Buffers: shared hit=6806 read=6602
        ->  Sort  (cost=31342.04..32383.71 rows=416667 width=23) (actual time=1733.304..1733.306 rows=40 loops=3)
              Sort Key: birth_date DESC
              Sort Method: top-N heapsort  Memory: 32kB
              Buffers: shared hit=6806 read=6602
              Worker 0:  Sort Method: top-N heapsort  Memory: 32kB
              Worker 1:  Sort Method: top-N heapsort  Memory: 32kB
              ->  Parallel Seq Scan on users  (cost=0.00..17500.67 rows=416667 width=23) (actual time=38.013..1654.549 rows=333333 loops=3)
                    Buffers: shared hit=6732 read=6602
Planning:
  Buffers: shared hit=25
Planning Time: 0.337 ms
Execution Time: 1850.154 ms
```

**План выполнения после оптимизации:**
```
Limit  (cost=0.42..4.02 rows=50 width=23) (actual time=0.155..1.207 rows=50 loops=1)
  Buffers: shared hit=26 read=27
  ->  Index Scan using idx_users_bd_desc on users  (cost=0.42..71803.66 rows=1000000 width=23) (actual time=0.152..1.183 rows=50 loops=1)
        Buffers: shared hit=26 read=27
Planning:
  Buffers: shared hit=15 read=1
Planning Time: 0.663 ms
Execution Time: 1.249 ms
```

**Сравнение времени выполнения:**

| Метрика | До оптимизации | После оптимизации | Изменение |
|---------|---------------|-----------------|-----------|
| Execution Time | 1850.154 мс | 1.249 мс | Ускорение в 1481 раз |
| Buffers read | 6602 | 27 | Уменьшение в 244 раза |
| Наличие узла Sort | Присутствует | Отсутствует | Устранён |

**Анализ изменений в плане:**  
Индекс с направлением `DESC` позволил планировщику использовать `Index Scan` и остановить выполнение после получения 50 строк. Узел `Sort` полностью исключён из плана.

**Вывод:**  
Гипотеза подтвердилась. Индекс с указанием направления сортировки идеально подходит для запросов с `ORDER BY ... DESC LIMIT`. Планировщик использует индекс для прямого доступа к данным в нужном порядке.

---

## 1.3. Сценарий 3: Альтернативные варианты индексирования

**Текст запроса:**
```sql
SELECT user_id, username, birth_date
FROM lab_4.users
WHERE birth_date >= '1985-01-01' AND username LIKE 'user_123%';
```

**Гипотеза:**  
- Вариант А `(birth_date, username)`: эффективен, если условие по дате более селективно  
- Вариант Б `(username, birth_date)`: эффективен, если префикс `username` более селективен  
Ожидалось, что вариант с более селективным полем первым даст лучший план.

**Созданные индексы:**
```sql
-- Вариант А
CREATE INDEX idx_users_bd_uid ON lab_4.users (birth_date, username);

-- Вариант Б  
CREATE INDEX idx_users_uid_bd ON lab_4.users (username, birth_date);
```

**План выполнения без индексов:**
```
Gather  (cost=1000.00..20589.50 rows=55 width=23) (actual time=1184.705..1187.999 rows=100 loops=1)
  Workers Planned: 2
  Workers Launched: 2
  Buffers: shared hit=6916 read=6418
  ->  Parallel Seq Scan on users  (cost=0.00..19584.00 rows=23 width=23) (actual time=788.324..1178.450 rows=33 loops=3)
        Filter: ((birth_date >= '1985-01-01'::date) AND ((username)::text ~~ 'user_123%'::text))
        Rows Removed by Filter: 333300
        Buffers: shared hit=6916 read=6418
Planning:
  Buffers: shared hit=10 read=4
Planning Time: 146.077 ms
Execution Time: 1188.024 ms
```

**План с Вариантом А `(birth_date, username)`:**
```
Gather  (cost=1000.00..20589.50 rows=55 width=23) (actual time=1.891..51.091 rows=100 loops=1)
  Workers Planned: 2
  Workers Launched: 2
  Buffers: shared hit=7076 read=6258
  ->  Parallel Seq Scan on users  (cost=0.00..19584.00 rows=23 width=23) (actual time=27.477..42.498 rows=33 loops=3)
        Filter: ((birth_date >= '1985-01-01'::date) AND ((username)::text ~~ 'user_123%'::text))
        Rows Removed by Filter: 333300
        Buffers: shared hit=7076 read=6258
Planning:
  Buffers: shared hit=18 read=1
Planning Time: 0.269 ms
Execution Time: 51.114 ms
```

**План с Вариантом Б `(username, birth_date)`:**
```
Gather  (cost=1000.00..20589.50 rows=55 width=23) (actual time=3.660..65.107 rows=100 loops=1)
  Workers Planned: 2
  Workers Launched: 2
  Buffers: shared hit=7236 read=6098
  ->  Parallel Seq Scan on users  (cost=0.00..19584.00 rows=23 width=23) (actual time=33.690..52.995 rows=33 loops=3)
        Filter: ((birth_date >= '1985-01-01'::date) AND ((username)::text ~~ 'user_123%'::text))
        Rows Removed by Filter: 333300
        Buffers: shared hit=7236 read=6098
Planning:
  Buffers: shared hit=19 read=1
Planning Time: 0.439 ms
Execution Time: 65.141 ms
```

**Сравнение времени выполнения:**

| Конфигурация | Execution Time | Использован индекс |
|-------------|---------------|-------------------|
| Без индекса | 1188.024 (80) мс | Нет |
| Вариант А | 51.114 мс | Нет |
| Вариант Б | 65.141 мс | Нет |

**Анализ изменений в плане:**  
Ни один из составных индексов не был использован планировщиком. Условие `username LIKE 'user_123%'` содержит префикс, но распределение значений `username` делает этот предикат недостаточно селективным. Условие `birth_date >= '1985-01-01'` охватывает около 75% строк. Планировщик оценил, что параллельное последовательное сканирование дешевле случайных чтений через индекс. При первом выполнении без инжекса время выполнения было порядка 1188 мс, при повторном около 80 мс, что объясняется расходами на планирование, кешем и некоторыми особенностями жесткого дистка с сильно исчерпанным ресурсом.

**Вывод:**  
Гипотеза частично опровергнута: ни один из составных индексов не был использован. Это демонстрирует важный принцип: индекс не гарантирует ускорение. При низкой селективности предикатов или высокой стоимости случайных чтений `Seq Scan` может быть оптимальным выбором.

---

## 1.4. Сценарий 4: Текстовый поиск (префикс, подстрока)

**Текст запроса А (префиксный поиск):**
```sql
SELECT user_id FROM lab_4.users WHERE username LIKE 'user_50000%';
```

**Гипотеза А:**  
Обычный B-tree индекс по `username` должен ускорить префиксный поиск, так как значения в индексе отсортированы лексикографически.

**Индекс:**
```sql
CREATE INDEX idx_users_username ON lab_4.users (username);
```

**План выполнения до оптимизации:**
```
Gather  (cost=1000.00..19552.33 rows=100 width=8) (actual time=78.240..82.974 rows=11 loops=1)
  Workers Planned: 2
  Workers Launched: 2
  Buffers: shared hit=7332 read=6002
  ->  Parallel Seq Scan on users  (cost=0.00..18542.33 rows=42 width=8) (actual time=37.999..75.568 rows=4 loops=3)
        Filter: ((username)::text ~~ 'user_50000%'::text)
        Rows Removed by Filter: 333330
        Buffers: shared hit=7332 read=6002
Planning:
  Buffers: shared hit=5
Planning Time: 0.095 ms
Execution Time: 82.997 ms
```

**План выполнения после оптимизации:**
```
Gather  (cost=1000.00..19552.33 rows=100 width=8) (actual time=9.839..78.209 rows=11 loops=1)
  Workers Planned: 2
  Workers Launched: 2
  Buffers: shared hit=7492 read=5842
  ->  Parallel Seq Scan on users  (cost=0.00..18542.33 rows=42 width=8) (actual time=34.569..65.325 rows=4 loops=3)
        Filter: ((username)::text ~~ 'user_50000%'::text)
        Rows Removed by Filter: 333330
        Buffers: shared hit=7492 read=5842
Planning:
  Buffers: shared hit=15 read=1
Planning Time: 0.772 ms
Execution Time: 78.256 ms
```

**Результаты А:**

| Конфигурация | Execution Time | План |
|-------------|---------------|------|
| Без индекса | 82.997 мс | Parallel Seq Scan |
| С B-tree | 78.256 мс | Parallel Seq Scan |

**Анализ А:**  
Планировщик не использовал B-tree индекс, так как параллельное последовательное сканирование оказалось дешевле для данного объёма выборки. Индекс технически применим, но экономически нецелесообразен.


---

**Текст запроса Б (поиск подстроки):**
```sql
SELECT user_id FROM lab_4.users WHERE username LIKE '%12345%';
```

**Гипотеза Б:**  
B-tree индекс не поддерживает поиск подстроки в середине строки. Для ускорения требуется расширение `pg_trgm` и GIN-индекс с оператором `gin_trgm_ops`.

**Индекс:**
```sql
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE INDEX idx_users_username_trgm ON lab_4.users USING gin (username gin_trgm_ops);
```

**План выполнения до оптимизации:**
```
Gather  (cost=1000.00..19552.33 rows=100 width=8) (actual time=2.188..65.082 rows=20 loops=1)
  Workers Planned: 2
  Workers Launched: 2
  Buffers: shared hit=7588 read=5746
  ->  Parallel Seq Scan on users  (cost=0.00..18542.33 rows=42 width=8) (actual time=3.810..59.041 rows=7 loops=3)
        Filter: ((username)::text ~~ '%12345%'::text)
        Rows Removed by Filter: 333327
        Buffers: shared hit=7588 read=5746
Planning Time: 0.065 ms
Execution Time: 65.110 ms
```

**План выполнения после оптимизации:**
```
Bitmap Heap Scan on users  (cost=40.77..416.04 rows=100 width=8) (actual time=1.507..1.724 rows=20 loops=1)
  Recheck Cond: ((username)::text ~~ '%12345%'::text)
  Heap Blocks: exact=12
  Buffers: shared hit=15 read=7
  ->  Bitmap Index Scan on idx_users_username_trgm  (cost=0.00..40.75 rows=100 width=0) (actual time=1.412..1.412 rows=20 loops=1)
        Index Cond: ((username)::text ~~ '%12345%'::text)
        Buffers: shared hit=10
Planning:
  Buffers: shared hit=22
Planning Time: 0.565 ms
Execution Time: 1.783 ms
```

**Сравнение времени выполнения (подстрока):**

| Метрика | До оптимизации | После оптимизации | Изменение |
|---------|---------------|-----------------|-----------|
| Execution Time | 65.110 мс | 1.783 мс | Ускорение в 36.5 раз |
| Тип сканирования | Parallel Seq Scan | Bitmap Heap Scan | Целевой доступ |
| Rows Removed by Filter | 333327 | 0 | Фильтрация в индексе |

**Вывод:**  
Гипотеза Б подтвердилась. Для префиксного поиска `LIKE 'prefix%'` B-tree индекс может не использоваться, если параллельный `Seq Scan` дешевле. Для поиска подстроки `LIKE '%substring%'` только GIN-индекс с `pg_trgm` даёт значимое ускорение.

---

## 1.5. Сценарий 5: Соединение таблиц (JOIN)

**Текст запроса:**
```sql
SELECT u.username, p.name, p.is_public
FROM lab_4.users u
JOIN lab_4.playlists p ON u.user_id = p.user_id
WHERE u.birth_date BETWEEN '1990-01-01' AND '2000-12-31'
  AND p.is_public = TRUE
LIMIT 100;
```

**Гипотеза:**  
Индексы на `users(birth_date)`, `playlists(user_id)` и `playlists(is_public)` заменят `Seq Scan` на `Index Scan` и ускорят выполнение запроса.

**Созданные индексы:**
```sql
CREATE INDEX idx_users_bd ON lab_4.users (birth_date);
CREATE INDEX idx_playlists_user ON lab_4.playlists (user_id);
CREATE INDEX idx_playlists_public ON lab_4.playlists (is_public);
```

**План выполнения до оптимизации:**
```
Limit  (cost=1000.42..7258.88 rows=1 width=29) (actual time=1872.955..1877.710 rows=0 loops=1)
  Buffers: shared hit=32 read=4135
  ->  Nested Loop  (cost=1000.42..7258.88 rows=1 width=29) (actual time=1872.951..1877.705 rows=0 loops=1)
        Buffers: shared hit=32 read=4135
        ->  Gather  (cost=1000.00..7250.43 rows=1 width=26) (actual time=1872.949..1877.671 rows=0 loops=1)
              Workers Planned: 2
              Workers Launched: 2
              Buffers: shared hit=32 read=4135
              ->  Parallel Seq Scan on playlists p  (cost=0.00..6250.33 rows=1 width=26) (actual time=1861.409..1861.410 rows=0 loops=3)
                    Filter: is_public
                    Rows Removed by Filter: 166667
                    Buffers: shared hit=32 read=4135
        ->  Index Scan using users_pkey on users u  (cost=0.42..8.45 rows=1 width=19) (never executed)
              Index Cond: (user_id = p.user_id)
              Filter: ((birth_date >= '1990-01-01'::date) AND (birth_date <= '2000-12-31'::date))
Planning:
  Buffers: shared hit=78 read=10 dirtied=2
Planning Time: 595.374 ms
Execution Time: 1877.780 ms
```

**План выполнения после оптимизации:**
```
Limit  (cost=0.85..12.89 rows=1 width=29) (actual time=0.020..0.021 rows=0 loops=1)
  Buffers: shared read=3
  ->  Nested Loop  (cost=0.85..12.89 rows=1 width=29) (actual time=0.018..0.019 rows=0 loops=1)
        Buffers: shared read=3
        ->  Index Scan using idx_playlists_public on playlists p  (cost=0.42..4.44 rows=1 width=26) (actual time=0.018..0.018 rows=0 loops=1)
              Index Cond: (is_public = true)
              Buffers: shared read=3
        ->  Index Scan using users_pkey on users u  (cost=0.42..8.45 rows=1 width=19) (never executed)
              Index Cond: (user_id = p.user_id)
              Filter: ((birth_date >= '1990-01-01'::date) AND (birth_date <= '2000-12-31'::date))
Planning:
  Buffers: shared hit=64 read=8
Planning Time: 0.629 ms
Execution Time: 0.041 ms
```

**Сравнение времени выполнения:**

| Метрика | До оптимизации | После оптимизации | Изменение |
|---------|---------------|-----------------|-----------|
| Execution Time | 1877.780 мс | 0.041 мс | Ускорение в 45800 раз |
| Scan на playlists | Parallel Seq Scan | Index Scan | Целевой доступ |
| Planning Time | 595.374 мс | 0.629 мс | Ускорение в 947 раз |
| Buffers read | 4135 | 3 | Уменьшение в 1378 раз |

**Анализ изменений в плане:**  
Индексы позволили планировщику заменить последовательное сканирование таблицы `playlists` на индексный доступ. Особенно заметен выигрыш во времени планирования: с индексами планировщик быстрее находит оптимальный план.

**Вывод:**  
Гипотеза подтвердилась. Индексы на полях фильтрации и соединения критически важны для сложных запросов. Для JOIN-запросов рекомендуется индексировать внешние ключи и поля в `WHERE` с высокой селективностью.

---

## 1.6. Сценарий 6: Негативный (индекс не помогает)

**Текст запроса:**
```sql
SELECT user_id, username FROM lab_4.users WHERE birth_date > '1900-01-01';
```

**Гипотеза:**  
Условие `birth_date > '1900-01-01'` охватывает практически все строки таблицы. В этом случае `Seq Scan` должен быть дешевле `Index Scan`, так как случайные чтения индекса дороже последовательных.

**Созданный индекс:**
```sql
CREATE INDEX idx_users_bd ON lab_4.users (birth_date);
```

**План выполнения до оптимизации:**
```
Seq Scan on users  (cost=0.00..25834.00 rows=999900 width=19) (actual time=0.149..175.815 rows=1000000 loops=1)
  Filter: (birth_date > '1900-01-01'::date)
  Buffers: shared hit=7787 read=5547
Planning:
  Buffers: shared hit=5 dirtied=1
Planning Time: 0.283 ms
Execution Time: 229.157 ms
```

**План выполнения после оптимизации:**
```
Seq Scan on users  (cost=0.00..25834.00 rows=1000000 width=19) (actual time=0.101..165.144 rows=1000000 loops=1)
  Filter: (birth_date > '1900-01-01'::date)
  Buffers: shared hit=7883 read=5451
Planning:
  Buffers: shared hit=16 read=4
Planning Time: 0.588 ms
Execution Time: 211.869 ms
```

**Сравнение времени выполнения:**

| Метрика | До оптимизации | После оптимизации | Изменение |
|---------|---------------|-----------------|-----------|
| Execution Time | 229.157 мс | 211.869 мс | Разница в пределах шума |
| Тип сканирования | Seq Scan | Seq Scan | Индекс корректно проигнорирован |

**Анализ изменений в плане:**  
Планировщик корректно оценил стоимость планов и выбрал `Seq Scan`, так как селективность условия близка к 100%, а стоимость случайных чтений индекса превышает стоимость последовательного сканирования.

**Вывод:**  
Гипотеза подтвердилась. Индекс не является универсальным решением. Его создание оправдано только при достаточной селективности предиката и частом использовании в запросах.

---

# 2. Влияние индексов на операции INSERT / UPDATE

**Методика:**  
- Объём вставки: 2000 строк в `lab_4.users`  
- Объём обновления: 1000 строк по диапазону `user_id`  
- Конфигурации: без индексов, с одним B-tree, с одним GIN, со всеми 6 индексами  
- Все операции выполнялись в транзакции с `ROLLBACK`

**Результаты:**

| Конфигурация | INSERT 2000 строк (мс) | UPDATE 1000 строк (мс) |
|-------------|----------------------|----------------------|
| Без индексов | 54.083 | 48.0 |
| +1 B-tree | 72.255 | 39.560 |
| +1 GIN (trgm) | 88.853 | 262.205 |
| Все 6 индексов | 275.992 | 108.802 |

**Оверхеад относительно базовой конфигурации:**

| Конфигурация | Оверхеад INSERT | Оверхеад UPDATE |
|-------------|----------------|-----------------|
| +1 B-tree | +33.6% | -18.75%* |
| +1 GIN | +64.3% | +446.2% |
| Все 6 индексов | +410.5% | +126.6% |

*Отрицательный оверхеад для UPDATE объясняется кэшированием

**Анализ:**  
Каждый дополнительный индекс увеличивает время вставки и объём записываемых данных, так как требует обновления структуры индекса. GIN-индекс особенно ресурсоёмкий из-за сложной внутренней структуры. Для операций обновления влияние индексов менее предсказуемо из-за влияния кэша.

**Вывод:**  
Индексы ускоряют чтение, но замедляют запись. Для таблиц с преобладанием операций чтения оверхеад приемлем. Для write-heavy таблиц рекомендуется минимизировать количество индексов и использовать частичные индексы.

---

# 3. Общие выводы

1. B-tree индекс является универсальным выбором для большинства сценариев: равенство, диапазоны, сортировка.
2. Для поиска подстрок в тексте необходим GIN-индекс с расширением `pg_trgm`.
3. Порядок колонок в составном индексе критичен: сначала условия равенства, затем диапазоны, затем сортировка.
4. Планировщик PostgreSQL не всегда использует индекс: при низкой селективности `Seq Scan` может быть оптимальным.
5. Индексы имеют стоимость: каждый индекс замедляет операции вставки и обновления и увеличивает объём хранилища.
6. Актуальная статистика важна для корректной работы планировщика: рекомендуется выполнять `ANALYZE` после массовой загрузки данных.
