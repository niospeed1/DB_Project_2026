-- 1 --

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

-- 2 --

WITH ShiftsThisYear AS (
    -- Βρίσκουμε ποιους ιατρούς (personnel_id) είχαν έστω και μία βάρδια τη φετινή χρονιά
    SELECT DISTINCT ps.personnel_id AS doctor_id
    FROM personnel_shifts ps
    JOIN shift s ON ps.shift_id = s.shift_id
    WHERE EXTRACT(YEAR FROM s.shift_date) = EXTRACT(YEAR FROM CURRENT_DATE)
),
SurgeriesAsLead AS (
    -- Μετράμε τις επεμβάσεις ανά ιατρό όπου ήταν ο κύριος χειρουργός (surgeon_id)
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
    
    -- Ένδειξη αν είχε εφημερία φέτος (ΝΑΙ/ΟΧΙ)
    CASE 
        WHEN sty.doctor_id IS NOT NULL THEN 'ΝΑΙ' 
        ELSE 'ΟΧΙ' 
    END AS "Εφημερία Φέτος",
    
    -- Αριθμός επεμβάσεων (Αν είναι NULL, βάλε 0)
    COALESCE(sal.total_surgeries, 0) AS "Σύνολο Επεμβάσεων"
 
FROM doctors d 
JOIN personnel p ON d.doctor_id = p.personnel_id 
LEFT JOIN ShiftsThisYear sty ON d.doctor_id = sty.doctor_id
LEFT JOIN SurgeriesAsLead sal ON d.doctor_id = sal.doctor_id
 
-- Βάλαμε 'Χειρουργός' επειδή υπάρχει ακριβώς έτσι στη βάση σου!
WHERE d.specialty = 'Χειρουργός';

-- 3 --

SELECT 
    p.patient_id,
    p.first_name,
    p.last_name,
    d.department_description,
    COUNT(a.admission_id) AS total_admissions,
    SUM(a.total_cost) AS total_cost_in_department
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
ORDER BY total_admissions DESC;

-- 4a --

EXPLAIN ANALYZE
SELECT 
    d.doctor_id AS "Κωδικός Ιατρού",
    p.first_name AS "Όνομα",
    p.last_name AS "Επώνυμο",
    ROUND(AVG(de.medical_care), 2) AS "Μέση Αξιολόγηση Ιατρού (Φροντίδα)",
    ROUND(AVG(ae.overall_experience), 2) AS "Μέση Αξιολόγηση Νοσηλείας (Συνολική)"
FROM doctors d
JOIN personnel p ON d.doctor_id = p.personnel_id
JOIN doctor_evaluation de ON d.doctor_id = de.doctor_id
JOIN admission_evaluation ae ON de.admission_id = ae.admission_id
WHERE d.doctor_id = 11
GROUP BY 
    d.doctor_id, 
    p.first_name, 
    p.last_name;

-- 4b --

-- Δημιουργία του ευρετηρίου
CREATE INDEX idx_q4_doctor_eval ON doctor_evaluation(doctor_id);

-- Εξαναγκασμός χρήσης Index
SET enable_seqscan = OFF;

-- Τρέχουμε πάλι το πλάνο
EXPLAIN ANALYZE
SELECT 
    d.doctor_id AS "Κωδικός Ιατρού",
    p.first_name AS "Όνομα",
    p.last_name AS "Επώνυμο",
    ROUND(AVG(de.medical_care), 2) AS "Μέση Αξιολόγηση Ιατρού (Φροντίδα)",
    ROUND(AVG(ae.overall_experience), 2) AS "Μέση Αξιολόγηση Νοσηλείας (Συνολική)"
FROM doctors d
JOIN personnel p ON d.doctor_id = p.personnel_id
JOIN doctor_evaluation de ON d.doctor_id = de.doctor_id
JOIN admission_evaluation ae ON de.admission_id = ae.admission_id
WHERE d.doctor_id = 11
GROUP BY 
    d.doctor_id, 
    p.first_name, 
    p.last_name;

-- Επαναφορά της βάσης στην κανονική της λειτουργία (ΣΗΜΑΝΤΙΚΟ!)
SET enable_seqscan = ON;

-- 5 --

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

-- 6a --

EXPLAIN ANALYZE
SELECT 
    a.admission_id AS "Κωδικός Νοσηλείας",
    a.admission_date AS "Ημ/νία Εισαγωγής",
    a.discharge_date AS "Ημ/νία Εξιτηρίου",
    din.icd_description AS "Διάγνωση Εισαγωγής",
    dout.icd_description AS "Διάγνωση Εξιτηρίου",
    a.total_cost AS "Συνολικό Κόστος",
    ROUND((ae.medical_care + ae.nursing_care + ae.hygiene + ae.food + ae.overall_experience) / 5.0, 2) AS "Μέση Αξιολόγηση"
FROM 
    admission a
LEFT JOIN 
    diagnosis din ON a.admission_diagnosis = din.icd_id
LEFT JOIN 
    diagnosis dout ON a.discharge_diagnosis = dout.icd_id
LEFT JOIN 
    admission_evaluation ae ON a.admission_id = ae.admission_id
WHERE 
    a.patient_id = 5;

-- 6b --

CREATE INDEX idx_q6_patient ON admission(patient_id);

SET enable_seqscan = OFF;

EXPLAIN ANALYZE
SELECT 
    a.admission_id AS "Κωδικός Νοσηλείας",
    a.admission_date AS "Ημ/νία Εισαγωγής",
    a.discharge_date AS "Ημ/νία Εξιτηρίου",
    din.icd_description AS "Διάγνωση Εισαγωγής",
    dout.icd_description AS "Διάγνωση Εξιτηρίου",
    a.total_cost AS "Συνολικό Κόστος",
    ROUND((ae.medical_care + ae.nursing_care + ae.hygiene + ae.food + ae.overall_experience) / 5.0, 2) AS "Μέση Αξιολόγηση"
FROM 
    admission a
LEFT JOIN 
    diagnosis din ON a.admission_diagnosis = din.icd_id
LEFT JOIN 
    diagnosis dout ON a.discharge_diagnosis = dout.icd_id
LEFT JOIN 
    admission_evaluation ae ON a.admission_id = ae.admission_id
WHERE 
    a.patient_id = 5;

SET enable_seqscan = ON;

-- 7 --

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

-- 8 -- 

SELECT 
    p.personnel_id,
    p.first_name,
    p.last_name,
    p.personnel_type
FROM 
    personnel p
WHERE 
    p.personnel_id NOT IN (
        -- Υποερώτημα (Subquery): Βρίσκουμε το προσωπικό που ΕΧΕΙ προγραμματιστεί
        -- για βάρδια τη συγκεκριμένη ημερομηνία και στο συγκεκριμένο τμήμα
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
    p.personnel_type, 
    p.last_name;

-- 9 --

WITH YearlyPatientStats AS (
    -- Βήμα 1: Υπολογίζουμε τις συνολικές ημέρες ανά ασθενή ΜΟΝΟ για το 2025
    SELECT 
        p.patient_id,
        p.first_name,
        p.last_name,
        EXTRACT(YEAR FROM a.admission_date) AS admission_year,
        SUM(COALESCE(a.discharge_date, CURRENT_DATE) - a.admission_date) AS total_days
    FROM admission a
    JOIN patients p ON a.patient_id = p.patient_id
    WHERE 
        EXTRACT(YEAR FROM a.admission_date) = 2025 -- Εδώ μπαίνει ο περιορισμός του έτους!
    GROUP BY 
        p.patient_id, 
        p.first_name, 
        p.last_name, 
        EXTRACT(YEAR FROM a.admission_date)
    HAVING 
        SUM(COALESCE(a.discharge_date, CURRENT_DATE) - a.admission_date) > 15
),
GroupedPatients AS (
    -- Βήμα 2: Μετράμε πόσοι ασθενείς έχουν τον ίδιο αριθμό ημερών 
    SELECT 
        patient_id,
        first_name AS "Όνομα",
        last_name AS "Επώνυμο",
        admission_year AS "Έτος",
        total_days AS "Συνολικές Ημέρες",
        COUNT(patient_id) OVER (PARTITION BY total_days) AS patients_with_same_days
    FROM YearlyPatientStats
)
-- Βήμα 3: Εμφανίζουμε μόνο όσους βρήκαν "ταίρι"
SELECT 
    "Όνομα",
    "Επώνυμο",
    "Έτος",
    "Συνολικές Ημέρες"
FROM GroupedPatients
WHERE patients_with_same_days > 1
ORDER BY "Συνολικές Ημέρες" DESC, "Επώνυμο";

-- 10 -- 

WITH AdmissionSubstances AS (
    -- Βρίσκουμε τις μοναδικές δραστικές ουσίες ανά νοσηλεία (admission_id)
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
    AND a1.active_substance < a2.active_substance -- Η συνθήκη '<' εξασφαλίζει μοναδικά ζεύγη και αποτρέπει συνδυασμούς της ουσίας με τον εαυτό της
GROUP BY 
    a1.active_substance, 
    a2.active_substance
ORDER BY 
    Συχνότητα DESC
LIMIT 3;

-- 11 --

WITH YearlySurgeries AS (
    -- Βήμα 1: Υπολογίζουμε τα χειρουργεία ανά ιατρό για το τρέχον έτος
    SELECT 
        ma.surgeon_id,
        COUNT(ma.medical_act_id) AS surgery_count
    FROM 
        medical_acts ma
    JOIN 
        admission a ON ma.admission_id = a.admission_id
    WHERE 
        ma.medical_act_category = 'Χειρουργική'
        -- Παίρνουμε μόνο το έτος από την ημερομηνία εισαγωγής και το συγκρίνουμε με το τρέχον έτος
        AND EXTRACT(YEAR FROM a.admission_date) = EXTRACT(YEAR FROM CURRENT_DATE)
    GROUP BY 
        ma.surgeon_id
),
MaxSurgeries AS (
    -- Βήμα 2: Βρίσκουμε τον ιατρό με τα περισσότερα χειρουργεία
    SELECT MAX(surgery_count) AS max_count 
    FROM YearlySurgeries
)
-- Βήμα 3: Εμφανίζουμε όσους έχουν κάνει <= (max - 5)
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

-- 12 --

SELECT 
    d.department_description AS "Τμήμα",
    s.shift_date AS "Ημερομηνία Βάρδιας",
    s.shift_type AS "Τύπος Βάρδιας",
    p.personnel_type AS "Τύπος Προσωπικού",
    -- Δημιουργία ενιαίας στήλης για την "υποκλάση" ανάλογα με τον τύπο του υπαλλήλου
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
-- Συνδέουμε τους πίνακες των υποκλάσεων
LEFT JOIN 
    doctors doc ON p.personnel_id = doc.doctor_id
LEFT JOIN 
    nurses n ON p.personnel_id = n.nurse_id
LEFT JOIN 
    administrative_personnel ap ON p.personnel_id = ap.admin_id
WHERE 
    -- Φίλτρο για την εβδομάδα που ξεκινάει στις 2026-05-01
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

-- 13 --

WITH RECURSIVE SupervisionHierarchy AS (
    -- 1. ΒΑΣΙΚΟ ΣΚΕΛΟΣ (Base Case): 
    -- Βρίσκουμε τον άμεσο επόπτη για κάθε ιατρό και το ορίζουμε ως Επίπεδο 1
    SELECT 
        doctor_id AS original_doctor_id,
        supervisor_id AS current_supervisor_id,
        1 AS hierarchy_level
    FROM 
        doctors
    WHERE 
        supervisor_id IS NOT NULL
        
    UNION ALL
    
    -- 2. ΑΝΑΔΡΟΜΙΚΟ ΣΚΕΛΟΣ (Recursive Step): 
    -- Παίρνουμε τον προηγούμενο επόπτη και βρίσκουμε τον δικό του επόπτη, αυξάνοντας το επίπεδο
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
-- 3. ΤΕΛΙΚΟ ΕΡΩΤΗΜΑ (Εμφάνιση αποτελεσμάτων με τα ονόματα και τις βαθμίδες στα Ελληνικά)
SELECT 
    sh.original_doctor_id AS "Κωδικός Ιατρού",
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
    "Κωδικός Ιατρού", 
    "Επίπεδο Ιεραρχίας";

-- 14 --

WITH YearlyDiagnosisCounts AS (
    -- Βρίσκουμε τον αριθμό εισαγωγών ανά διάγνωση ΜΟΝΟ για τα έτη 2025 και 2026
    SELECT 
        a.admission_diagnosis AS icd_id,
        EXTRACT(YEAR FROM a.admission_date) AS admission_year,
        COUNT(a.admission_id) AS total_admissions
    FROM 
        admission a
    WHERE 
        a.admission_diagnosis IS NOT NULL
        -- Εδώ προσθέτουμε τον περιορισμό για τα συγκεκριμένα έτη
        AND EXTRACT(YEAR FROM a.admission_date) IN (2025, 2026)
    GROUP BY 
        a.admission_diagnosis, 
        EXTRACT(YEAR FROM a.admission_date)
    HAVING 
        COUNT(a.admission_id) >= 5
)
-- Συνδέουμε το 2025 με το 2026 για να βρούμε ίδιο αριθμό περιστατικών
SELECT 
    y1.icd_id AS "Κωδικός ICD",
    d.icd_description AS "Περιγραφή Διάγνωσης",
    y1.admission_year AS "Αρχικό Έτος",
    y2.admission_year AS "Επόμενο Έτος",
    y1.total_admissions AS "Αριθμός Νοσηλειών"
FROM 
    YearlyDiagnosisCounts y1
JOIN 
    YearlyDiagnosisCounts y2 
        ON y1.icd_id = y2.icd_id 
        AND y1.admission_year = 2025 -- Το y1 αντιπροσωπεύει αυστηρά το 2025
        AND y2.admission_year = 2026 -- Το y2 αντιπροσωπεύει αυστηρά το 2026
        AND y1.total_admissions = y2.total_admissions
JOIN 
    diagnosis d ON y1.icd_id = d.icd_id
ORDER BY 
    "Αριθμός Νοσηλειών" DESC, 
    "Κωδικός ICD";

-- 15 --

WITH LevelStats AS (
    -- Βήμα 1: Υπολογισμός συνολικών στατιστικών ανά επίπεδο επείγοντος
    SELECT 
        emergency_level,
        COUNT(case_id) AS total_cases_in_level,
        -- Η αφαίρεση δύο TIMESTAMPs στην PostgreSQL επιστρέφει αυτόματα τύπο INTERVAL (π.χ. "00:15:30")
        AVG(handled_time - arrival_time) AS avg_wait_time,
        -- Υπολογισμός ποσοστού: (Περιστατικά με νοσηλεία / Συνολικά Περιστατικά) * 100
        ROUND((COUNT(admission_id) * 100.0) / COUNT(case_id), 2) AS admission_percentage
    FROM 
        emergency_case
    GROUP BY 
        emergency_level
),
DeptDistribution AS (
    -- Βήμα 2: Κατανομή των παραπομπών (νοσηλειών) ανά τμήμα για κάθε επίπεδο
    SELECT 
        ec.emergency_level,
        d.department_description,
        COUNT(ec.case_id) AS cases_referred_to_dept
    FROM 
        emergency_case ec
    JOIN 
        admission a ON ec.admission_id = a.admission_id
    JOIN 
        departments d ON a.department_id = d.department_id
    GROUP BY 
        ec.emergency_level, 
        d.department_description
)
-- Βήμα 3: Τελική συνένωση με Ελληνικές επικεφαλίδες
SELECT 
    ls.emergency_level AS "Επίπεδο Επείγοντος",
    ls.total_cases_in_level AS "Συνολικά Περιστατικά",
    ls.avg_wait_time AS "Μέσος Χρόνος Αναμονής",
    ls.admission_percentage AS "Ποσοστό Νοσηλειών (%)",
    dd.department_description AS "Τμήμα Παραπομπής",
    dd.cases_referred_to_dept AS "Περιστατικά ανά Τμήμα"
FROM 
    LevelStats ls
LEFT JOIN 
    DeptDistribution dd ON ls.emergency_level = dd.emergency_level
ORDER BY 
    "Επίπεδο Επείγοντος", 
    "Περιστατικά ανά Τμήμα" DESC;