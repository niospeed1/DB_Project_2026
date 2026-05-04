
-- 2. Εισαγωγή με σωστή σειρά
INSERT INTO doctor_evaluation (admission_id, doctor_id, medical_care)
SELECT 
    unique_pairs.admission_id, 
    unique_pairs.doctor_id,
    floor(random() * 5 + 1)::int -- Ο βαθμός μπαίνει ΑΦΟΥ βρούμε τα μοναδικά ζευγάρια
FROM (
    -- Εδώ απομονώνουμε τα ζευγάρια χωρίς να επηρεάζει το random
    SELECT DISTINCT admission_id, doctor_id 
    FROM prescription
) AS unique_pairs
JOIN admission a ON unique_pairs.admission_id = a.admission_id
WHERE a.discharge_date IS NOT NULL;