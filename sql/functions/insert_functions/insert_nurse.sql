CREATE OR REPLACE FUNCTION insert_nurse(
    p_amka VARCHAR, 
    p_first_name VARCHAR, 
    p_last_name VARCHAR,
    p_age INT,
    p_email VARCHAR, 
    p_phone_number VARCHAR, 
    p_hire_date DATE,
    p_rank VARCHAR
) RETURNS VOID AS $$
DECLARE
    new_id INT;
    random_department_id INT;
BEGIN
   
    INSERT INTO personnel (
        amka, first_name, last_name, age, 
        email, phone_number, hire_date, personnel_type
    )
    VALUES (
        p_amka, p_first_name, p_last_name, p_age, 
        p_email, p_phone_number, p_hire_date, 'Νοσηλευτής'
    )
    RETURNING personnel_id INTO new_id;

    SELECT department_id INTO random_department_id 
    FROM departments 
    ORDER BY RANDOM() 
    LIMIT 1;

    INSERT INTO nurses (nurse_id, department_id, rank)
    VALUES (new_id, random_department_id, p_rank);

END;
$$ LANGUAGE plpgsql;