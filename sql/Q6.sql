SELECT 
    a.admission_id AS "Κωδικός Νοσηλείας",
    a.admission_date AS "Ημ/νία Εισαγωγής",
    a.discharge_date AS "Ημ/νία Εξιτηρίου",
    din.icd_description AS "Διάγνωση Εισαγωγής",
    dout.icd_description AS "Διάγνωση Εξιτηρίου",
    a.total_cost AS "Συνολικό Κόστος",
    ROUND((ae.medical_care + ae.nursing_care + ae.hygiene + ae.food + ae.overall_experience) / 5.0, 2) AS "Μέση Αξιολόγηση"
FROM 
    admission a
LEFT JOIN 
    diagnosis din ON a.admission_diagnosis = din.icd_id
LEFT JOIN 
    diagnosis dout ON a.discharge_diagnosis = dout.icd_id
LEFT JOIN 
    admission_evaluation ae ON a.admission_id = ae.admission_id
WHERE 
    a.patient_id = 5;

EXPLAIN ANALYZE
SELECT 
    a.admission_id AS "Κωδικός Νοσηλείας",
    a.admission_date AS "Ημ/νία Εισαγωγής",
    a.discharge_date AS "Ημ/νία Εξιτηρίου",
    din.icd_description AS "Διάγνωση Εισαγωγής",
    dout.icd_description AS "Διάγνωση Εξιτηρίου",
    a.total_cost AS "Συνολικό Κόστος",
    ROUND((ae.medical_care + ae.nursing_care + ae.hygiene + ae.food + ae.overall_experience) / 5.0, 2) AS "Μέση Αξιολόγηση"
FROM 
    admission a
LEFT JOIN 
    diagnosis din ON a.admission_diagnosis = din.icd_id
LEFT JOIN 
    diagnosis dout ON a.discharge_diagnosis = dout.icd_id
LEFT JOIN 
    admission_evaluation ae ON a.admission_id = ae.admission_id
WHERE 
    a.patient_id = 5;

DROP INDEX IF EXISTS idx_q6_patient;
CREATE INDEX idx_q6_patient ON admission(patient_id);

SET enable_seqscan = OFF;

EXPLAIN ANALYZE
SELECT 
    a.admission_id AS "Κωδικός Νοσηλείας",
    a.admission_date AS "Ημ/νία Εισαγωγής",
    a.discharge_date AS "Ημ/νία Εξιτηρίου",
    din.icd_description AS "Διάγνωση Εισαγωγής",
    dout.icd_description AS "Διάγνωση Εξιτηρίου",
    a.total_cost AS "Συνολικό Κόστος",
    ROUND((ae.medical_care + ae.nursing_care + ae.hygiene + ae.food + ae.overall_experience) / 5.0, 2) AS "Μέση Αξιολόγηση"
FROM 
    admission a
LEFT JOIN 
    diagnosis din ON a.admission_diagnosis = din.icd_id
LEFT JOIN 
    diagnosis dout ON a.discharge_diagnosis = dout.icd_id
LEFT JOIN 
    admission_evaluation ae ON a.admission_id = ae.admission_id
WHERE 
    a.patient_id = 5;

SET enable_seqscan = ON;
