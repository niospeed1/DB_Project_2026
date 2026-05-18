WITH YearlySurgeries AS (
    SELECT 
        ma.surgeon_id,
        COUNT(ma.medical_act_id) AS surgery_count
    FROM 
        medical_acts ma
    JOIN 
        admission a ON ma.admission_id = a.admission_id
    WHERE 
        ma.medical_act_category = 'Χειρουργική'
        AND EXTRACT(YEAR FROM a.admission_date) = EXTRACT(YEAR FROM CURRENT_DATE)
    GROUP BY 
        ma.surgeon_id
),
MaxSurgeries AS (
    SELECT MAX(surgery_count) AS max_count 
    FROM YearlySurgeries
)
SELECT 
    d.doctor_id AS "ID Ιατρού",
    p.first_name AS "Όνομα",
    p.last_name AS "Επώνυμο",
    ys.surgery_count AS "Αριθμός Χειρουργείων"
FROM 
    YearlySurgeries ys
JOIN 
    doctors d ON ys.surgeon_id = d.doctor_id
JOIN 
    personnel p ON d.doctor_id = p.personnel_id
CROSS JOIN 
    MaxSurgeries ms
WHERE 
    ys.surgery_count <= ms.max_count - 5
ORDER BY 
    "Αριθμός Χειρουργείων" DESC;
