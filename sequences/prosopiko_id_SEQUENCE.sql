CREATE SEQUENCE IF NOT EXISTS prosopiko_id_seq;

ALTER SEQUENCE prosopiko_id_seq
OWNED BY prosopiko.prosopiko_id;

ALTER TABLE prosopiko
ALTER COLUMN prosopiko_id
SET DEFAULT nextval('prosopiko_id_seq');

SELECT setval(
    'prosopiko_id_seq',
    COALESCE((SELECT MAX(prosopiko_id) FROM prosopiko), 0)
);