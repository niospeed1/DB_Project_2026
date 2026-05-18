CREATE OR REPLACE PROCEDURE populate_prescriptions()
LANGUAGE plpgsql
AS $$
DECLARE
    rec RECORD;
    drug_rec RECORD;
    v_doctor_id INT;
    v_start_date DATE;
    v_end_date DATE;
    v_dose VARCHAR(100);
    v_freq VARCHAR(100);
    v_num_drugs INT;

    v_doses VARCHAR[] := ARRAY['500mg', '10mg', '20mg', '50mg', '1 xάπι', '2 xάπια', '1000mg'];
    v_freqs VARCHAR[] := ARRAY['1 φορά/μέρα', '2 φορές/μέρα', 'Ανά 8 ώρες', 'Προ ύπνου', 'Μετά το γεύμα'];
BEGIN
    FOR rec IN 
        SELECT admission_id, patient_id, discharge_date 
        FROM admission 
        ORDER BY random() 
        LIMIT 300
    LOOP
        v_num_drugs := floor(random() * 3 + 2)::int;

        v_start_date := COALESCE(rec.discharge_date, CURRENT_DATE) + 1;

        v_end_date := v_start_date + floor(random() * 13 + 3)::int;

        FOR drug_rec IN
            SELECT m.drug_id
            FROM medicine m
            WHERE NOT EXISTS (
                SELECT 1
                FROM medicine_substances ms
                JOIN patients p ON p.patient_id = rec.patient_id
                WHERE ms.drug_id = m.drug_id
                  AND COALESCE(p.allergies, '') ILIKE '%' || ms.active_substance || '%'
            )
            ORDER BY random()
            LIMIT v_num_drugs
        LOOP
            SELECT doctor_id INTO v_doctor_id FROM doctors ORDER BY random() LIMIT 1;
            
            v_dose := v_doses[floor(random() * array_length(v_doses, 1) + 1)::int];
            v_freq := v_freqs[floor(random() * array_length(v_freqs, 1) + 1)::int];

            INSERT INTO prescription (
                doctor_id,
                patient_id,
                drug_id,
                admission_id,
                dose,
                frequency,
                start_date,
                end_date
            ) VALUES (
                v_doctor_id,
                rec.patient_id,
                drug_rec.drug_id,
                rec.admission_id,
                v_dose,
                v_freq,
                v_start_date,
                v_end_date
            );
        END LOOP;
        
    END LOOP;
    
    COMMIT;
END;
$$;