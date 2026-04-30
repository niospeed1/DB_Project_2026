CREATE OR REPLACE FUNCTION check_room_capacity()
RETURNS TRIGGER AS $$
DECLARE
    current_patients INT;
    max_capacity INT;
BEGIN
    
    SELECT COUNT(*) INTO current_patients 
    FROM admission 
    WHERE room_id = NEW.room_id AND discharge_date IS NULL;

    
    SELECT capacity INTO max_capacity 
    FROM rooms 
    WHERE room_id = NEW.room_id;


    IF current_patients >= max_capacity THEN
        RAISE EXCEPTION 'Ο θάλαμος με ID % είναι πλήρης! (Χωρητικότητα: %)', NEW.room_id, max_capacity;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_check_capacity
BEFORE INSERT ON admission
FOR EACH ROW
EXECUTE FUNCTION check_room_capacity();




CREATE OR REPLACE FUNCTION update_ward_status()
RETURNS TRIGGER AS $$
BEGIN

    UPDATE rooms 
    SET room_status = CASE 
        WHEN (SELECT COUNT(*) FROM admission WHERE room_id = NEW.room_id AND discharge_date IS NULL) >= capacity 
        THEN 'Κατειλημμέν0'
        ELSE 'Διαθέσιμο'
    END
    WHERE room_id = NEW.room_id;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_ward_status
AFTER INSERT OR UPDATE OF discharge_date ON admission
FOR EACH ROW
EXECUTE FUNCTION update_ward_status();