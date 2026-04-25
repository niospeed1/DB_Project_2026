INSERT INTO tmhmata (tmhma_id, perigrafh, arithmos_klinwn, orofos, kthrio) VALUES (1, 'Παθολογικό', 7, 2, 3);
INSERT INTO tmhmata (tmhma_id, perigrafh, arithmos_klinwn, orofos, kthrio) VALUES (2, 'Καρδιολογικό', 7, 3, 1);
INSERT INTO tmhmata (tmhma_id, perigrafh, arithmos_klinwn, orofos, kthrio) VALUES (3, 'Χειρουργικό', 10, 1, 2);
INSERT INTO tmhmata (tmhma_id, perigrafh, arithmos_klinwn, orofos, kthrio) VALUES (4, 'Ορθοπεδικό', 8, 4, 2);
INSERT INTO tmhmata (tmhma_id, perigrafh, arithmos_klinwn, orofos, kthrio) VALUES (5, 'Παιδιατρικό', 8, 3, 1);
INSERT INTO tmhmata (tmhma_id, perigrafh, arithmos_klinwn, orofos, kthrio) VALUES (6, 'Μαιευτικό-Γυναικολογικό', 9, 3, 1);
INSERT INTO tmhmata (tmhma_id, perigrafh, arithmos_klinwn, orofos, kthrio) VALUES (7, 'Οφθαλμολογικό', 9, 3, 3);
INSERT INTO tmhmata (tmhma_id, perigrafh, arithmos_klinwn, orofos, kthrio) VALUES (8, 'ΩΡΛ', 10, 1, 2);
INSERT INTO tmhmata (tmhma_id, perigrafh, arithmos_klinwn, orofos, kthrio) VALUES (9, 'Νευρολογικό', 5, 1, 2);
INSERT INTO tmhmata (tmhma_id, perigrafh, arithmos_klinwn, orofos, kthrio) VALUES (10, 'Ψυχιατρικό', 5, 1, 3);
INSERT INTO tmhmata (tmhma_id, perigrafh, arithmos_klinwn, orofos, kthrio) VALUES (11, 'Δερματολογικό', 7, 2, 2);
INSERT INTO tmhmata (tmhma_id, perigrafh, arithmos_klinwn, orofos, kthrio) VALUES (12, 'Ουρολογικό', 5, 1, 2);
INSERT INTO tmhmata (tmhma_id, perigrafh, arithmos_klinwn, orofos, kthrio) VALUES (13, 'Ογκολογικό', 6, 1, 3);
INSERT INTO tmhmata (tmhma_id, perigrafh, arithmos_klinwn, orofos, kthrio) VALUES (14, 'Πνευμονολογικό', 5, 1, 1);
INSERT INTO tmhmata (tmhma_id, perigrafh, arithmos_klinwn, orofos, kthrio) VALUES (15, 'ΜΕΘ (Εντατική)', 8, 5, 2);
INSERT INTO tmhmata (tmhma_id, perigrafh, arithmos_klinwn, orofos, kthrio) VALUES (16, 'ΤΕΠ (Επείγοντα)', 9, 3, 1);
INSERT INTO tmhmata (tmhma_id, perigrafh, arithmos_klinwn, orofos, kthrio) VALUES (17, 'Αιματολογικό', 7, 1, 2);

//edw prepei na treksoyme prwta tis eisagwges twn iatrwn

WITH NumberedTmhmata AS (
    -- Βάζουμε έναν αύξοντα αριθμό (1 έως 17) σε κάθε τμήμα
    SELECT tmhma_id, ROW_NUMBER() OVER () as rn 
    FROM tmhmata
),
UniqueDirectors AS (
    -- Ανακατεύουμε τους Διευθυντές και τους βάζουμε κι αυτούς στη σειρά (1, 2, 3...)
    SELECT iatros_id, ROW_NUMBER() OVER (ORDER BY RANDOM()) as rn 
    FROM iatroi 
    WHERE vathmida = 'Διευθυντής'
)
-- Κάνουμε την ενημέρωση "ζευγαρώνοντας" το rn του τμήματος με το rn του Διευθυντή
UPDATE tmhmata 
SET dieuthintis = ud.iatros_id
FROM NumberedTmhmata nt
JOIN UniqueDirectors ud ON nt.rn = ud.rn
WHERE tmhmata.tmhma_id = nt.tmhma_id;