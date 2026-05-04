CREATE OR REPLACE FUNCTION prevent_allergic_prescription()
RETURNS TRIGGER AS $$
DECLARE
    v_patient_allergy TEXT;
BEGIN
    -- 1. Βρίσκουμε τη μοναδική αλλεργία του ασθενή
    SELECT allergies INTO v_patient_allergy
    FROM patients
    WHERE patient_id = NEW.patient_id;

    -- 2. Αν ο ασθενής έχει αλλεργία, κάνουμε τον έλεγχο
    IF v_patient_allergy IS NOT NULL THEN
        -- Ψάχνουμε αν το φάρμακο έχει την ουσία (ΑΓΝΟΩΝΤΑΣ ΠΕΖΑ/ΚΕΦΑΛΑΙΑ)
        IF EXISTS (
            SELECT 1 
            FROM medicine_substances 
            WHERE drug_id = NEW.drug_id 
              -- Η ΜΑΓΕΙΑ ΕΙΝΑΙ ΣΕ ΑΥΤΗ ΤΗ ΓΡΑΜΜΗ:
              AND LOWER(active_substance) = LOWER(v_patient_allergy)
        ) THEN
            RAISE EXCEPTION 'ΑΠΑΓΟΡΕΥΣΗ: Ο ασθενής (ID: %) έχει αλλεργία στη δραστική ουσία "%" αυτού του φαρμάκου!', NEW.patient_id, v_patient_allergy;
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER check_allergy_before_prescription
BEFORE INSERT OR UPDATE ON prescription
FOR EACH ROW
EXECUTE FUNCTION prevent_allergic_prescription();
