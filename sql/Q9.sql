WITH YearlyPatientStats AS (
    SELECT 
        p.patient_id,
        p.first_name,
        p.last_name,
        EXTRACT(YEAR FROM a.admission_date) AS admission_year,
        SUM(COALESCE(a.discharge_date, CURRENT_DATE) - a.admission_date) AS total_days
    FROM admission a
    JOIN patients p ON a.patient_id = p.patient_id
    WHERE 
        EXTRACT(YEAR FROM a.admission_date) = 2025 
    GROUP BY 
        p.patient_id, 
        p.first_name, 
        p.last_name, 
        EXTRACT(YEAR FROM a.admission_date)
    HAVING 
        SUM(COALESCE(a.discharge_date, CURRENT_DATE) - a.admission_date) > 15
),
GroupedPatients AS (
    SELECT 
        patient_id,
        first_name AS "Όνομα",
        last_name AS "Επώνυμο",
        admission_year AS "Έτος",
        total_days AS "Συνολικές Ημέρες",
        COUNT(patient_id) OVER (PARTITION BY total_days) AS patients_with_same_days
    FROM YearlyPatientStats
)
SELECT 
    "Όνομα",
    "Επώνυμο",
    "Έτος",
    "Συνολικές Ημέρες"
FROM GroupedPatients
WHERE patients_with_same_days > 1
ORDER BY "Συνολικές Ημέρες" DESC, "Επώνυμο";
