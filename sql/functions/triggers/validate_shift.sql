CREATE OR REPLACE FUNCTION check_shift_validity()
RETURNS TRIGGER AS $$
DECLARE
    count_doctors INTEGER;
    count_nurses INTEGER;
    count_admins INTEGER;
    has_apprentice BOOLEAN;
    has_supervisor BOOLEAN;
BEGIN

    IF (NEW.shift_status = 'COMPLETED' AND OLD.shift_status = 'DRAFT') THEN
        
        SELECT 
            COUNT(*) FILTER (WHERE p.personnel_type = 'Ιατρός'),
            COUNT(*) FILTER (WHERE p.personnel_type = 'Νοσηλευτής'),
            COUNT(*) FILTER (WHERE p.personnel_type = 'Διοικητικό Προσωπικό') 

        INTO count_doctors, count_nurses, count_admins
        FROM personnel_shifts pe
        JOIN personnel p ON pe.personnel_id = p.personnel_id
        WHERE pe.shift_id = NEW.shift_id;

        IF COALESCE(count_doctors, 0) < 3 OR COALESCE(count_nurses, 0) < 6 OR COALESCE(count_admins, 0) < 2 THEN
            RAISE EXCEPTION 'Ανεπαρκές προσωπικό: Απαιτούνται 3 ιατροί, 6 νοσηλευτές και 2 διοικητικοί.';
        END IF;

        SELECT 
            EXISTS(SELECT 1 FROM personnel_shifts pe 
                   JOIN doctors i ON pe.personnel_id = i.doctor_id 
                   WHERE pe.shift_id = NEW.shift_id AND i.rank = 'Ειδικευόμενος'),
            EXISTS(SELECT 1 FROM personnel_shifts pe 
                   JOIN doctors i ON pe.personnel_id = i.doctor_id 
                   WHERE pe.shift_id = NEW.shift_id AND i.rank IN ('Επιμελητής Α', 'Διευθυντής'))
        INTO has_apprentice, has_supervisor;

        IF has_apprentice AND NOT has_supervisor THEN
            RAISE EXCEPTION 'Βρέθηκε Ειδικευόμενος ιατρός χωρίς την παρουσία Επιμελητή Α ή Διευθυντή.';
        END IF;

    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER validate_shift
BEFORE UPDATE ON shift
FOR EACH ROW
EXECUTE FUNCTION check_shift_validity();