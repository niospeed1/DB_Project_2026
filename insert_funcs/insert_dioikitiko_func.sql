CREATE OR REPLACE FUNCTION insert_dioikitiko_prosopiko(
    p_amka VARCHAR, p_onoma VARCHAR, p_eponimo VARCHAR, p_hlikia INT,
    p_email VARCHAR, p_thlefono VARCHAR, p_proslhpsh DATE,
    p_kathikon VARCHAR, p_grafeio VARCHAR
) RETURNS VOID AS $$
DECLARE
    new_id INT;
    random_tmhma_id INT;
BEGIN
    -- 1. Εισαγωγή των γενικών στοιχείων στον πίνακα prosopiko
    -- Ορίζουμε τον τύπο προσωπικού ως 'dioikitikos' (ή ό,τι string χρησιμοποιείς στη βάση σου)
    INSERT INTO prosopiko (prosopiko_typos, amka, onoma, eponimo, hlikia, email, thlefono, hmeromhnia_proslhpshs)
    VALUES ('Διοικητικό Προσωπικό', p_amka, p_onoma, p_eponimo, p_hlikia, p_email, p_thlefono, p_proslhpsh)
    RETURNING prosopiko_id INTO new_id;

    -- 2. Τυχαία επιλογή ενός τμήματος (όπως κάναμε και στους ιατρούς)
    SELECT tmhma_id INTO random_tmhma_id 
    FROM TMHMATA 
    ORDER BY RANDOM() 
    LIMIT 1;

    -- 3. Εισαγωγή των εξειδικευμένων στοιχείων στον πίνακα dioikhtiko_prosopiko
    -- Εδώ περνάμε το new_id (από το RETURNING), τα πεδία από τις παραμέτρους, 
    -- και το τυχαίο tmhma_id που μόλις βρήκαμε.
    INSERT INTO dioikitiko_prosopiko (dioikhtikos_id, kathikon, grafeio, tmhma_id)
    VALUES (new_id, p_kathikon, p_grafeio, random_tmhma_id);

END;
$$ LANGUAGE plpgsql;