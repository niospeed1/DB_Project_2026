CREATE OR REPLACE FUNCTION insert_administrative_personnel(
    p_amka VARCHAR, p_first_name VARCHAR, p_last_name VARCHAR, p_age INT,
    p_email VARCHAR, p_phone_number VARCHAR, p_hire_date DATE,
    p_duty VARCHAR, p_office VARCHAR
) RETURNS VOID AS $$
DECLARE
    new_id INT;
    random_department_id INT;
BEGIN

    INSERT INTO personnel (personnel_type, amka, first_name, last_name, age, email, phone_number, hire_date)
    VALUES ('Διοικητικό Προσωπικό', p_amka, p_first_name, p_last_name, p_age, p_email, p_phone_number, p_hire_date)
    RETURNING personnel_id INTO new_id;

    -- 2. Τυχαία επιλογή ενός τμήματος (όπως κάναμε και στους ιατρούς)
    SELECT department_id INTO random_department_id 
    FROM departments 
    ORDER BY RANDOM() 
    LIMIT 1;

    INSERT INTO administrative_personnel (admin_id, duty, office, department_id)
    VALUES (new_id, p_duty, p_office, random_department_id);

END;
$$ LANGUAGE plpgsql;