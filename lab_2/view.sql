
CREATE OR REPLACE VIEW lab_2.v_content_ratings AS
SELECT
    ci.item_id,
    ci.title,
    COUNT(r.rating_value) AS ratings_count,
    ROUND(AVG(r.rating_value), 2) AS avg_rating
FROM lab_2.content_items ci
LEFT JOIN lab_2.ratings r ON r.item_id = ci.item_id
GROUP BY ci.item_id, ci.title;



CREATE OR REPLACE VIEW lab_2.v_user_activity AS
SELECT
    u.user_id,
    u.username,
    COUNT(DISTINCT uc.item_id) AS items_in_collection,
    COUNT(DISTINCT r.item_id) AS rated_items,
    COUNT(DISTINCT p.playlist_id) AS playlists_count
FROM lab_2.users u
LEFT JOIN lab_2.user_collections uc ON uc.user_id = u.user_id
LEFT JOIN lab_2.ratings r ON r.user_id = u.user_id
LEFT JOIN lab_2.playlists p ON p.user_id = u.user_id
GROUP BY u.user_id, u.username;



CREATE OR REPLACE VIEW lab_2.v_top_content AS
SELECT
    ci.item_id,
    ci.title,
    AVG(r.rating_value) AS avg_rating,
    COUNT(r.rating_value) AS ratings_count
FROM lab_2.content_items ci
JOIN lab_2.ratings r ON r.item_id = ci.item_id
GROUP BY ci.item_id, ci.title
HAVING COUNT(r.rating_value) > 5
ORDER BY avg_rating DESC;