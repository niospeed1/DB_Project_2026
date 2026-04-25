CREATE OR REPLACE FUNCTION check_individual_shift_constraints()
RETURNS TRIGGER AS $$
DECLARE
    v_typos VARCHAR;
    v_hmeromhnia DATE;
    v_vardia typos_vardias;
    v_count_month INTEGER;
    v_consecutive_nights INTEGER;
BEGIN
    -- 1. Βρίσκουμε τον τύπο του υπαλλήλου από τον πίνακα prosopiko
    SELECT prosopiko_typos INTO v_typos 
    FROM prosopiko 
    WHERE prosopiko_id = NEW.prosopiko_id;

    -- 2. Βρίσκουμε την ημερομηνία και τη βάρδια που πάμε να τον προσθέσουμε
    SELECT hmeromhnia, vardia INTO v_hmeromhnia, v_vardia 
    FROM efhmeria 
    WHERE efhmeria_id = NEW.efhmeria_id;

  IF EXISTS (
        SELECT 1 
        FROM prosopiko_efhmerias pe
        JOIN efhmeria e ON pe.efhmeria_id = e.efhmeria_id
        WHERE pe.prosopiko_id = NEW.prosopiko_id
          AND e.hmeromhnia = v_hmeromhnia 
          AND e.vardia = v_vardia
    ) THEN
        RAISE EXCEPTION 'Σύγκρουση Βαρδιών: Ο υπάλληλος είναι ήδη δηλωμένος σε άλλη βάρδια την ίδια ακριβώς μέρα και ώρα!';
    END IF;

    -- --- ΚΑΝΟΝΑΣ 1: Μηνιαία Όρια ---
    SELECT COUNT(*) INTO v_count_month
    FROM prosopiko_efhmerias pe
    JOIN efhmeria e ON pe.efhmeria_id = e.efhmeria_id
    WHERE pe.prosopiko_id = NEW.prosopiko_id
      AND EXTRACT(MONTH FROM e.hmeromhnia) = EXTRACT(MONTH FROM v_hmeromhnia)
      AND EXTRACT(YEAR FROM e.hmeromhnia) = EXTRACT(YEAR FROM v_hmeromhnia);

    IF (v_typos = 'Ιατρός' AND v_count_month >= 15) THEN
        RAISE EXCEPTION 'Ο ιατρός έχει συμπληρώσει το όριο (15) για αυτόν το μήνα.';
    ELSIF (v_typos = 'Νοσηλευτής' AND v_count_month >= 20) THEN
        RAISE EXCEPTION 'Ο νοσηλευτής έχει συμπληρώσει το όριο (20) για αυτόν το μήνα.';
    ELSIF (v_typos = 'Διοικητικό Προσωπικό' AND v_count_month >= 25) THEN
        RAISE EXCEPTION 'Ο διοικητικός υπάλληλος έχει συμπληρώσει το όριο (25).';
    END IF;

    -- --- ΚΑΝΟΝΑΣ 2: 8ωρη Ανάπαυση (Αποτροπή Διαδοχικών Βαρδιών) ---
    -- Ελέγχουμε αν υπάρχει βάρδια χωρίς καθόλου κενό ενδιάμεσα
    IF EXISTS (
        SELECT 1 FROM prosopiko_efhmerias pe
        JOIN efhmeria e ON pe.efhmeria_id = e.efhmeria_id
        WHERE pe.prosopiko_id = NEW.prosopiko_id
          AND (
            (e.hmeromhnia = v_hmeromhnia AND v_vardia = 'ΑΠΟΓΕΥΜΑ' AND e.vardia = 'ΠΡΩΙ') OR
            (e.hmeromhnia = v_hmeromhnia AND v_vardia = 'ΠΡΩΙ' AND e.vardia = 'ΑΠΟΓΕΥΜΑ') OR
            (e.hmeromhnia = v_hmeromhnia AND v_vardia = 'ΝΥΧΤΑ' AND e.vardia = 'ΑΠΟΓΕΥΜΑ') OR
            (e.hmeromhnia = v_hmeromhnia AND v_vardia = 'ΑΠΟΓΕΥΜΑ' AND e.vardia = 'ΝΥΧΤΑ') OR
            (e.hmeromhnia = v_hmeromhnia - 1 AND v_vardia = 'ΠΡΩΙ' AND e.vardia = 'ΝΥΧΤΑ') OR
            (e.hmeromhnia = v_hmeromhnia + 1 AND v_vardia = 'ΝΥΧΤΑ' AND e.vardia = 'ΠΡΩΙ')
          )
    ) THEN
        RAISE EXCEPTION 'Παραβίαση 8ωρης ανάπαυσης! Ο υπάλληλος δουλεύει σε διαδοχική βάρδια.';
    END IF;

    -- --- ΚΑΝΟΝΑΣ 3: Μέγιστο 3 συνεχόμενες Νύχτες ---
    IF v_vardia = 'ΝΥΧΤΑ' THEN
        SELECT COUNT(*) INTO v_consecutive_nights
        FROM efhmeria e
        JOIN prosopiko_efhmerias pe ON e.efhmeria_id = pe.efhmeria_id
        WHERE pe.prosopiko_id = NEW.prosopiko_id 
          AND e.vardia = 'ΝΥΧΤΑ'
          AND e.hmeromhnia IN (v_hmeromhnia - 1, v_hmeromhnia - 2);

        IF v_consecutive_nights >= 2 THEN
            RAISE EXCEPTION 'Απαγορεύεται η 3η συνεχόμενη νυχτερινή βάρδια.';
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Δημιουργία του Trigger που καλεί τη συνάρτηση
CREATE TRIGGER trigger_check_individual_constraints
BEFORE INSERT ON prosopiko_efhmerias
FOR EACH ROW
EXECUTE FUNCTION check_individual_shift_constraints();




