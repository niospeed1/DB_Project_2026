CREATE OR REPLACE FUNCTION validate_supervisor_trigger_fn()
RETURNS TRIGGER AS $$
DECLARE
    v_supervisor_rank VARCHAR;
BEGIN

    IF NEW.rank = 'Διευθυντής' AND NEW.supervisor_id IS NOT NULL THEN
        RAISE EXCEPTION 'Παραβίαση Ιεραρχίας: Οι Διευθυντές δεν επιτρέπεται να έχουν επόπτη.';
    END IF;

    IF NEW.rank = 'Ειδικευόμενος' AND NEW.supervisor_id IS NULL THEN
        RAISE EXCEPTION 'Παραβίαση Κανόνα: Οι Ειδικευόμενοι πρέπει υποχρεωτικά να έχουν επόπτη.';
    END IF;

    IF NEW.supervisor_id IS NOT NULL THEN

        SELECT rank INTO v_supervisor_rank 
        FROM doctors 
        WHERE doctor_id = NEW.supervisor_id;

        IF v_supervisor_rank IS NULL THEN
            RAISE EXCEPTION 'Σφάλμα Δεδομένων: Ο επόπτης με ID % δεν υπάρχει στο σύστημα.', NEW.supervisor_id;
        END IF;

        -- Αυστηροί έλεγχοι ποιος μπορεί να επιβλέπει ποιον
        IF NEW.rank = 'Ειδικευόμενος' AND v_supervisor_rank NOT IN ('Επιμελητής Β', 'Επιμελητής Α', 'Διευθυντής') THEN
            RAISE EXCEPTION 'Παραβίαση Ιεραρχίας: Ο επόπτης ενός Ειδικευόμενος πρέπει να είναι τουλάχιστον Επιμελητής Β.';
            
        ELSIF NEW.rank = 'Επιμελητής Β' AND v_supervisor_rank NOT IN ('Επιμελητής Α', 'Διευθυντής') THEN
            RAISE EXCEPTION 'Παραβίαση Ιεραρχίας: Ο επόπτης ενός Επιμελητής Β πρέπει να είναι τουλάχιστον Επιμελητής Α.';
            
        ELSIF NEW.rank = 'Επιμελητής Α' AND v_supervisor_rank != 'Διευθυντής' THEN
            RAISE EXCEPTION 'Παραβίαση Ιεραρχίας: Ο επόπτης ενός Επιμελητής Α πρέπει να είναι υποχρεωτικά Διευθυντής.';
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


CREATE TRIGGER trg_check_doctor_supervisor
BEFORE INSERT OR UPDATE ON doctors
FOR EACH ROW
EXECUTE FUNCTION validate_supervisor_trigger_fn();