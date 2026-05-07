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
    v_ken_id INT;
    v_new_admission_id INT;
    v_rand_prob NUMERIC;


v_target_icd TEXT;  
v_count_2025 INT := 0;
v_count_2026 INT := 0;

BEGIN
    
    SELECT icd_id INTO v_target_icd FROM diagnosis LIMIT 1;

    FOR rec IN 
        SELECT * FROM emergency_case 
        WHERE handled_time IS NULL 
        ORDER BY 
            arrival_time::date ASC, 
            emergency_level::int ASC, 
            arrival_time ASC 
    LOOP
        
        v_handled_time := rec.arrival_time + (
            CASE 
                WHEN rec.emergency_level::text = '1' THEN (random() * 5 + 1) * INTERVAL '1 minute'
                WHEN rec.emergency_level::text = '2' THEN (random() * 15 + 5) * INTERVAL '1 minute'
                ELSE (random() * 45 + 15) * INTERVAL '1 minute'
            END
        );

        UPDATE emergency_case 
        SET handled_time = v_handled_time 
        WHERE case_id = rec.case_id;

        IF rec.outcome = 'Νοσηλεία' THEN
            
            -- ΝΕΑ ΤΡΟΠΟΠΟΙΗΣΗ: Ρεαλιστική, ελαφρώς σταθμισμένη κατανομή
            v_rand_prob := random(); 
            
            IF v_rand_prob < 0.15 THEN
                -- 15% πιθανότητα: Ελαφρύ boost στο 1ο τμήμα
                SELECT department_id INTO v_dept_id 
                FROM departments WHERE department_id != 16 
                ORDER BY department_id ASC LIMIT 1;
                
            ELSIF v_rand_prob < 0.30 THEN
                -- 15% πιθανότητα: Ελαφρύ boost στο 2ο τμήμα
                SELECT department_id INTO v_dept_id 
                FROM departments WHERE department_id != 16 
                ORDER BY department_id ASC OFFSET 1 LIMIT 1;
                
            ELSE
                -- 70% πιθανότητα: Ισομερής, τυχαία κατανομή σε όλα τα διαθέσιμα τμήματα
                SELECT department_id INTO v_dept_id 
                FROM departments WHERE department_id != 16 
                ORDER BY random() LIMIT 1;
            END IF;

            IF v_dept_id IS NULL THEN
                CONTINUE; 
            END IF;

            SELECT room_id INTO v_room_id 
            FROM rooms WHERE department_id = v_dept_id ORDER BY random() LIMIT 1;

            -- Γ. Τροποποιημένη Επιλογή ICD-10 για να ικανοποιεί το Query των συνεχόμενων ετών
            IF EXTRACT(YEAR FROM v_handled_time) = 2025 AND v_count_2025 < 6 THEN
                v_adm_diag := v_target_icd;
                v_count_2025 := v_count_2025 + 1;
            ELSIF EXTRACT(YEAR FROM v_handled_time) = 2026 AND v_count_2026 < 6 THEN
                v_adm_diag := v_target_icd;
                v_count_2026 := v_count_2026 + 1;
            ELSE
                -- Για τα υπόλοιπα περιστατικά, επιλέγουμε τυχαία, ΑΠΟΦΕΥΓΟΝΤΑΣ τον κωδικό-στόχο
                SELECT icd_id INTO v_adm_diag
                FROM diagnosis
                WHERE icd_id != v_target_icd
                ORDER BY random()
                LIMIT 1;
            END IF;

            -- Επιλογή discharge_diagnosis, επίσης αποφεύγοντας τον κωδικό-στόχο (για να μη μετρηθεί 2 φορές)
            SELECT icd_id INTO v_dis_diag
            FROM diagnosis
            WHERE icd_id != v_target_icd
            ORDER BY random()
            LIMIT 1;

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
                ken_id
            ) VALUES (
                rec.patient_id::int,
                v_dept_id,
                v_room_id,
                v_handled_time::date,
                (v_handled_time + (v_random_days * INTERVAL '1 day'))::date,
                v_adm_diag,
                v_dis_diag,
                v_ken_id
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
$$