/////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////




CREATE OR REPLACE FUNCTION check_efhmeria_validity()
RETURNS TRIGGER AS $$
DECLARE
    count_iatroi INTEGER;
    count_nosileutes INTEGER;
    count_dioikitikoi INTEGER;
    has_eidikeuomenos BOOLEAN;
    has_supervisor BOOLEAN;
BEGIN
    -- Κάνουμε τον έλεγχο ΜΟΝΟ αν ο χρήστης προσπαθεί να οριστικοποιήσει τη βάρδια
    IF (NEW.status = 'COMPLETED' AND OLD.status = 'DRAFT') THEN
        
        -- 1. Μετράμε το προσωπικό της βάρδιας
        SELECT 
            COUNT(*) FILTER (WHERE p.prosopiko_typos = 'Ιατρός'),
            COUNT(*) FILTER (WHERE p.prosopiko_typos = 'Νοσηλευτής'),
            COUNT(*) FILTER (WHERE p.prosopiko_typos = 'Διοικητικό Προσωπικό') 
            -- (Προσοχή: Βάλε ακριβώς το string που έχεις στον τύπο προσωπικού στη βάση σου)
        INTO count_iatroi, count_nosileutes, count_dioikitikoi
        FROM prosopiko_efhmerias pe
        JOIN prosopiko p ON pe.prosopiko_id = p.prosopiko_id
        WHERE pe.efhmeria_id = NEW.efhmeria_id;

        -- 2. Ελέγχουμε τα ελάχιστα νούμερα
        IF COALESCE(count_iatroi, 0) < 3 OR COALESCE(count_nosileutes, 0) < 6 OR COALESCE(count_dioikitikoi, 0) < 2 THEN
            RAISE EXCEPTION 'Ανεπαρκές προσωπικό: Απαιτούνται 3 ιατροί, 6 νοσηλευτές και 2 διοικητικοί.';
        END IF;

        -- 3. Έλεγχος Ιεραρχίας Ιατρών
        -- Πλέον κάνουμε JOIN με τον πίνακα iatros
        SELECT 
            EXISTS(SELECT 1 FROM prosopiko_efhmerias pe 
                   JOIN iatroi i ON pe.prosopiko_id = i.iatros_id 
                   WHERE pe.efhmeria_id = NEW.efhmeria_id AND i.vathmida = 'Ειδικευόμενος'),
            EXISTS(SELECT 1 FROM prosopiko_efhmerias pe 
                   JOIN iatroi i ON pe.prosopiko_id = i.iatros_id 
                   WHERE pe.efhmeria_id = NEW.efhmeria_id AND i.vathmida IN ('Επιμελητής Α', 'Διευθυντής'))
        INTO has_eidikeuomenos, has_supervisor;

        IF has_eidikeuomenos AND NOT has_supervisor THEN
            RAISE EXCEPTION 'Βρέθηκε Ειδικευόμενος ιατρός χωρίς την παρουσία Επιμελητή Α ή Διευθυντή.';
        END IF;

    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Δημιουργία του Trigger
CREATE TRIGGER trigger_validate_efhmeria
BEFORE UPDATE ON efhmeria
FOR EACH ROW
EXECUTE FUNCTION check_efhmeria_validity();




