CREATE OR REPLACE FUNCTION insert_noshleuths(
    p_amka VARCHAR, 
    p_onoma VARCHAR, 
    p_eponimo VARCHAR,
    p_hlikia INT,
    p_email VARCHAR, 
    p_thlefono VARCHAR, 
    p_proslhpsh DATE,
    p_vathmida VARCHAR
) RETURNS VOID AS $$
DECLARE
    new_id INT;
    random_tmhma_id INT;
BEGIN
   
    INSERT INTO prosopiko (
        amka, onoma, eponimo, hlikia, 
        email, thlefono, hmeromhnia_proslhpshs, prosopiko_typos
    )
    VALUES (
        p_amka, p_onoma, p_eponimo, p_hlikia, 
        p_email, p_thlefono, p_proslhpsh, 'Νοσηλευτής'
    )
    RETURNING prosopiko_id INTO new_id;

    SELECT tmhma_id INTO random_tmhma_id 
    FROM TMHMATA 
    ORDER BY RANDOM() 
    LIMIT 1;

    INSERT INTO noshleutes (noshleuths_id, tmhma_id, vathmida)
    VALUES (new_id, random_tmhma_id, p_vathmida);

END;
$$ LANGUAGE plpgsql;