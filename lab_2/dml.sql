
INSERT INTO lab_2.users (username, birth_date, email, password_hash)
VALUES ('new_user', '2000-01-01', 'new_user@mail.com', md5('password'));


INSERT INTO lab_2.ratings (user_id, item_id, rating_value, review_text)
VALUES (501, 10, 8, 'Nice content');


UPDATE lab_2.ratings
SET rating_value = 9,
    review_text = 'Actually very good'
WHERE user_id = 501 AND item_id = 10;


DELETE FROM lab_2.ratings
WHERE user_id = 501 AND item_id = 10;



INSERT INTO lab_2.playlists (user_id, name, description, is_public)
VALUES (10, 'My Favorites', 'Best content ever', true);

WITH new_playlist AS (
    INSERT INTO lab_2.playlists (user_id, name, description)
    VALUES (10, 'Test playlist', 'test')
    RETURNING playlist_id
)
INSERT INTO lab_2.playlist_items (playlist_id, item_id)
SELECT playlist_id, 25 FROM new_playlist;

UPDATE lab_2.playlists
SET description = 'Updated description'
WHERE playlist_id = 1001;

DELETE FROM lab_2.playlist_items
WHERE playlist_id = 1001 AND item_id = 30;
