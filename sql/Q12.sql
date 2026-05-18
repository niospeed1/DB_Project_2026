SELECT 
    d.department_description AS "Τμήμα",
    s.shift_date AS "Ημερομηνία Βάρδιας",
    s.shift_type AS "Τύπος Βάρδιας",
    p.personnel_type AS "Τύπος Προσωπικού",
    CASE 
        WHEN doc.doctor_id IS NOT NULL THEN doc.specialty
        WHEN n.nurse_id IS NOT NULL THEN n.rank
        WHEN ap.admin_id IS NOT NULL THEN ap.duty
        ELSE 'Άγνωστος Ρόλος'
    END AS "Ειδικότητα / Ρόλος",
    COUNT(ps.personnel_id) AS "Αριθμός Προσωπικού"
FROM 
    shift s
JOIN 
    departments d ON s.department_id = d.department_id
JOIN 
    personnel_shifts ps ON s.shift_id = ps.shift_id
JOIN 
    personnel p ON ps.personnel_id = p.personnel_id
LEFT JOIN 
    doctors doc ON p.personnel_id = doc.doctor_id
LEFT JOIN 
    nurses n ON p.personnel_id = n.nurse_id
LEFT JOIN 
    administrative_personnel ap ON p.personnel_id = ap.admin_id
WHERE 
    s.shift_date BETWEEN '2026-05-01' AND '2026-05-07'
GROUP BY 
    d.department_description,
    s.shift_date,
    s.shift_type,
    p.personnel_type,
    "Ειδικότητα / Ρόλος"
ORDER BY 
    "Τμήμα", 
    "Ημερομηνία Βάρδιας", 
    "Τύπος Βάρδιας";
