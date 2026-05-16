CREATE OR REPLACE FUNCTION lab_6.check_single_details()
RETURNS TRIGGER AS $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM lab_6.book_details WHERE item_id = NEW.item_id
    ) OR EXISTS (
        SELECT 1 FROM lab_6.film_details WHERE item_id = NEW.item_id
    ) OR EXISTS (
        SELECT 1 FROM lab_6.music_details WHERE item_id = NEW.item_id
    ) THEN
        RAISE EXCEPTION 'Item already has details in another table';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_book_details_check
BEFORE INSERT ON lab_6.book_details
FOR EACH ROW EXECUTE FUNCTION lab_6.check_single_details();

CREATE TRIGGER trg_film_details_check
BEFORE INSERT ON lab_6.film_details
FOR EACH ROW EXECUTE FUNCTION lab_6.check_single_details();

CREATE TRIGGER trg_music_details_check
BEFORE INSERT ON lab_6.music_details
FOR EACH ROW EXECUTE FUNCTION lab_6.check_single_details();



CREATE OR REPLACE FUNCTION lab_6.limit_playlists()
RETURNS TRIGGER AS $$
DECLARE
    cnt INT;
BEGIN
    SELECT COUNT(*) INTO cnt
    FROM lab_6.playlists
    WHERE user_id = NEW.user_id;

    IF cnt >= 10 THEN
        RAISE EXCEPTION 'User cannot have more than 10 playlists';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_limit_playlists
BEFORE INSERT ON lab_6.playlists
FOR EACH ROW EXECUTE FUNCTION lab_6.limit_playlists();


CREATE TABLE lab_6.rating_audit (
    audit_id BIGSERIAL PRIMARY KEY,
    user_id BIGINT,
    item_id BIGINT,
    action_type TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE OR REPLACE FUNCTION lab_6.audit_rating()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO lab_6.rating_audit(user_id, item_id, action_type)
    VALUES (NEW.user_id, NEW.item_id, TG_OP);

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_rating_audit
AFTER INSERT OR UPDATE ON lab_6.ratings
FOR EACH ROW EXECUTE FUNCTION lab_6.audit_rating();

