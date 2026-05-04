CREATE OR REPLACE PROCEDURE populate_medical_acts()
LANGUAGE plpgsql
AS $$
DECLARE
    rec RECORD;
    v_category VARCHAR(50);
    v_type_id INT;
    v_duration INT;
    v_diff INT;
    v_cost_ken INT;
    v_location INT;
    v_surgeon_id INT;
    v_new_medical_act_id INT;
    v_counter INT := 1;
BEGIN
    -- 1. Επιλέγουμε 600 τυχαίες νοσηλείες 
    -- (προαιρετικά βάζουμε WHERE medical_act_id IS NULL για να μην πειράξουμε ήδη συμπληρωμένα)
    FOR rec IN 
        SELECT admission_id, admission_date, discharge_date 
        FROM admission 
        WHERE medical_act_id IS NULL
        ORDER BY random() 
        LIMIT 600
    LOOP
        -- 2. Καθορισμός Κατηγορίας με βάση τον μετρητή
        -- 1-300: Χειρουργική, 301-450: Διαγνωστική, 451-600: Θεραπευτική
        IF v_counter <= 300 THEN
            v_category := 'Χειρουργική';
        ELSIF v_counter <= 450 THEN
            v_category := 'Διαγνωστική';
        ELSE
            v_category := 'Θεραπευτική';
        END IF;

        -- 3. Τυχαίος τύπος πράξης (FK στο medical_act_codes)
        SELECT medical_act_code_id INTO v_type_id 
        FROM medical_act_codes 
        ORDER BY random() 
        LIMIT 1;

        -- 4. Υπολογισμός Διάρκειας (μικρότερη της διαφοράς discharge - admission)
        -- Αν η διαφορά είναι 1 ή 0, η διάρκεια θα είναι 0 (αυθημερόν). 
        v_diff := rec.discharge_date - rec.admission_date;
        IF v_diff IS NULL OR v_diff <= 1 THEN
            v_duration := 0;
        ELSE
            -- Τυχαίος ακέραιος από 0 έως (v_diff - 1)
            v_duration := floor(random() * v_diff)::int;
        END IF;

        -- 5. Τυχαίο Κόστος (FK στο table ken)
        SELECT ken_id INTO v_cost_ken FROM ken ORDER BY random() LIMIT 1;

        -- 6. Τοποθεσία (Room) & Γιατρός (Doctor) με βάση την κατηγορία
        IF v_category = 'Χειρουργική' THEN
            -- Για χειρουργείο: Δωμάτιο 'Χειρουργείο' ή 'ΜΕΘ'
            SELECT room_id::VARCHAR INTO v_location 
            FROM rooms 
            WHERE room_type IN ('Χειρουργείο', 'ΜΕΘ') 
            ORDER BY random() LIMIT 1;

            -- Για χειρουργείο: Γιατρός 'Χειρουργός'
            SELECT doctor_id INTO v_surgeon_id 
            FROM doctors 
            WHERE specialty = 'Χειρουργός' 
            ORDER BY random() LIMIT 1;
        ELSE
            -- Για Διαγνωστική/Θεραπευτική: Οποιοδήποτε άλλο δωμάτιο
            SELECT room_id::VARCHAR INTO v_location 
            FROM rooms 
            WHERE room_type NOT IN ('Χειρουργείο', 'ΜΕΘ') 
            ORDER BY random() LIMIT 1;

            -- Για Διαγνωστική/Θεραπευτική: Γιατρός ΠΟΥ ΔΕΝ ΕΙΝΑΙ 'Χειρουργός'
            SELECT doctor_id INTO v_surgeon_id 
            FROM doctors 
            WHERE specialty != 'Χειρουργός' 
            ORDER BY random() LIMIT 1;
        END IF;

        -- 7. Δημιουργία εγγραφής στον πίνακα medical_acts
        INSERT INTO medical_acts (
            medical_act_type, 
            medical_act_category, 
            duration, 
            medical_act_cost, 
            room_id, 
            surgeon_id
        ) VALUES (
            v_type_id,
            v_category,
            v_duration,
            v_cost_ken,
            v_location,
            v_surgeon_id
        ) RETURNING medical_act_id INTO v_new_medical_act_id;

        -- 8. Ενημέρωση του πίνακα admission με το νέο ID
        UPDATE admission 
        SET medical_act_id = v_new_medical_act_id 
        WHERE admission_id = rec.admission_id;

        -- Αύξηση μετρητή
        v_counter := v_counter + 1;
    END LOOP;
    
    COMMIT;
END;
$$;
