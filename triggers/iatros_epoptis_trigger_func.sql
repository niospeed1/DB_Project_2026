CREATE OR REPLACE FUNCTION validate_epopths_trigger_fn()
RETURNS TRIGGER AS $$
DECLARE
    v_epopths_vathmida VARCHAR;
BEGIN
    -- ΚΑΝΟΝΑΣ 1: Οι Διευθυντές απαγορεύεται να έχουν επόπτη
    IF NEW.vathmida = 'Διευθυντής' AND NEW.epoptis_id IS NOT NULL THEN
        RAISE EXCEPTION 'Παραβίαση Ιεραρχίας: Οι Διευθυντές δεν επιτρέπεται να έχουν επόπτη.';
    END IF;

    -- ΚΑΝΟΝΑΣ 2: Οι Ειδικευόμενοι υποχρεούνται να έχουν επόπτη
    IF NEW.vathmida = 'Ειδικευόμενος' AND NEW.epoptis_id IS NULL THEN
        RAISE EXCEPTION 'Παραβίαση Κανόνα: Οι Ειδικευόμενοι πρέπει υποχρεωτικά να έχουν επόπτη.';
    END IF;

    -- ΚΑΝΟΝΑΣ 3: Έλεγχος Ορθότητας Ιεραρχίας (αν έχει δοθεί επόπτης)
    IF NEW.epoptis_id IS NOT NULL THEN
        -- Βρίσκουμε τη βαθμίδα του γιατρού που πάει να μπει ως επόπτης
        SELECT vathmida INTO v_epopths_vathmida 
        FROM iatroi 
        WHERE iatros_id = NEW.epoptis_id;

        -- Έλεγχος ότι ο επόπτης υπάρχει στο σύστημα
        IF v_epopths_vathmida IS NULL THEN
            RAISE EXCEPTION 'Σφάλμα Δεδομένων: Ο επόπτης με ID % δεν υπάρχει στο σύστημα.', NEW.epoptis_id;
        END IF;

        -- Αυστηροί έλεγχοι ποιος μπορεί να επιβλέπει ποιον
        IF NEW.vathmida = 'Ειδικευόμενος' AND v_epopths_vathmida NOT IN ('Επιμελητής Β', 'Επιμελητής Α', 'Διευθυντής') THEN
            RAISE EXCEPTION 'Παραβίαση Ιεραρχίας: Ο επόπτης ενός Ειδικευόμενος πρέπει να είναι τουλάχιστον Επιμελητής Β.';
            
        ELSIF NEW.vathmida = 'Επιμελητής Β' AND v_epopths_vathmida NOT IN ('Επιμελητής Α', 'Διευθυντής') THEN
            RAISE EXCEPTION 'Παραβίαση Ιεραρχίας: Ο επόπτης ενός Επιμελητής Β πρέπει να είναι τουλάχιστον Επιμελητής Α.';
            
        ELSIF NEW.vathmida = 'Επιμελητής Α' AND v_epopths_vathmida != 'Διευθυντής' THEN
            RAISE EXCEPTION 'Παραβίαση Ιεραρχίας: Ο επόπτης ενός Επιμελητής Α πρέπει να είναι υποχρεωτικά Διευθυντής.';
        END IF;
    END IF;

    -- Αν όλα είναι σωστά, προχωράει το INSERT ή UPDATE
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


CREATE TRIGGER trg_check_iatroi_epopths
BEFORE INSERT OR UPDATE ON iatroi
FOR EACH ROW
EXECUTE FUNCTION validate_epopths_trigger_fn();