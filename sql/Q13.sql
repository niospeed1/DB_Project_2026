WITH RECURSIVE SupervisionHierarchy AS (
    SELECT 
        doctor_id AS original_doctor_id,
        supervisor_id AS current_supervisor_id,
        1 AS hierarchy_level
    FROM 
        doctors
    WHERE 
        supervisor_id IS NOT NULL
    UNION ALL
    SELECT 
        sh.original_doctor_id,
        d.supervisor_id,
        sh.hierarchy_level + 1
    FROM 
        SupervisionHierarchy sh
    JOIN 
        doctors d ON sh.current_supervisor_id = d.doctor_id
    WHERE 
        d.supervisor_id IS NOT NULL
)
SELECT 
    sh.original_doctor_id AS "ID Ιατρού",
    p_doc.last_name AS "Επώνυμο Ιατρού",
    p_doc.first_name AS "Όνομα Ιατρού",
    sh.hierarchy_level AS "Επίπεδο Ιεραρχίας",
    sh.current_supervisor_id AS "Κωδικός Επόπτη",
    p_sup.last_name AS "Επώνυμο Επόπτη",
    p_sup.first_name AS "Όνομα Επόπτη",
    d_sup.rank AS "Βαθμίδα Επόπτη"
FROM 
    SupervisionHierarchy sh
JOIN 
    personnel p_doc ON sh.original_doctor_id = p_doc.personnel_id
JOIN 
    doctors d_sup ON sh.current_supervisor_id = d_sup.doctor_id
JOIN 
    personnel p_sup ON sh.current_supervisor_id = p_sup.personnel_id
ORDER BY 
    "ID Ιατρού", 
    "Επίπεδο Ιεραρχίας";
