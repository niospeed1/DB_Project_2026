SELECT 
    p.first_name AS "Όνομα",
    p.last_name AS "Επώνυμο",
    d.specialty AS "Ειδικότητα",
    p.age AS "Ηλικία",
    COUNT(ma.medical_act_id) AS "Σύνολο Χειρουργείων"
FROM 
    personnel p
JOIN 
    doctors d ON p.personnel_id = d.doctor_id
JOIN 
    medical_acts ma ON d.doctor_id = ma.surgeon_id
WHERE 
    p.age < 35
    AND ma.medical_act_category = 'Χειρουργική' 
GROUP BY 
    d.doctor_id, 
    p.first_name, 
    p.last_name, 
    d.specialty, 
    p.age
ORDER BY 
    "Σύνολο Χειρουργείων" DESC;
