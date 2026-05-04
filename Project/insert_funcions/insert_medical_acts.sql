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
    v_num_docs INT;
    v_num_nurses INT;
    v_selected_dept_id INT;
BEGIN

    FOR i IN 1..600 LOOP
        
        SELECT a.admission_id, a.admission_date, a.discharge_date 
        INTO rec
        FROM admission a
        LEFT JOIN medical_acts ma ON a.admission_id = ma.admission_id
        GROUP BY a.admission_id, a.admission_date, a.discharge_date
        HAVING COUNT(ma.medical_act_id) < 2
        ORDER BY random() 
        LIMIT 1;

        IF NOT FOUND THEN
            CONTINUE;
        END IF;

        IF i <= 300 THEN
            v_category := 'Χειρουργική';
        ELSIF i <= 450 THEN
            v_category := 'Διαγνωστική';
        ELSE
            v_category := 'Θεραπευτική';
        END IF;

        SELECT medical_act_code_id INTO v_type_id 
        FROM medical_act_codes 
        ORDER BY random() 
        LIMIT 1;

        v_diff := rec.discharge_date - rec.admission_date;
        IF v_diff IS NULL OR v_diff <= 1 THEN
            v_duration := 0;
        ELSE
            v_duration := floor(random() * (v_diff - 1) + 1)::int;
        END IF;

        SELECT ken_id INTO v_cost_ken FROM ken ORDER BY random() LIMIT 1;

        IF v_category = 'Χειρουργική' THEN
            SELECT room_id::INT INTO v_location 
            FROM rooms 
            WHERE room_type IN ('Χειρουργείο', 'ΜΕΘ') 
            ORDER BY random() LIMIT 1;

            SELECT doctor_id INTO v_surgeon_id 
            FROM doctors 
            WHERE specialty = 'Χειρουργός' 
            ORDER BY random() LIMIT 1;

            SELECT department_id INTO v_selected_dept_id
            FROM doctor_department
            WHERE doctor_id = v_surgeon_id
            ORDER BY random() LIMIT 1;

        ELSE
        
            SELECT r.room_id, d.doctor_id, r.department_id
            INTO v_location, v_surgeon_id, v_selected_dept_id
            FROM rooms r
            JOIN doctor_department dd ON r.department_id = dd.department_id
            JOIN doctors d ON dd.doctor_id = d.doctor_id
            WHERE r.room_type NOT IN ('Χειρουργείο', 'ΜΕΘ') 
              AND d.specialty != 'Χειρουργός'
            ORDER BY random() LIMIT 1;
        END IF;

        IF v_location IS NULL OR v_surgeon_id IS NULL THEN
            CONTINUE;
        END IF;

        INSERT INTO medical_acts (
            admission_id,          
            medical_act_type, 
            medical_act_category, 
            duration, 
            medical_act_cost,      
            room_id, 
            surgeon_id
        ) VALUES (
            rec.admission_id,
            v_type_id,
            v_category,
            v_duration,
            v_cost_ken,
            v_location,
            v_surgeon_id
        ) RETURNING medical_act_id INTO v_new_medical_act_id;

        
        v_num_docs := floor(random() * 3)::int; 
        v_num_nurses := floor(random() * 4)::int; 

        IF v_selected_dept_id IS NOT NULL THEN
            
            IF v_num_docs > 0 THEN
                INSERT INTO medical_act_assistants (medical_act_id, personnel_id)
                SELECT v_new_medical_act_id, doctor_id
                FROM (
                    SELECT dd.doctor_id
                    FROM doctor_department dd
                    WHERE dd.department_id = v_selected_dept_id
                      AND dd.doctor_id != v_surgeon_id
                ) AS available_docs
                ORDER BY random() 
                LIMIT v_num_docs;
            END IF;

            IF v_num_nurses > 0 THEN
                INSERT INTO medical_act_assistants (medical_act_id, personnel_id)
                SELECT v_new_medical_act_id, nurse_id
                FROM nurses n
                WHERE n.department_id = v_selected_dept_id
                ORDER BY random()
                LIMIT v_num_nurses;
            END IF;
            
        END IF;
        
    END LOOP;
    
    COMMIT;
END;
$$;
