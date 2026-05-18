WITH AdmissionSubstances AS (
    SELECT DISTINCT 
        p.admission_id, 
        ms.active_substance
    FROM prescription p
    JOIN medicine_substances ms ON p.drug_id = ms.drug_id
    WHERE p.admission_id IS NOT NULL
)
SELECT 
    a1.active_substance AS "Δραστική Ουσία 1",
    a2.active_substance AS "Δραστική Ουσία 2",
    COUNT(*) AS Συχνότητα
FROM AdmissionSubstances a1
JOIN AdmissionSubstances a2 
    ON a1.admission_id = a2.admission_id 
    AND a1.active_substance < a2.active_substance 
GROUP BY 
    a1.active_substance, 
    a2.active_substance
ORDER BY 
    Συχνότητα DESC
LIMIT 3;
