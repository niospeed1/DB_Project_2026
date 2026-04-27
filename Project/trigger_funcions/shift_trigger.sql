CREATE OR REPLACE FUNCTION check_individual_shift_constraints()
RETURNS TRIGGER AS $$
DECLARE
    v_type VARCHAR;
    v_date DATE;
    v_shift_type type_shift_types;
    v_count_month INTEGER;
    v_consecutive_nights INTEGER;
BEGIN

    SELECT personnel_type INTO v_type 
    FROM personnel 
    WHERE personnel_id = NEW.personnel_id;

    SELECT shift_date, shift_type INTO v_date, v_shift_type 
    FROM shift 
    WHERE shift_id = NEW.shift_id;

  IF EXISTS (
        SELECT 1 
        FROM personnel_shifts pe
        JOIN shift e ON pe.shift_id = e.shift_id
        WHERE pe.personnel_id = NEW.personnel_id
          AND e.shift_date = v_date 
          AND e.shift_type = v_shift_type
    ) THEN
        RAISE EXCEPTION 'Σύγκρουση Βαρδιών: Ο υπάλληλος είναι ήδη δηλωμένος σε άλλη βάρδια την ίδια ακριβώς μέρα και ώρα!';
    END IF;

    -- --- ΚΑΝΟΝΑΣ 1: Μηνιαία Όρια ---
    SELECT COUNT(*) INTO v_count_month
    FROM personnel_shifts pe
    JOIN shift e ON pe.shift_id = e.shift_id
    WHERE pe.personnel_id = NEW.personnel_id
      AND EXTRACT(MONTH FROM e.shift_date) = EXTRACT(MONTH FROM v_date)
      AND EXTRACT(YEAR FROM e.shift_date) = EXTRACT(YEAR FROM v_date);

    IF (v_type = 'Ιατρός' AND v_count_month >= 15) THEN
        RAISE EXCEPTION 'Ο ιατρός έχει συμπληρώσει το όριο (15) για αυτόν το μήνα.';
    ELSIF (v_type = 'Νοσηλευτής' AND v_count_month >= 20) THEN
        RAISE EXCEPTION 'Ο νοσηλευτής έχει συμπληρώσει το όριο (20) για αυτόν το μήνα.';
    ELSIF (v_type = 'Διοικητικό Προσωπικό' AND v_count_month >= 25) THEN
        RAISE EXCEPTION 'Ο διοικητικός υπάλληλος έχει συμπληρώσει το όριο (25).';
    END IF;

    IF EXISTS (
        SELECT 1 FROM personnel_shifts pe
        JOIN shift e ON pe.shift_id = e.shift_id
        WHERE pe.personnel_id = NEW.personnel_id
          AND (
            (e.shift_date = v_date AND v_shift_type = 'ΑΠΟΓΕΥΜΑ' AND e.shift_type = 'ΠΡΩΙ') OR
            (e.shift_date = v_date AND v_shift_type = 'ΠΡΩΙ' AND e.shift_type = 'ΑΠΟΓΕΥΜΑ') OR
            (e.shift_date = v_date AND v_shift_type = 'ΝΥΧΤΑ' AND e.shift_type = 'ΑΠΟΓΕΥΜΑ') OR
            (e.shift_date = v_date AND v_shift_type = 'ΑΠΟΓΕΥΜΑ' AND e.shift_type = 'ΝΥΧΤΑ') OR
            (e.shift_date = v_date - 1 AND v_shift_type = 'ΠΡΩΙ' AND e.shift_type = 'ΝΥΧΤΑ') OR
            (e.shift_date = v_date + 1 AND v_shift_type = 'ΝΥΧΤΑ' AND e.shift_type = 'ΠΡΩΙ')
          )
    ) THEN
        RAISE EXCEPTION 'Παραβίαση 8ωρης ανάπαυσης! Ο υπάλληλος δουλεύει σε διαδοχική βάρδια.';
    END IF;

    IF v_shift_type = 'ΝΥΧΤΑ' THEN
        SELECT COUNT(*) INTO v_consecutive_nights
        FROM shift e
        JOIN personnel_shifts pe ON e.shift_id = pe.shift_id
        WHERE pe.personnel_id = NEW.personnel_id 
          AND e.shift_type = 'ΝΥΧΤΑ'
          AND e.shift_date IN (v_date - 1, v_date - 2);

        IF v_consecutive_nights >= 2 THEN
            RAISE EXCEPTION 'Απαγορεύεται η 3η συνεχόμενη νυχτερινή βάρδια.';
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_check_individual_constraints
BEFORE INSERT ON personnel_shifts
FOR EACH ROW
EXECUTE FUNCTION check_individual_shift_constraints();




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

-- Δημιουργία του Trigger
CREATE TRIGGER trigger_validate_shift
BEFORE UPDATE ON shift
FOR EACH ROW
EXECUTE FUNCTION check_shift_validity();
