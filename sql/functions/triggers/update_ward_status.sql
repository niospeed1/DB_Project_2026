CREATE OR REPLACE FUNCTION update_ward_status()
RETURNS TRIGGER AS $$
BEGIN

    UPDATE rooms 
    SET room_status = CASE 
        WHEN (SELECT COUNT(*) FROM admission WHERE room_id = NEW.room_id AND discharge_date IS NULL) >= capacity 
        THEN 'Κατειλημμένο'
        ELSE 'Διαθέσιμο'
    END
    WHERE room_id = NEW.room_id;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_ward_status
AFTER INSERT OR UPDATE OF discharge_date ON admission
FOR EACH ROW
EXECUTE FUNCTION update_ward_status();
