SELECT 
    d.doctor_id AS "ID Ιατρού",
    p.first_name AS "Όνομα",
    p.last_name AS "Επώνυμο",
    ROUND(AVG(de.medical_care), 2) AS "Μέση Αξιολ. Ιατρού",
    ROUND(AVG(ae.overall_experience), 2) AS "Μέση Αξιολ. Νοσηλείας"
FROM doctors d
JOIN personnel p ON d.doctor_id = p.personnel_id
JOIN doctor_evaluation de ON d.doctor_id = de.doctor_id
JOIN admission_evaluation ae ON de.admission_id = ae.admission_id
WHERE d.doctor_id = 1
GROUP BY 
    d.doctor_id, 
    p.first_name, 
    p.last_name;

EXPLAIN ANALYZE
SELECT 
    d.doctor_id AS "ID Ιατρού",
    p.first_name AS "Όνομα",
    p.last_name AS "Επώνυμο",
    ROUND(AVG(de.medical_care), 2) AS "Μέση Αξιολ. Ιατρού",
    ROUND(AVG(ae.overall_experience), 2) AS "Μέση Αξιολ. Νοσηλείας"
FROM doctors d
JOIN personnel p ON d.doctor_id = p.personnel_id
JOIN doctor_evaluation de ON d.doctor_id = de.doctor_id
JOIN admission_evaluation ae ON de.admission_id = ae.admission_id
WHERE d.doctor_id = 1
GROUP BY 
    d.doctor_id, 
    p.first_name, 
    p.last_name;

DROP INDEX IF EXISTS idx_q4_doctor_eval;
CREATE INDEX idx_q4_doctor_eval ON doctor_evaluation(doctor_id);

SET enable_seqscan = OFF;

EXPLAIN ANALYZE
SELECT 
    d.doctor_id AS "ID Ιατρού",
    p.first_name AS "Όνομα",
    p.last_name AS "Επώνυμο",
    ROUND(AVG(de.medical_care), 2) AS "Μέση Αξιολ. Ιατρού",
    ROUND(AVG(ae.overall_experience), 2) AS "Μέση Αξιολ. Νοσηλείας"
FROM doctors d
JOIN personnel p ON d.doctor_id = p.personnel_id
JOIN doctor_evaluation de ON d.doctor_id = de.doctor_id
JOIN admission_evaluation ae ON de.admission_id = ae.admission_id
WHERE d.doctor_id = 1
GROUP BY 
    d.doctor_id, 
    p.first_name, 
    p.last_name;

SET enable_seqscan = ON;
