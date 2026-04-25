CREATE TABLE prosopiko (
    prosopiko_id INT PRIMARY KEY,
    prosopiko_typos VARCHAR(50) NOT NULL,
    amka CHAR(11) NOT NULL UNIQUE,
    onoma VARCHAR(50) NOT NULL,
    eponimo VARCHAR(50) NOT NULL,
    hlikia INT,
    email VARCHAR(100),
    thlefono VARCHAR(20),
    hmeromhnia_proslhpshs DATE
);

CREATE TABLE iatroi (
    iatros_id INT PRIMARY KEY,
    arithmos_adeias VARCHAR(30) NOT NULL UNIQUE,
    arithmos_sullogou VARCHAR(30) NOT NULL UNIQUE,
    eidikothta VARCHAR(100) NOT NULL,
    vathmida VARCHAR(50),
    CONSTRAINT fk_iatroi_prosopiko
        FOREIGN KEY (iatros_id)
        REFERENCES prosopiko(prosopiko_id)
);

ALTER TABLE iatroi ADD COLUMN epoptis_id INT NULL;

ALTER TABLE iatroi 
ADD CONSTRAINT fk_epoptis
FOREIGN KEY (epoptis_id)
REFERENCES iatroi(iatros_id);

CREATE TABLE noshleutes (
    noshleuths_id INT PRIMARY KEY,
    vathmida VARCHAR(50),
    CONSTRAINT fk_noshleutes_prosopiko
        FOREIGN KEY (noshleuths_id)
        REFERENCES prosopiko(prosopiko_id)
);

CREATE TABLE dioikitiko_prosopiko (
    dioikhtikos_id INT PRIMARY KEY,
    kathikon VARCHAR(100) NOT NULL,
    grafeio VARCHAR(100),
    CONSTRAINT fk_dioikitiko_prosopiko_prosopiko
        FOREIGN KEY (dioikhtikos_id)
        REFERENCES prosopiko(prosopiko_id)
);

CREATE TABLE tmhmata (
    tmhma_id SERIAL PRIMARY KEY,
    perigrafh VARCHAR(150) NOT NULL,
    arithmos_klinwn INT NOT NULL,
    orofos INT,
    kthrio VARCHAR(100),
    dieuthintis INT,
    CONSTRAINT fk_tmhmata_dieuthintis
        FOREIGN KEY (dieuthintis)
        REFERENCES iatroi(iatros_id)
);

ALTER TABLE noshleutes
ADD COLUMN tmhma_id INT;

ALTER TABLE noshleutes
ADD CONSTRAINT fk_noshleutes_tmhmata
FOREIGN KEY (tmhma_id)
REFERENCES tmhmata(tmhma_id);

ALTER TABLE dioikitiko_prosopiko
ADD COLUMN tmhma_id INT;

ALTER TABLE dioikitiko_prosopiko
ADD CONSTRAINT fk_dioikitiko_prosopiko_tmhmata
FOREIGN KEY (tmhma_id)
REFERENCES tmhmata(tmhma_id);

CREATE TABLE iatros_tmhma (
    iatros_id INT,
    tmhma_id INT,
    CONSTRAINT pk_iatros_tmhma
        PRIMARY KEY (iatros_id, tmhma_id),
    CONSTRAINT fk_iatros_tmhma_iatroi
        FOREIGN KEY (iatros_id)
        REFERENCES iatroi(iatros_id),
    CONSTRAINT fk_iatros_tmhma_tmhmata
        FOREIGN KEY (tmhma_id)
        REFERENCES tmhmata(tmhma_id)
);

CREATE TABLE klines (
    klinh_id SERIAL PRIMARY KEY,
    tupos VARCHAR(50) NOT NULL,
    katastasi VARCHAR(50) NOT NULL,
    tmhma_id INT,
    CONSTRAINT fk_klines_tmhmata
        FOREIGN KEY (tmhma_id)
        REFERENCES tmhmata(tmhma_id)
);

CREATE TABLE efhmeria (
    efhmeria_id SERIAL PRIMARY KEY,
    tmhma_id INT NOT NULL,
    hmeromhnia DATE NOT NULL,
    vardia VARCHAR(50) NOT NULL,
    CONSTRAINT fk_efhmeria_tmhmata
        FOREIGN KEY (tmhma_id)
        REFERENCES tmhmata(tmhma_id)
);

