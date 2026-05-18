SELECT 
    ms.active_substance AS "Δραστική Ουσία",
    COUNT(DISTINCT ms.drug_id) AS "Αριθμός Φαρμάκων",
    COUNT(DISTINCT p.patient_id) AS "Αριθμός Αλλεργικών Ασθενών"
FROM 
    medicine_substances ms
JOIN 
    patients p ON p.allergies ILIKE ms.active_substance
WHERE 
    p.allergies IS NOT NULL
GROUP BY 
    ms.active_substance
ORDER BY 
    "Αριθμός Αλλεργικών Ασθενών" DESC;
