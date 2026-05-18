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
            
            v_rand_prob := random(); 
            
            IF v_rand_prob < 0.20 THEN
                SELECT department_id INTO v_dept_id 
                FROM departments WHERE department_id != 16 
                ORDER BY department_id ASC LIMIT 1;
                
            ELSIF v_rand_prob < 0.40 THEN
                SELECT department_id INTO v_dept_id 
                FROM departments WHERE department_id != 16 
                ORDER BY department_id ASC OFFSET 1 LIMIT 1;
                
            ELSE
                SELECT department_id INTO v_dept_id 
                FROM departments WHERE department_id != 16 
                ORDER BY random() LIMIT 1;
            END IF;

            IF v_dept_id IS NULL THEN
                CONTINUE; 
            END IF;

            SELECT room_id INTO v_room_id 
            FROM rooms WHERE department_id = v_dept_id ORDER BY random() LIMIT 1;

            IF EXTRACT(YEAR FROM v_handled_time) = 2025 AND v_count_2025 < 6 THEN
                v_adm_diag := v_target_icd;
                v_count_2025 := v_count_2025 + 1;
            ELSIF EXTRACT(YEAR FROM v_handled_time) = 2026 AND v_count_2026 < 6 THEN
                v_adm_diag := v_target_icd;
                v_count_2026 := v_count_2026 + 1;
            ELSE

                SELECT icd_id INTO v_adm_diag
                FROM diagnosis
                WHERE icd_id != v_target_icd
                ORDER BY random()
                LIMIT 1;
            END IF;

            SELECT icd_id INTO v_dis_diag
            FROM diagnosis
            WHERE icd_id != v_target_icd
            ORDER BY random()
            LIMIT 1;

            SELECT ken_id INTO v_ken_id FROM ken ORDER BY random() LIMIT 1;


            v_random_days := floor(random() * (20 - 2 + 1) + 2)::int;

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

            UPDATE emergency_case
            SET admission_id = v_new_admission_id
            WHERE case_id = rec.case_id;

        END IF;
    END LOOP;
   
    COMMIT;
END;
$$;