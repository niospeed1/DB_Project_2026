INSERT INTO admission_evaluation (
    admission_id, 
    medical_care, 
    nursing_care, 
    hygiene, 
    food, 
    overall_experience
)
WITH RandomScores AS (
    SELECT 
        admission_id,
        floor(random() * 5 + 1)::int AS med,
        floor(random() * 5 + 1)::int AS nurs,
        floor(random() * 5 + 1)::int AS hyg,
        floor(random() * 5 + 1)::int AS fd
    FROM admission
    WHERE discharge_date IS NOT NULL
)
SELECT 
    admission_id,
    med,
    nurs,
    hyg,
    fd,
    ROUND((med + nurs + hyg + fd) / 4.0)::int AS overall_experience
FROM RandomScores;