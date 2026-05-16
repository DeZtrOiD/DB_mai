CREATE OR REPLACE FUNCTION lab_4.add_rating(
    p_user_id BIGINT,
    p_item_id BIGINT,
    p_rating SMALLINT,
    p_review TEXT DEFAULT NULL
)
RETURNS VOID AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM lab_4.users WHERE user_id = p_user_id) THEN
        RAISE EXCEPTION 'User not found';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM lab_4.content_items WHERE item_id = p_item_id) THEN
        RAISE EXCEPTION 'Content item not found';
    END IF;

    INSERT INTO lab_4.ratings(user_id, item_id, rating_value, review_text)
    VALUES (p_user_id, p_item_id, p_rating, p_review);

EXCEPTION
    WHEN unique_violation THEN
        RAISE EXCEPTION 'User already rated this item';
    WHEN check_violation THEN
        RAISE EXCEPTION 'Rating must be between 1 and 10';
END;
$$ LANGUAGE plpgsql;



CREATE OR REPLACE FUNCTION lab_4.add_to_collection(
    p_user_id BIGINT,
    p_item_id BIGINT
)
RETURNS VOID AS $$
BEGIN
    INSERT INTO lab_4.user_collections(user_id, item_id)
    VALUES (p_user_id, p_item_id);

EXCEPTION
    WHEN unique_violation THEN
        RAISE EXCEPTION 'Item already in collection';
    WHEN foreign_key_violation THEN
        RAISE EXCEPTION 'Invalid user or item';
END;
$$ LANGUAGE plpgsql;



CREATE OR REPLACE FUNCTION lab_4.get_avg_rating(p_item_id BIGINT)
RETURNS NUMERIC AS $$
DECLARE
    result NUMERIC;
BEGIN
    SELECT AVG(rating_value)
    INTO result
    FROM lab_4.ratings
    WHERE item_id = p_item_id;

    RETURN result;
END;
$$ LANGUAGE plpgsql;
