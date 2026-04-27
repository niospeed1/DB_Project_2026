INSERT INTO department (department_id, department_description, number_of_beds, floor, building) VALUES (1, 'Παθολογικό', 7, 2, 3);
INSERT INTO department (department_id, department_description, number_of_beds, floor, building) VALUES (2, 'Καρδιολογικό', 7, 3, 1);
INSERT INTO department (department_id, department_description, number_of_beds, floor, building) VALUES (3, 'Χειρουργικό', 10, 1, 2);
INSERT INTO department (department_id, department_description, number_of_beds, floor, building) VALUES (4, 'Ορθοπεδικό', 8, 4, 2);
INSERT INTO department (department_id, department_description, number_of_beds, floor, building) VALUES (5, 'Παιδιατρικό', 8, 3, 1);
INSERT INTO department (department_id, department_description, number_of_beds, floor, building) VALUES (6, 'Μαιευτικό-Γυναικολογικό', 9, 3, 1);
INSERT INTO department (department_id, department_description, number_of_beds, floor, building) VALUES (7, 'Οφθαλμολογικό', 9, 3, 3);
INSERT INTO department (department_id, department_description, number_of_beds, floor, building) VALUES (8, 'ΩΡΛ', 10, 1, 2);
INSERT INTO department (department_id, department_description, number_of_beds, floor, building) VALUES (9, 'Νευρολογικό', 5, 1, 2);
INSERT INTO department (department_id, department_description, number_of_beds, floor, building) VALUES (10, 'Ψυχιατρικό', 5, 1, 3);
INSERT INTO department (department_id, department_description, number_of_beds, floor, building) VALUES (11, 'Δερματολογικό', 7, 2, 2);
INSERT INTO department (department_id, department_description, number_of_beds, floor, building) VALUES (12, 'Ουρολογικό', 5, 1, 2);
INSERT INTO department (department_id, department_description, number_of_beds, floor, building) VALUES (13, 'Ογκολογικό', 6, 1, 3);
INSERT INTO department (department_id, department_description, number_of_beds, floor, building) VALUES (14, 'Πνευμονολογικό', 5, 1, 1);
INSERT INTO department (department_id, department_description, number_of_beds, floor, building) VALUES (15, 'ΜΕΘ (Εντατική)', 8, 5, 2);
INSERT INTO department (department_id, department_description, number_of_beds, floor, building) VALUES (16, 'ΤΕΠ (Επείγοντα)', 9, 3, 1);
INSERT INTO department (department_id, department_description, number_of_beds, floor, building) VALUES (17, 'Αιματολογικό', 7, 1, 2);

//edw prepei na treksoyme prwta tis eisagwges twn iatrwn

WITH NumberedDepartments AS (
    -- Βάζουμε έναν αύξοντα αριθμό (1 έως 17) σε κάθε τμήμα
    SELECT department_id, ROW_NUMBER() OVER () as rn 
    FROM department
),
UniqueDirectors AS (

    SELECT doctor_id, ROW_NUMBER() OVER (ORDER BY RANDOM()) as rn 
    FROM doctors 
    WHERE rank = 'Διευθυντής'
)

UPDATE department 
SET director = ud.doctor_id
FROM NumberedDepartments nt
JOIN UniqueDirectors ud ON nt.rn = ud.rn
WHERE department.department_id = nt.department_id;