CREATE TYPE typos_vardias AS ENUM ('ΠΡΩΙ', 'ΑΠΟΓΕΥΜΑ', 'ΝΥΧΤΑ');

ALTER TABLE efhmeria 
ALTER COLUMN vardia TYPE typos_vardias 
USING vardia::typos_vardias;

ALTER TABLE efhmeria 
ADD COLUMN status VARCHAR(20) DEFAULT 'DRAFT' NOT NULL;

CREATE TABLE prosopiko_efhmerias (
    efhmeria_id INT,
    prosopiko_id INT,
    CONSTRAINT pk_prosopiko_efhmerias
        PRIMARY KEY (efhmeria_id, prosopiko_id),
    CONSTRAINT fk_prosopiko_efhmerias_efhmeria
        FOREIGN KEY (efhmeria_id)
        REFERENCES efhmeria(efhmeria_id),
    CONSTRAINT fk_prosopiko_efhmerias_prosopiko
        FOREIGN KEY (prosopiko_id)
        REFERENCES prosopiko(prosopiko_id)
);

CREATE TABLE astheneis (
    asthenhs_id SERIAL PRIMARY KEY,
    patronimo VARCHAR(100),
    amka CHAR(11) NOT NULL UNIQUE,
    onoma VARCHAR(100) NOT NULL,
    eponimo VARCHAR(100) NOT NULL,
    hlikia INT,
    fulo VARCHAR(20),
    varos NUMERIC(5,2),
    thlefono VARCHAR(20),
    ypsos NUMERIC(5,2),
    dieuthinsi VARCHAR(200),
    email VARCHAR(100),
    epaggelma VARCHAR(100),
    yphkoothta VARCHAR(100),
    oikeio_atomo VARCHAR(100),
    asfalistikos_foreas VARCHAR(100),
    allergies TEXT
);

CREATE TABLE diagnosi (
    diagnosi_id SERIAL PRIMARY KEY,
    icd_id VARCHAR(20) NOT NULL,
    perigrafh TEXT NOT NULL
);

CREATE TABLE farmaka (
    farmako_id SERIAL PRIMARY KEY,
    drastikh_ousia VARCHAR(100) NOT NULL
);

CREATE TABLE ken (
    ken_id SERIAL PRIMARY KEY,
    kostos NUMERIC(10,2) NOT NULL,
    mdn VARCHAR(50) NOT NULL
);

CREATE TABLE noshleia (
    noshleia_id SERIAL PRIMARY KEY,
    asthenis_id INT NOT NULL,
    tmhma_id INT NOT NULL,
    hmeromhnia_eisagwghs DATE NOT NULL,
    hmeromhnia_eksodou DATE,
    diagnwsh_eisagwghs INT,
    diagnwsh_eksodou INT,
    ken_id INT,
    ergastiriakes_eksetaseis TEXT,
    iatrikh_praksi TEXT,
    farmakeutikh_agwgi TEXT,
    aksiologhsh_noshleias TEXT,
    klinh_id INT,
    CONSTRAINT fk_noshleia_astheneis
        FOREIGN KEY (asthenis_id)
        REFERENCES astheneis(asthenhs_id),
    CONSTRAINT fk_noshleia_tmhmata
        FOREIGN KEY (tmhma_id)
        REFERENCES tmhmata(tmhma_id),
    CONSTRAINT fk_noshleia_diagnwsh_eisagwghs
        FOREIGN KEY (diagnwsh_eisagwghs)
        REFERENCES diagnosi(diagnosi_id),
    CONSTRAINT fk_noshleia_diagnwsh_eksodou
        FOREIGN KEY (diagnwsh_eksodou)
        REFERENCES diagnosi(diagnosi_id),
    CONSTRAINT fk_noshleia_ken
        FOREIGN KEY (ken_id)
        REFERENCES ken(ken_id),
    CONSTRAINT fk_noshleia_klines
        FOREIGN KEY (klinh_id)
        REFERENCES klines(klinh_id)
);

CREATE TABLE aksiologhsh_noshleias (
    aksiologhsh_id SERIAL PRIMARY KEY,
    noshleia_id INT NOT NULL UNIQUE,
    iatrikh_frontida INT,
    noshleutikh_frontida INT,
    kathariothta INT,
    faghto INT,
    sunolikh_empeiria INT,
    CONSTRAINT fk_aksiologhsh_noshleias_noshleia
        FOREIGN KEY (noshleia_id)
        REFERENCES noshleia(noshleia_id)
);

