-- топ среднего рейтинга
SELECT 
    ci.item_id,
    ci.title,
    COUNT(r.rating_value) AS ratings_count,
    AVG(r.rating_value) AS avg_rating
FROM lab_2.content_items ci
LEFT JOIN lab_2.ratings r ON ci.item_id = r.item_id
GROUP BY ci.item_id, ci.title
HAVING COUNT(r.rating_value) > 2
ORDER BY avg_rating DESC NULLS LAST
LIMIT 10;


-- количество контента по жанрам 
SELECT 
    g.name AS genre,
    COUNT(cg.item_id) AS total_items
FROM lab_2.genres g
LEFT JOIN lab_2.content_genres cg ON g.genre_id = cg.genre_id
GROUP BY g.name
HAVING COUNT(cg.item_id) > 50
ORDER BY total_items DESC;


-- самые активные пользователи + последняя активность 
SELECT 
    u.user_id,
    u.username,
    COUNT(r.item_id) AS ratings_count,
    MAX(r.rated_at) AS last_activity
FROM lab_2.users u
LEFT JOIN lab_2.ratings r ON u.user_id = r.user_id
GROUP BY u.user_id, u.username
ORDER BY ratings_count DESC
LIMIT 10;