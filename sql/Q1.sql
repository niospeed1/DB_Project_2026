SELECT 
    d.department_description AS "Τμήμα",
    EXTRACT(YEAR FROM a.admission_date) AS "Έτος",
    p.insurance_provider AS "Ασφαλ. Φορέας",
    COUNT(a.admission_id) AS "Νοσηλείες",
    SUM(a.total_cost) AS "Συνολικά Έσοδα",
    SUM(k.cost) AS "Βασικό Κόστος",
    SUM(
        GREATEST(0, (COALESCE(a.discharge_date, CURRENT_DATE) - a.admission_date) - k.mdn) 
        * (k.cost / NULLIF(k.mdn, 0))
    ) AS "Χρέωση Υπέρβασης ΜΔΝ"
FROM 
    admission a
JOIN 
    departments d ON a.department_id = d.department_id
JOIN 
    patients p ON a.patient_id = p.patient_id
JOIN 
    ken k ON a.ken_id = k.ken_id
GROUP BY 
    d.department_description,
    EXTRACT(YEAR FROM a.admission_date),
    p.insurance_provider
ORDER BY 
    "Έτος" DESC, 
    "Τμήμα", 
    "Συνολικά Έσοδα" DESC;
