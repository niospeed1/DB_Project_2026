CREATE OR REPLACE FUNCTION insert_doctor(
    p_amka VARCHAR, p_first_name VARCHAR, p_last_name VARCHAR, p_age INT,
    p_email VARCHAR, p_phone_number VARCHAR, p__hire_date DATE,
    p_specialty VARCHAR, p_rank VARCHAR,
    p_license_number VARCHAR, p_association_number VARCHAR,
    p_department VARCHAR[]
) RETURNS VOID AS $$
DECLARE
    new_id INT;
    v_supervisor_id INT := NULL; 
    t_name VARCHAR; 
    found_department_id INT;
BEGIN

    IF p_rank = 'Ειδικευόμενος' THEN
        SELECT doctor_id INTO v_supervisor_id FROM doctors 
        WHERE rank IN ('Επιμελητής Β', 'Επιμελητής Α', 'Διευθυντής') 
        ORDER BY RANDOM() LIMIT 1;
        
        IF v_supervisor_id IS NULL THEN
            RAISE EXCEPTION 'Αδυναμία εισαγωγής: Δεν βρέθηκε διαθέσιμος επόπτης.';
        END IF;

    ELSIF p_rank = 'Επιμελητής Β' THEN
        SELECT doctor_id INTO v_supervisor_id FROM doctors 
        WHERE rank IN ('Επιμελητής Α', 'Διευθυντής') 
        ORDER BY RANDOM() LIMIT 1;
        
    ELSIF p_rank = 'Επιμελητής Α' THEN
        SELECT doctor_id INTO v_supervisor_id FROM doctors 
        WHERE rank = 'Διευθυντής' 
        ORDER BY RANDOM() LIMIT 1;
    END IF;

    INSERT INTO personnel (personnel_type, amka, first_name, last_name, age, email, phone_number, hire_date)
    VALUES ('Ιατρός', p_amka, p_first_name, p_last_name, p_age, p_email, p_phone_number, p__hire_date)
    RETURNING personnel_id INTO new_id;

    INSERT INTO doctors (doctor_id, specialty, rank, license_number, association_number, supervisor_id)
    VALUES (new_id, p_specialty, p_rank, p_license_number, p_association_number, v_supervisor_id);

    FOREACH t_name IN ARRAY p_department
    LOOP

        SELECT department_id INTO found_department_id FROM departments WHERE department_description = t_name;
        
        IF found_department_id IS NOT NULL THEN
            INSERT INTO doctor_department (doctor_id, department_id)
            VALUES (new_id, found_department_id);
        END IF;
    END LOOP;

END;
$$ LANGUAGE plpgsql;