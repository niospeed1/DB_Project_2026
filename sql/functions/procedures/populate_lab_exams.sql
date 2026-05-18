CREATE OR REPLACE PROCEDURE populate_lab_exams()
LANGUAGE plpgsql
AS $$
DECLARE
    rec RECORD;
    v_category VARCHAR(50);
    v_type_id INT;
    v_cost_ken INT;
    v_doctor_id INT;
    v_date DATE;
    v_result TEXT;
    v_diff INT;
    
    v_counter INT := 0; 
    v_num_exams INT;  
    

    v_categories TEXT[] := ARRAY['Αιματολογικές', 'Βιοχημικές', 'Απεικονιστικές'];
    v_phrases TEXT[] := ARRAY[
        'Χωρίς παθολογικά ευρήματα. Φυσιολογική απεικόνιση',
        'Ήπια εκφύλιση, συμβατή με την ηλικία του ασθενούς',
        'Μικρή συλλογή υγρού, χωρίς σημεία ενεργού φλεγμονής',
        'Εικόνα εντός φυσιολογικών ορίων',
        'Δεν παρατηρήθηκαν αλλοιώσεις στην εξεταζόμενη περιοχή',
        'Ανίχνευση μικρού μορφώματος, συνιστάται τακτικός επανέλεγχος',
        'Φυσιολογική μετεγχειρητική εικόνα, απουσία επιπλοκών'
    ];
BEGIN

    WHILE v_counter < 600 LOOP

        SELECT admission_id, admission_date, discharge_date INTO rec
        FROM admission 
        ORDER BY random() 
        LIMIT 1;

        v_num_exams := floor(random() * 4 + 1)::int;

        FOR i IN 1..v_num_exams LOOP
            
            IF v_counter >= 600 THEN
                EXIT;
            END IF;

            v_category := v_categories[floor(random() * 3 + 1)::int];

            SELECT lab_exam_code_id INTO v_type_id FROM lab_exams_codes ORDER BY random() LIMIT 1;
            SELECT ken_id INTO v_cost_ken FROM ken ORDER BY random() LIMIT 1;
            SELECT doctor_id INTO v_doctor_id FROM doctors ORDER BY random() LIMIT 1;

            v_diff := COALESCE(rec.discharge_date, CURRENT_DATE) - rec.admission_date;
            IF v_diff < 0 THEN 
                v_diff := 0; 
            END IF;
            
            v_date := rec.admission_date + floor(random() * (v_diff + 1))::int;

            IF v_category IN ('Αιματολογικές', 'Βιοχημικές') THEN
                v_result := floor(random() * (250 - 10 + 1) + 10)::text || ' mg/dL';
            ELSE
                v_result := v_phrases[floor(random() * 7 + 1)::int];
            END IF;

            INSERT INTO lab_exams (
                admission_id,
                lab_exam_type,
                lab_exam_category,
                lab_exam_date,
                lab_exam_result,
                lab_exam_cost,
                doctor_id
            ) VALUES (
                rec.admission_id,
                v_type_id,
                v_category,
                v_date,
                v_result,
                v_cost_ken,
                v_doctor_id
            );

            v_counter := v_counter + 1;
            
        END LOOP;
    END LOOP;
    
    COMMIT;
END;
$$;