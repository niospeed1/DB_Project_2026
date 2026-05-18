SELECT 
    p.personnel_id AS "ID Προσωπικού",
    p.first_name AS "Όνομα",
    p.last_name AS "Επώνυμο",
    p.personnel_type AS "Τύπος Προσωπικού"
FROM 
    personnel p
WHERE 
    p.personnel_id NOT IN (
        SELECT 
            ps.personnel_id
        FROM 
            personnel_shifts ps
        JOIN 
            shift s ON ps.shift_id = s.shift_id
        WHERE 
            s.shift_date = '2026-05-15' 
            AND s.department_id = 1
    )
ORDER BY 
    "Τύπος Προσωπικού", 
    "Επώνυμο";
