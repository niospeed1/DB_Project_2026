WITH LevelStats AS (
    SELECT 
        emergency_level,
        COUNT(case_id) AS total_cases_in_level,
        AVG(handled_time - arrival_time) AS avg_wait_time,
        ROUND((COUNT(admission_id) * 100.0) / COUNT(case_id), 2) AS admission_percentage
    FROM 
        emergency_case
    GROUP BY 
        emergency_level
),
DeptDistribution AS (
    SELECT 
        ec.emergency_level,
        d.department_description,
        COUNT(ec.case_id) AS cases_referred_to_dept
    FROM 
        emergency_case ec
    JOIN 
        admission a ON ec.admission_id = a.admission_id
    JOIN 
        departments d ON a.department_id = d.department_id
    GROUP BY 
        ec.emergency_level, 
        d.department_description
)
SELECT 
    ls.emergency_level AS "Επίπεδο Επείγοντος",
    ls.total_cases_in_level AS "Συνολικά Περιστατικά",
    ls.avg_wait_time AS "Μέσος Χρόνος Αναμονής",
    ls.admission_percentage AS "Ποσοστό Νοσηλειών (%)",
    dd.department_description AS "Τμήμα Παραπομπής",
    dd.cases_referred_to_dept AS "Περιστατικά ανά Τμήμα"
FROM 
    LevelStats ls
LEFT JOIN 
    DeptDistribution dd ON ls.emergency_level = dd.emergency_level
ORDER BY 
    "Επίπεδο Επείγοντος", 
    "Περιστατικά ανά Τμήμα" DESC;
