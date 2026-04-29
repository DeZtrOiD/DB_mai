SELECT
    ci.item_id,
    ci.title,
    g.name AS genre
FROM lab_2.content_items ci
JOIN lab_2.content_genres cg ON cg.item_id = ci.item_id
JOIN lab_2.genres g ON g.genre_id = cg.genre_id
ORDER BY ci.item_id;


SELECT
    u.username,
    ci.title,
    uc.user_id
FROM lab_2.user_collections uc
JOIN lab_2.users u ON u.user_id = uc.user_id
JOIN lab_2.content_items ci ON ci.item_id = uc.item_id;



SELECT
    ci.title,
    COUNT(r.rating_value) AS ratings_count,
    AVG(r.rating_value) AS avg_rating
FROM lab_2.content_items ci
JOIN lab_2.ratings r ON r.item_id = ci.item_id
GROUP BY ci.item_id, ci.title
ORDER BY avg_rating DESC NULLS LAST;



SELECT
    p.name AS playlist,
    u.username
FROM lab_2.playlists p
JOIN lab_2.users u ON u.user_id = p.user_id;



SELECT
    ci.title,
    a.name AS author,
    r.role_name
FROM lab_2.content_items ci
JOIN lab_2.content_credits cc ON cc.item_id = ci.item_id
JOIN lab_2.authors a ON a.author_id = cc.author_id
JOIN lab_2.roles r ON r.role_id = cc.role_id;