CREATE TABLE suntagografhsh (
    syntagografhsh_id SERIAL PRIMARY KEY,
    iatros_id INT NOT NULL,
    asthenis_id INT NOT NULL,
    farmako_id INT NOT NULL,
    noshleia_id INT,
    dosologia VARCHAR(100) NOT NULL,
    suxnothta VARCHAR(100) NOT NULL,
    hmeromhnia_enarkshs DATE NOT NULL,
    hmeromhnia_lhkshs DATE,
    CONSTRAINT fk_suntagografhsh_iatroi
        FOREIGN KEY (iatros_id)
        REFERENCES iatroi(iatros_id),
    CONSTRAINT fk_suntagografhsh_astheneis
        FOREIGN KEY (asthenis_id)
        REFERENCES astheneis(asthenhs_id),
    CONSTRAINT fk_suntagografhsh_farmaka
        FOREIGN KEY (farmako_id)
        REFERENCES farmaka(farmako_id),
    CONSTRAINT fk_suntagografhsh_noshleia
        FOREIGN KEY (noshleia_id)
        REFERENCES noshleia(noshleia_id)
);

CREATE TABLE ergastiriakes_eksetaseis (
    ergasthriakh_eksetasi_id SERIAL PRIMARY KEY,
    noshleia_id INT NOT NULL,
    tupos VARCHAR(100) NOT NULL,
    hmeromhnia DATE NOT NULL,
    apotelesma TEXT,
    kostos INT,
    iatros_id INT,
    CONSTRAINT fk_ergastiriakes_eksetaseis_noshleia
        FOREIGN KEY (noshleia_id)
        REFERENCES noshleia(noshleia_id),
    CONSTRAINT fk_ergastiriakes_eksetaseis_iatroi
        FOREIGN KEY (iatros_id)
        REFERENCES iatroi(iatros_id)
);

CREATE TABLE peristatiko_epeigontwn (
    peristatiko_id SERIAL PRIMARY KEY,
    asthenhs_id INT NOT NULL,
    noshleia_id INT,
    noshleuths_dialoghs INT NOT NULL,
    simptwmata TEXT,
    epipedo_epeigontos VARCHAR(50),
    ekvash TEXT,
    CONSTRAINT fk_peristatiko_epeigontwn_astheneis
        FOREIGN KEY (asthenhs_id)
        REFERENCES astheneis(asthenhs_id),
    CONSTRAINT fk_peristatiko_epeigontwn_noshleia
        FOREIGN KEY (noshleia_id)
        REFERENCES noshleia(noshleia_id),
    CONSTRAINT fk_peristatiko_epeigontwn_noshleutes
        FOREIGN KEY (noshleuths_dialoghs)
        REFERENCES noshleutes(noshleuths_id)
);

CREATE TABLE iatrikh_praksi (
    iatrikh_praksi_id SERIAL PRIMARY KEY,
    onoma VARCHAR(100) NOT NULL,
    kathgoria VARCHAR(100),
    diarkeia INT,
    kostos NUMERIC(10,2),
    xwros VARCHAR(100),
    xeirourgos_id INT,
    noshleia_id INT,
    CONSTRAINT fk_iatrikh_praksi_iatroi
        FOREIGN KEY (xeirourgos_id)
        REFERENCES iatroi(iatros_id),
    CONSTRAINT fk_iatrikh_praksi_noshleia
        FOREIGN KEY (noshleia_id)
        REFERENCES noshleia(noshleia_id)
);

CREATE TABLE voithoi_praksis (
    iatrikh_praksi_id INT,
    prosopiko_id INT,
    CONSTRAINT pk_voithoi_praksis
        PRIMARY KEY (iatrikh_praksi_id, prosopiko_id),
    CONSTRAINT fk_voithoi_praksis_iatrikh_praksi
        FOREIGN KEY (iatrikh_praksi_id)
        REFERENCES iatrikh_praksi(iatrikh_praksi_id),
    CONSTRAINT fk_voithoi_praksis_prosopiko
        FOREIGN KEY (prosopiko_id)
        REFERENCES prosopiko(prosopiko_id)
);
