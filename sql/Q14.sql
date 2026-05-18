WITH YearlyDiagnosisCounts AS (
    SELECT 
        a.admission_diagnosis AS icd_id,
        EXTRACT(YEAR FROM a.admission_date) AS admission_year,
        COUNT(a.admission_id) AS total_admissions
    FROM 
        admission a
    WHERE 
        a.admission_diagnosis IS NOT NULL
        AND EXTRACT(YEAR FROM a.admission_date) IN (2025, 2026)
    GROUP BY 
        a.admission_diagnosis, 
        EXTRACT(YEAR FROM a.admission_date)
    HAVING 
        COUNT(a.admission_id) >= 5
)
SELECT 
    y1.icd_id AS "Κωδικός ICD",
    d.icd_description AS "Περιγραφή Διάγνωσης",
    y1.admission_year AS "Αρχικό Έτος",
    y2.admission_year AS "Επόμενο Έτος",
    y1.total_admissions AS "Αριθμός Νοσηλειών"
FROM 
    YearlyDiagnosisCounts y1
JOIN 
    YearlyDiagnosisCounts y2 
        ON y1.icd_id = y2.icd_id 
        AND y1.admission_year = 2025 
        AND y2.admission_year = 2026 
        AND y1.total_admissions = y2.total_admissions
JOIN 
    diagnosis d ON y1.icd_id = d.icd_id
ORDER BY 
    "Αριθμός Νοσηλειών" DESC, 
    "Κωδικός ICD";
