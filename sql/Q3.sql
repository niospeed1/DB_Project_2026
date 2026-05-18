SELECT 
    p.patient_id AS "ID Ασθενούς",
    p.first_name AS "Όνομα",
    p.last_name AS "Επώνυμο",
    d.department_description AS "Τμήμα",
    COUNT(a.admission_id) AS "Νοσηλείες",
    SUM(a.total_cost) AS "Συνολικό Κόστος"
FROM admission a
JOIN patients p ON a.patient_id = p.patient_id
JOIN departments d ON a.department_id = d.department_id
GROUP BY 
    p.patient_id, 
    p.first_name, 
    p.last_name, 
    d.department_id,
    d.department_description
HAVING COUNT(a.admission_id) > 3
ORDER BY COUNT(a.admission_id) DESC;
