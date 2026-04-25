CREATE OR REPLACE FUNCTION insert_iatros(
    p_amka VARCHAR, p_onoma VARCHAR, p_eponimo VARCHAR, p_hlikia INT,
    p_email VARCHAR, p_thlefono VARCHAR, p_proslhpsh DATE,
    p_eidikothta VARCHAR, p_vathmida VARCHAR,
    p_arithmos_adeias VARCHAR, p_arithmos_sullogou VARCHAR,
    p_tmhmata VARCHAR[] -- ΑΛΛΑΓΗ: Δέχεται τα ονόματα των τμημάτων, ΟΧΙ νούμερα
) RETURNS VOID AS $$
DECLARE
    new_id INT;
    v_epopths_id INT := NULL; 
    t_name VARCHAR; 
    found_tmhma_id INT;
BEGIN
    -- 1. Λογική Εποπτών (Όπως ακριβώς ήταν)
    IF p_vathmida = 'Ειδικευόμενος' THEN
        SELECT iatros_id INTO v_epopths_id FROM iatroi 
        WHERE vathmida IN ('Επιμελητής Β', 'Επιμελητής Α', 'Διευθυντής') 
        ORDER BY RANDOM() LIMIT 1;
        
        IF v_epopths_id IS NULL THEN
            RAISE EXCEPTION 'Αδυναμία εισαγωγής: Δεν βρέθηκε διαθέσιμος επόπτης.';
        END IF;

    ELSIF p_vathmida = 'Επιμελητής Β' THEN
        SELECT iatros_id INTO v_epopths_id FROM iatroi 
        WHERE vathmida IN ('Επιμελητής Α', 'Διευθυντής') 
        ORDER BY RANDOM() LIMIT 1;
        
    ELSIF p_vathmida = 'Επιμελητής Α' THEN
        SELECT iatros_id INTO v_epopths_id FROM iatroi 
        WHERE vathmida = 'Διευθυντής' 
        ORDER BY RANDOM() LIMIT 1;
    END IF;

    -- 2. Εισαγωγή σε Προσωπικό και Ιατρούς
    INSERT INTO prosopiko (prosopiko_typos, amka, onoma, eponimo, hlikia, email, thlefono, hmeromhnia_proslhpshs)
    VALUES ('Ιατρός', p_amka, p_onoma, p_eponimo, p_hlikia, p_email, p_thlefono, p_proslhpsh)
    RETURNING prosopiko_id INTO new_id;

    INSERT INTO iatroi (iatros_id, eidikothta, vathmida, arithmos_adeias, arithmos_sullogou, epoptis_id)
    VALUES (new_id, p_eidikothta, p_vathmida, p_arithmos_adeias, p_arithmos_sullogou, v_epopths_id);

    -- 3. Αλάνθαστη ανάθεση M:N (Βρίσκει το ID με βάση την περιγραφή)
    FOREACH t_name IN ARRAY p_tmhmata
    LOOP
        -- Ψάχνουμε να βρούμε το ID του τμήματος από το όνομά του
        SELECT tmhma_id INTO found_tmhma_id FROM TMHMATA WHERE perigrafh = t_name;
        
        IF found_tmhma_id IS NOT NULL THEN
            INSERT INTO IATROS_TMHMA (iatros_id, tmhma_id)
            VALUES (new_id, found_tmhma_id);
        END IF;
    END LOOP;

END;
$$ LANGUAGE plpgsql;