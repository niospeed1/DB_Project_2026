CREATE OR REPLACE PROCEDURE process_emergency_cases()
LANGUAGE plpgsql
AS $$
DECLARE
    rec RECORD;
    v_handled_time TIMESTAMP;
    v_random_days INT;
    v_dept_id INT;
    v_room_id INT;
    v_adm_diag TEXT; 
    v_dis_diag TEXT; 
    v_ken_id INT; -- Νέα μεταβλητή για το Κλειστό Ενοποιημένο Νοσήλιο
    v_new_admission_id INT;
BEGIN
    -- 1. Επιλογή ασθενών (FIFO ανά ημέρα και προτεραιότητα Triage)
    FOR rec IN 
        SELECT * FROM emergency_case 
        WHERE handled_time IS NULL 
        ORDER BY 
            arrival_time::date ASC, 
            emergency_level::int ASC, 
            arrival_time ASC 
    LOOP
        
        -- 2. Υπολογισμός Handled Time βάσει Emergency Level
        v_handled_time := rec.arrival_time + (
            CASE 
                WHEN rec.emergency_level::text = '1' THEN (random() * 5 + 1) * INTERVAL '1 minute'
                WHEN rec.emergency_level::text = '2' THEN (random() * 15 + 5) * INTERVAL '1 minute'
                ELSE (random() * 45 + 15) * INTERVAL '1 minute'
            END
        );

        -- 3. Ενημέρωση του emergency_case
        UPDATE emergency_case 
        SET handled_time = v_handled_time 
        WHERE case_id = rec.case_id;

        -- 4. Διαδικασία Εισαγωγής
        IF rec.outcome = 'Νοσηλεία' THEN
            
            -- Α. Επιλογή υπαρκτού τμήματος (1-17, εκτός 16)
            SELECT department_id INTO v_dept_id 
            FROM departments 
            WHERE department_id BETWEEN 1 AND 17 
              AND department_id != 16 
            ORDER BY random() 
            LIMIT 1;

            IF v_dept_id IS NULL THEN
                CONTINUE; 
            END IF;

            -- Β. Επιλογή τυχαίου δωματίου που ανήκει στο επιλεγμένο τμήμα
            SELECT room_id INTO v_room_id 
            FROM rooms 
            WHERE department_id = v_dept_id 
            ORDER BY random() 
            LIMIT 1;

            -- Γ. Επιλογή τυχαίων κωδικών ICD-10 από τον πίνακα diagnosis
            SELECT icd_id INTO v_adm_diag FROM diagnosis ORDER BY random() LIMIT 1;
            SELECT icd_id INTO v_dis_diag FROM diagnosis ORDER BY random() LIMIT 1;

            -- Δ. Επιλογή τυχαίου ken_id από τον πίνακα ken
            SELECT ken_id INTO v_ken_id FROM ken ORDER BY random() LIMIT 1;

            -- Ε. Τυχαία διάρκεια νοσηλείας (2 έως 20 ημέρες)
            v_random_days := floor(random() * (20 - 2 + 1) + 2)::int;

            -- ΣΤ. Εισαγωγή στον πίνακα admission με δωμάτιο, διαγνώσεις και KEN
            INSERT INTO admission (
                patient_id, 
                department_id, 
                room_id,
                admission_date, 
                discharge_date,
                admission_diagnosis, 
                discharge_diagnosis,
                ken_id -- Προσθήκη του KEN
            ) VALUES (
                rec.patient_id::int,
                v_dept_id,
                v_room_id,
                v_handled_time::date,
                (v_handled_time + (v_random_days * INTERVAL '1 day'))::date,
                v_adm_diag,
                v_dis_diag,
                v_ken_id -- Ανάθεση του τυχαίου KEN
            )
            RETURNING admission_id INTO v_new_admission_id;

            -- Ζ. Ενημέρωση της σύνδεσης στο emergency_case
            UPDATE emergency_case 
            SET admission_id = v_new_admission_id 
            WHERE case_id = rec.case_id;

        END IF;
    END LOOP;
    
    COMMIT;
END;
$$;