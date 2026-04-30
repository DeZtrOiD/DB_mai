-- 1
SELECT lab_3.add_rating(1, 10, 8::smallint, 'Nice');
SELECT lab_3.add_rating(1, 10, 8::smallint, 'Nice');
-- User already rated this item

-- 2
SELECT lab_3.add_to_collection(1, 20);

-- 3 
SELECT lab_3.get_avg_rating(10);

-- 4
INSERT INTO lab_3.book_details(item_id, isbn) VALUES (1, '123');
INSERT INTO lab_3.film_details(item_id, duration_minutes) VALUES (1, 120);
-- Item already has details

-- 5
INSERT INTO lab_3.playlists(user_id, name) VALUES (1, 'p1');
INSERT INTO lab_3.playlists(user_id, name) VALUES (1, 'p2');
INSERT INTO lab_3.playlists(user_id, name) VALUES (1, 'p3');
INSERT INTO lab_3.playlists(user_id, name) VALUES (1, 'p4');
INSERT INTO lab_3.playlists(user_id, name) VALUES (1, 'p5');
INSERT INTO lab_3.playlists(user_id, name) VALUES (1, 'p6');
INSERT INTO lab_3.playlists(user_id, name) VALUES (1, 'p7');
INSERT INTO lab_3.playlists(user_id, name) VALUES (1, 'p8');
INSERT INTO lab_3.playlists(user_id, name) VALUES (1, 'p9');
INSERT INTO lab_3.playlists(user_id, name) VALUES (1, 'p10');
INSERT INTO lab_3.playlists(user_id, name) VALUES (1, 'p11');
-- User cannot have more than 10 playlists
