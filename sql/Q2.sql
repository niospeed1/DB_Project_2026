WITH ShiftsThisYear AS (
    SELECT DISTINCT ps.personnel_id AS doctor_id
    FROM personnel_shifts ps
    JOIN shift s ON ps.shift_id = s.shift_id
    WHERE EXTRACT(YEAR FROM s.shift_date) = EXTRACT(YEAR FROM CURRENT_DATE)
),
SurgeriesAsLead AS (
    SELECT 
        surgeon_id AS doctor_id, 
        COUNT(*) AS total_surgeries
    FROM medical_acts 
    WHERE surgeon_id IS NOT NULL
    GROUP BY surgeon_id
)
SELECT 
    d.doctor_id AS "ID Ιατρού",
    p.first_name AS "Όνομα", 
    p.last_name AS "Επώνυμο",
    d.specialty AS "Ειδικότητα",
    CASE 
        WHEN sty.doctor_id IS NOT NULL THEN 'ΝΑΙ' 
        ELSE 'ΟΧΙ' 
    END AS "Εφημερία Φέτος",
    COALESCE(sal.total_surgeries, 0) AS "Σύνολο Επεμβάσεων"
FROM doctors d 
JOIN personnel p ON d.doctor_id = p.personnel_id 
LEFT JOIN ShiftsThisYear sty ON d.doctor_id = sty.doctor_id
LEFT JOIN SurgeriesAsLead sal ON d.doctor_id = sal.doctor_id
WHERE d.specialty = 'Χειρουργός';
