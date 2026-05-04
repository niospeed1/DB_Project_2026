CREATE OR REPLACE FUNCTION insert_doctor(
    p_amka VARCHAR, p_first_name VARCHAR, p_last_name VARCHAR, p_age INT,
    p_email VARCHAR, p_phone_number VARCHAR, p__hire_date DATE,
    p_specialty VARCHAR, p_rank VARCHAR,
    p_license_number VARCHAR, p_association_number VARCHAR,
    p_department VARCHAR[]
) RETURNS VOID AS $$
DECLARE
    new_id INT;
    v_supervisor_id INT := NULL; 
    t_name VARCHAR; 
    found_department_id INT;
BEGIN

    IF p_rank = 'Ειδικευόμενος' THEN
        SELECT doctor_id INTO v_supervisor_id FROM doctors 
        WHERE rank IN ('Επιμελητής Β', 'Επιμελητής Α', 'Διευθυντής') 
        ORDER BY RANDOM() LIMIT 1;
        
        IF v_supervisor_id IS NULL THEN
            RAISE EXCEPTION 'Αδυναμία εισαγωγής: Δεν βρέθηκε διαθέσιμος επόπτης.';
        END IF;

    ELSIF p_rank = 'Επιμελητής Β' THEN
        SELECT doctor_id INTO v_supervisor_id FROM doctors 
        WHERE rank IN ('Επιμελητής Α', 'Διευθυντής') 
        ORDER BY RANDOM() LIMIT 1;
        
    ELSIF p_rank = 'Επιμελητής Α' THEN
        SELECT doctor_id INTO v_supervisor_id FROM doctors 
        WHERE rank = 'Διευθυντής' 
        ORDER BY RANDOM() LIMIT 1;
    END IF;

    INSERT INTO personnel (personnel_type, amka, first_name, last_name, age, email, phone_number, hire_date)
    VALUES ('Ιατρός', p_amka, p_first_name, p_last_name, p_age, p_email, p_phone_number, p__hire_date)
    RETURNING personnel_id INTO new_id;

    INSERT INTO doctors (doctor_id, specialty, rank, license_number, association_number, supervisor_id)
    VALUES (new_id, p_specialty, p_rank, p_license_number, p_association_number, v_supervisor_id);

    FOREACH t_name IN ARRAY p_department
    LOOP

        SELECT department_id INTO found_department_id FROM departments WHERE department_description = t_name;
        
        IF found_department_id IS NOT NULL THEN
            INSERT INTO doctor_department (doctor_id, department_id)
            VALUES (new_id, found_department_id);
        END IF;
    END LOOP;

END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION insert_nurse(
    p_amka VARCHAR, 
    p_first_name VARCHAR, 
    p_last_name VARCHAR,
    p_age INT,
    p_email VARCHAR, 
    p_phone_number VARCHAR, 
    p_hire_date DATE,
    p_rank VARCHAR
) RETURNS VOID AS $$
DECLARE
    new_id INT;
    random_department_id INT;
BEGIN
   
    INSERT INTO personnel (
        amka, first_name, last_name, age, 
        email, phone_number, hire_date, personnel_type
    )
    VALUES (
        p_amka, p_first_name, p_last_name, p_age, 
        p_email, p_phone_number, p_hire_date, 'Νοσηλευτής'
    )
    RETURNING personnel_id INTO new_id;

    SELECT department_id INTO random_department_id 
    FROM departments 
    ORDER BY RANDOM() 
    LIMIT 1;

    INSERT INTO nurses (nurse_id, department_id, rank)
    VALUES (new_id, random_department_id, p_rank);

END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION insert_administrative_personnel(
    p_amka VARCHAR, p_first_name VARCHAR, p_last_name VARCHAR, p_age INT,
    p_email VARCHAR, p_phone_number VARCHAR, p_hire_date DATE,
    p_duty VARCHAR, p_office VARCHAR
) RETURNS VOID AS $$
DECLARE
    new_id INT;
    random_department_id INT;
BEGIN

    INSERT INTO personnel (personnel_type, amka, first_name, last_name, age, email, phone_number, hire_date)
    VALUES ('Διοικητικό Προσωπικό', p_amka, p_first_name, p_last_name, p_age, p_email, p_phone_number, p_hire_date)
    RETURNING personnel_id INTO new_id;

    -- 2. Τυχαία επιλογή ενός τμήματος (όπως κάναμε και στους ιατρούς)
    SELECT department_id INTO random_department_id 
    FROM departments 
    ORDER BY RANDOM() 
    LIMIT 1;

    INSERT INTO administrative_personnel (admin_id, duty, office, department_id)
    VALUES (new_id, p_duty, p_office, random_department_id);

END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE PROCEDURE process_emergency_cases()
LANGUAGE plpgsql
AS $$
DECLARE
    rec RECORD;
    v_handled_time TIMESTAMP;
    v_random_days INT;
    v_dept_id INT;
    v_room_id INT;
    v_adm_diag TEXT; 
    v_dis_diag TEXT; 
    v_ken_id INT; -- Νέα μεταβλητή για το Κλειστό Ενοποιημένο Νοσήλιο
    v_new_admission_id INT;
BEGIN
    -- 1. Επιλογή ασθενών (FIFO ανά ημέρα και προτεραιότητα Triage)
    FOR rec IN 
        SELECT * FROM emergency_case 
        WHERE handled_time IS NULL 
        ORDER BY 
            arrival_time::date ASC, 
            emergency_level::int ASC, 
            arrival_time ASC 
    LOOP
        
        -- 2. Υπολογισμός Handled Time βάσει Emergency Level
        v_handled_time := rec.arrival_time + (
            CASE 
                WHEN rec.emergency_level::text = '1' THEN (random() * 5 + 1) * INTERVAL '1 minute'
                WHEN rec.emergency_level::text = '2' THEN (random() * 15 + 5) * INTERVAL '1 minute'
                ELSE (random() * 45 + 15) * INTERVAL '1 minute'
            END
        );

        -- 3. Ενημέρωση του emergency_case
        UPDATE emergency_case 
        SET handled_time = v_handled_time 
        WHERE case_id = rec.case_id;

        -- 4. Διαδικασία Εισαγωγής
        IF rec.outcome = 'Νοσηλεία' THEN
            
            -- Α. Επιλογή υπαρκτού τμήματος (1-17, εκτός 16)
            SELECT department_id INTO v_dept_id 
            FROM departments 
            WHERE department_id BETWEEN 1 AND 17 
              AND department_id != 16 
            ORDER BY random() 
            LIMIT 1;

            IF v_dept_id IS NULL THEN
                CONTINUE; 
            END IF;

            -- Β. Επιλογή τυχαίου δωματίου που ανήκει στο επιλεγμένο τμήμα
            SELECT room_id INTO v_room_id 
            FROM rooms 
            WHERE department_id = v_dept_id 
            ORDER BY random() 
            LIMIT 1;

            -- Γ. Επιλογή τυχαίων κωδικών ICD-10 από τον πίνακα diagnosis
            SELECT icd_id INTO v_adm_diag FROM diagnosis ORDER BY random() LIMIT 1;
            SELECT icd_id INTO v_dis_diag FROM diagnosis ORDER BY random() LIMIT 1;

            -- Δ. Επιλογή τυχαίου ken_id από τον πίνακα ken
            SELECT ken_id INTO v_ken_id FROM ken ORDER BY random() LIMIT 1;

            -- Ε. Τυχαία διάρκεια νοσηλείας (2 έως 20 ημέρες)
            v_random_days := floor(random() * (20 - 2 + 1) + 2)::int;

            -- ΣΤ. Εισαγωγή στον πίνακα admission με δωμάτιο, διαγνώσεις και KEN
            INSERT INTO admission (
                patient_id, 
                department_id, 
                room_id,
                admission_date, 
                discharge_date,
                admission_diagnosis, 
                discharge_diagnosis,
                ken_id -- Προσθήκη του KEN
            ) VALUES (
                rec.patient_id::int,
                v_dept_id,
                v_room_id,
                v_handled_time::date,
                (v_handled_time + (v_random_days * INTERVAL '1 day'))::date,
                v_adm_diag,
                v_dis_diag,
                v_ken_id -- Ανάθεση του τυχαίου KEN
            )
            RETURNING admission_id INTO v_new_admission_id;

            -- Ζ. Ενημέρωση της σύνδεσης στο emergency_case
            UPDATE emergency_case 
            SET admission_id = v_new_admission_id 
            WHERE case_id = rec.case_id;

        END IF;
    END LOOP;
    
    COMMIT;
END;
$$;

CREATE OR REPLACE PROCEDURE populate_lab_exams()
LANGUAGE plpgsql
AS $$
DECLARE
    rec RECORD;
    v_category VARCHAR(50);
    v_type_id INT;
    v_cost_ken INT;
    v_doctor_id INT;
    v_date DATE;
    v_result TEXT;
    v_diff INT;
    
    v_counter INT := 0;      -- Μετρητής συνολικών εξετάσεων
    v_num_exams INT;         -- Πόσες εξετάσεις θα πάρει η τρέχουσα νοσηλεία
    
    -- Πίνακες για την τυχαία επιλογή
    v_categories TEXT[] := ARRAY['Αιματολογικές', 'Βιοχημικές', 'Απεικονιστικές'];
    v_phrases TEXT[] := ARRAY[
        'Χωρίς παθολογικά ευρήματα. Φυσιολογική απεικόνιση',
        'Ήπια εκφύλιση, συμβατή με την ηλικία του ασθενούς',
        'Μικρή συλλογή υγρού, χωρίς σημεία ενεργού φλεγμονής',
        'Εικόνα εντός φυσιολογικών ορίων',
        'Δεν παρατηρήθηκαν αλλοιώσεις στην εξεταζόμενη περιοχή',
        'Ανίχνευση μικρού μορφώματος, συνιστάται τακτικός επανέλεγχος',
        'Φυσιολογική μετεγχειρητική εικόνα, απουσία επιπλοκών'
    ];
BEGIN
    -- Τρέχουμε τη λούπα μέχρι να φτάσουμε ακριβώς τις 600 εξετάσεις
    WHILE v_counter < 600 LOOP
        
        -- Παίρνουμε ΜΙΑ τυχαία νοσηλεία
        SELECT admission_id, admission_date, discharge_date INTO rec
        FROM admission 
        ORDER BY random() 
        LIMIT 1;

        -- Επιλέγουμε τυχαία πόσες εξετάσεις θα γίνουν σε αυτή τη νοσηλεία (π.χ. από 1 έως 4)
        v_num_exams := floor(random() * 4 + 1)::int;

        -- Εσωτερική λούπα για να φτιάξουμε τις εξετάσεις αυτής της νοσηλείας
        FOR i IN 1..v_num_exams LOOP
            
            -- Έλεγχος ασφαλείας: Αν φτάσαμε τις 600, σταματάμε αμέσως την εισαγωγή
            IF v_counter >= 600 THEN
                EXIT;
            END IF;

            -- 1. Τυχαία κατηγορία
            v_category := v_categories[floor(random() * 3 + 1)::int];

            -- 2. Τυχαίο FK για τύπο, κόστος και γιατρό για ΤΗΝ ΤΡΕΧΟΥΣΑ εξέταση
            SELECT lab_exam_code_id INTO v_type_id FROM lab_exams_codes ORDER BY random() LIMIT 1;
            SELECT ken_id INTO v_cost_ken FROM ken ORDER BY random() LIMIT 1;
            SELECT doctor_id INTO v_doctor_id FROM doctors ORDER BY random() LIMIT 1;

            -- 3. Υπολογισμός ημερομηνίας (για να έχει κάθε εξέταση άλλη μέρα μέσα στη νοσηλεία)
            v_diff := COALESCE(rec.discharge_date, CURRENT_DATE) - rec.admission_date;
            IF v_diff < 0 THEN 
                v_diff := 0; 
            END IF;
            
            v_date := rec.admission_date + floor(random() * (v_diff + 1))::int;

            -- 4. Δημιουργία του Αποτελέσματος
            IF v_category IN ('Αιματολογικές', 'Βιοχημικές') THEN
                v_result := floor(random() * (250 - 10 + 1) + 10)::text || ' mg/dL';
            ELSE
                v_result := v_phrases[floor(random() * 7 + 1)::int];
            END IF;

            -- 5. Εισαγωγή στον πίνακα lab_exams 
            INSERT INTO lab_exams (
                admission_id,
                lab_exam_type,
                lab_exam_category,
                lab_exam_date,
                lab_exam_result,
                lab_exam_cost,
                doctor_id
            ) VALUES (
                rec.admission_id,
                v_type_id,
                v_category,
                v_date,
                v_result,
                v_cost_ken,
                v_doctor_id
            );

            -- Αυξάνουμε τον μετρητή των συνολικών εξετάσεων
            v_counter := v_counter + 1;
            
        END LOOP;
    END LOOP;
    
    COMMIT;
END;
$$;

CREATE OR REPLACE PROCEDURE populate_medical_acts()
LANGUAGE plpgsql
AS $$
DECLARE
    rec RECORD;
    v_category VARCHAR(50);
    v_type_id INT;
    v_duration INT;
    v_diff INT;
    v_cost_ken INT;
    v_location INT;
    v_surgeon_id INT;
    v_new_medical_act_id INT;
    v_num_docs INT;
    v_num_nurses INT;
    v_selected_dept_id INT;
BEGIN

    FOR i IN 1..600 LOOP
        
        SELECT a.admission_id, a.admission_date, a.discharge_date 
        INTO rec
        FROM admission a
        LEFT JOIN medical_acts ma ON a.admission_id = ma.admission_id
        GROUP BY a.admission_id, a.admission_date, a.discharge_date
        HAVING COUNT(ma.medical_act_id) < 2
        ORDER BY random() 
        LIMIT 1;

        IF NOT FOUND THEN
            CONTINUE;
        END IF;

        IF i <= 300 THEN
            v_category := 'Χειρουργική';
        ELSIF i <= 450 THEN
            v_category := 'Διαγνωστική';
        ELSE
            v_category := 'Θεραπευτική';
        END IF;

        SELECT medical_act_code_id INTO v_type_id 
        FROM medical_act_codes 
        ORDER BY random() 
        LIMIT 1;

        v_diff := rec.discharge_date - rec.admission_date;
        IF v_diff IS NULL OR v_diff <= 1 THEN
            v_duration := 0;
        ELSE
            v_duration := floor(random() * (v_diff - 1) + 1)::int;
        END IF;

        SELECT ken_id INTO v_cost_ken FROM ken ORDER BY random() LIMIT 1;

        IF v_category = 'Χειρουργική' THEN
            SELECT room_id::INT INTO v_location 
            FROM rooms 
            WHERE room_type IN ('Χειρουργείο', 'ΜΕΘ') 
            ORDER BY random() LIMIT 1;

            SELECT doctor_id INTO v_surgeon_id 
            FROM doctors 
            WHERE specialty = 'Χειρουργός' 
            ORDER BY random() LIMIT 1;

            SELECT department_id INTO v_selected_dept_id
            FROM doctor_department
            WHERE doctor_id = v_surgeon_id
            ORDER BY random() LIMIT 1;

        ELSE
        
            SELECT r.room_id, d.doctor_id, r.department_id
            INTO v_location, v_surgeon_id, v_selected_dept_id
            FROM rooms r
            JOIN doctor_department dd ON r.department_id = dd.department_id
            JOIN doctors d ON dd.doctor_id = d.doctor_id
            WHERE r.room_type NOT IN ('Χειρουργείο', 'ΜΕΘ') 
              AND d.specialty != 'Χειρουργός'
            ORDER BY random() LIMIT 1;
        END IF;

        IF v_location IS NULL OR v_surgeon_id IS NULL THEN
            CONTINUE;
        END IF;

        INSERT INTO medical_acts (
            admission_id,          
            medical_act_type, 
            medical_act_category, 
            duration, 
            medical_act_cost,      
            room_id, 
            surgeon_id
        ) VALUES (
            rec.admission_id,
            v_type_id,
            v_category,
            v_duration,
            v_cost_ken,
            v_location,
            v_surgeon_id
        ) RETURNING medical_act_id INTO v_new_medical_act_id;

        
        v_num_docs := floor(random() * 3)::int; 
        v_num_nurses := floor(random() * 4)::int; 

        IF v_selected_dept_id IS NOT NULL THEN
            
            IF v_num_docs > 0 THEN
                INSERT INTO medical_act_assistants (medical_act_id, personnel_id)
                SELECT v_new_medical_act_id, doctor_id
                FROM (
                    SELECT dd.doctor_id
                    FROM doctor_department dd
                    WHERE dd.department_id = v_selected_dept_id
                      AND dd.doctor_id != v_surgeon_id
                ) AS available_docs
                ORDER BY random() 
                LIMIT v_num_docs;
            END IF;

            IF v_num_nurses > 0 THEN
                INSERT INTO medical_act_assistants (medical_act_id, personnel_id)
                SELECT v_new_medical_act_id, nurse_id
                FROM nurses n
                WHERE n.department_id = v_selected_dept_id
                ORDER BY random()
                LIMIT v_num_nurses;
            END IF;
            
        END IF;
        
    END LOOP;
    
    COMMIT;
END;
$$;

CREATE OR REPLACE PROCEDURE populate_prescriptions()
LANGUAGE plpgsql
AS $$
DECLARE
    rec RECORD;
    drug_rec RECORD;
    v_doctor_id INT;
    v_start_date DATE;
    v_end_date DATE;
    v_dose VARCHAR(100);
    v_freq VARCHAR(100);
    v_num_drugs INT;
    
    -- Πίνακες για τυχαία δοσολογία και συχνότητα
    v_doses VARCHAR[] := ARRAY['500mg', '10mg', '20mg', '50mg', '1 xάπι', '2 xάπια', '1000mg'];
    v_freqs VARCHAR[] := ARRAY['1 φορά/μέρα', '2 φορές/μέρα', 'Ανά 8 ώρες', 'Προ ύπνου', 'Μετά το γεύμα'];
BEGIN
    -- Επιλέγουμε 300 τυχαίες νοσηλείες (τις φέρνουμε μαζί με το patient_id τους για ευκολία)
    FOR rec IN 
        SELECT admission_id, patient_id, discharge_date 
        FROM admission 
        ORDER BY random() 
        LIMIT 300
    LOOP
        -- Για να ικανοποιήσουμε το SCREENSHOT:
        -- Επιλέγουμε από 2 έως 4 φάρμακα για κάθε νοσηλεία, ώστε να δημιουργούνται "ζεύγη" και "συνδυασμοί"
        v_num_drugs := floor(random() * 3 + 2)::int;

        -- Ημερομηνία έναρξης: 1 μέρα μετά το εξιτήριο (με COALESCE για ασφάλεια αν δεν έχει εξιτήριο)
        v_start_date := COALESCE(rec.discharge_date, CURRENT_DATE) + 1;
        
        -- Ημερομηνία λήξης: Τυχαία 3 έως 15 μέρες μετά την έναρξη
        v_end_date := v_start_date + floor(random() * 13 + 3)::int;

        -- ΒΡΙΣΚΟΥΜΕ ΤΑ ΦΑΡΜΑΚΑ (ΕΛΕΓΧΟΣ ΑΛΛΕΡΓΙΑΣ)
        -- Τραβάμε N τυχαία και διαφορετικά φάρμακα που ΔΕΝ έχουν δραστική ουσία στην οποία είναι αλλεργικός ο ασθενής
        FOR drug_rec IN
            SELECT m.drug_id
            FROM medicine m
            WHERE NOT EXISTS (
                -- Αν το παρακάτω query επιστρέψει έστω και 1 γραμμή, το φάρμακο ΑΠΟΡΡΙΠΤΕΤΑΙ
                SELECT 1
                FROM medicine_substances ms
                JOIN patients p ON p.patient_id = rec.patient_id
                WHERE ms.drug_id = m.drug_id
                  -- Ψάχνουμε αν το όνομα της ουσίας υπάρχει μέσα στο κείμενο των αλλεργιών του ασθενούς (ILIKE)
                  AND COALESCE(p.allergies, '') ILIKE '%' || ms.active_substance || '%'
            )
            ORDER BY random()
            LIMIT v_num_drugs
        LOOP
            -- Τυχαίος γιατρός για τη συγκεκριμένη συνταγογράφηση
            SELECT doctor_id INTO v_doctor_id FROM doctors ORDER BY random() LIMIT 1;
            
            -- Τυχαία δόση και συχνότητα
            v_dose := v_doses[floor(random() * array_length(v_doses, 1) + 1)::int];
            v_freq := v_freqs[floor(random() * array_length(v_freqs, 1) + 1)::int];

            -- Εισαγωγή στον πίνακα prescription
            INSERT INTO prescription (
                doctor_id,
                patient_id,
                drug_id,
                admission_id,
                dose,
                frequency,
                start_date,
                end_date
            ) VALUES (
                v_doctor_id,
                rec.patient_id,
                drug_rec.drug_id,
                rec.admission_id,
                v_dose,
                v_freq,
                v_start_date,
                v_end_date
            );
        END LOOP;
        
    END LOOP;
    
    COMMIT;
END;
$$;

CREATE OR REPLACE PROCEDURE calculate_total_admission_costs()
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE admission a
    SET total_cost = 
        -- 1. Βασικό Κόστος Νοσηλείας (ΚΕΝ) & Πρόσθετη Ημερήσια Χρέωση
        COALESCE((
            SELECT 
                k.cost + 
                -- Αν (Ημέρες - ΜΔΝ) > 0, τότε χρεώνουμε τις επιπλέον μέρες με (cost/mdn) ανά ημέρα
                COALESCE(
                    GREATEST(0, (COALESCE(a.discharge_date, CURRENT_DATE) - a.admission_date) - k.mdn) 
                    * (k.cost / NULLIF(k.mdn, 0)), 
                0)
            FROM ken k
            WHERE k.ken_id = a.ken_id
        ), 0)
        
        + 
        
        -- 2. Συνολικό Κόστος Ιατρικών Πράξεων (Μέσω του medical_act_cost -> ken_id)
        COALESCE((
            SELECT SUM(k_ma.cost)
            FROM medical_acts ma
            JOIN ken k_ma ON ma.medical_act_cost = k_ma.ken_id
            WHERE ma.admission_id = a.admission_id
        ), 0)
        
        +
        
        -- 3. Συνολικό Κόστος Εργαστηριακών Εξετάσεων (Μέσω του lab_exam_cost -> ken_id)
        COALESCE((
            SELECT SUM(k_le.cost)
            FROM lab_exams le
            JOIN ken k_le ON le.lab_exam_cost = k_le.ken_id
            WHERE le.admission_id = a.admission_id
        ), 0);
        
    COMMIT;
END;
$$;


CREATE OR REPLACE FUNCTION validate_supervisor_trigger_fn()
RETURNS TRIGGER AS $$
DECLARE
    v_supervisor_rank VARCHAR;
BEGIN

    IF NEW.rank = 'Διευθυντής' AND NEW.supervisor_id IS NOT NULL THEN
        RAISE EXCEPTION 'Παραβίαση Ιεραρχίας: Οι Διευθυντές δεν επιτρέπεται να έχουν επόπτη.';
    END IF;

    IF NEW.rank = 'Ειδικευόμενος' AND NEW.supervisor_id IS NULL THEN
        RAISE EXCEPTION 'Παραβίαση Κανόνα: Οι Ειδικευόμενοι πρέπει υποχρεωτικά να έχουν επόπτη.';
    END IF;

    IF NEW.supervisor_id IS NOT NULL THEN

        SELECT rank INTO v_supervisor_rank 
        FROM doctors 
        WHERE doctor_id = NEW.supervisor_id;

        IF v_supervisor_rank IS NULL THEN
            RAISE EXCEPTION 'Σφάλμα Δεδομένων: Ο επόπτης με ID % δεν υπάρχει στο σύστημα.', NEW.supervisor_id;
        END IF;

        -- Αυστηροί έλεγχοι ποιος μπορεί να επιβλέπει ποιον
        IF NEW.rank = 'Ειδικευόμενος' AND v_supervisor_rank NOT IN ('Επιμελητής Β', 'Επιμελητής Α', 'Διευθυντής') THEN
            RAISE EXCEPTION 'Παραβίαση Ιεραρχίας: Ο επόπτης ενός Ειδικευόμενος πρέπει να είναι τουλάχιστον Επιμελητής Β.';
            
        ELSIF NEW.rank = 'Επιμελητής Β' AND v_supervisor_rank NOT IN ('Επιμελητής Α', 'Διευθυντής') THEN
            RAISE EXCEPTION 'Παραβίαση Ιεραρχίας: Ο επόπτης ενός Επιμελητής Β πρέπει να είναι τουλάχιστον Επιμελητής Α.';
            
        ELSIF NEW.rank = 'Επιμελητής Α' AND v_supervisor_rank != 'Διευθυντής' THEN
            RAISE EXCEPTION 'Παραβίαση Ιεραρχίας: Ο επόπτης ενός Επιμελητής Α πρέπει να είναι υποχρεωτικά Διευθυντής.';
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


CREATE TRIGGER trg_check_doctor_supervisor
BEFORE INSERT OR UPDATE ON doctors
FOR EACH ROW
EXECUTE FUNCTION validate_supervisor_trigger_fn();


CREATE OR REPLACE FUNCTION prevent_allergic_prescription()
RETURNS TRIGGER AS $$
DECLARE
    v_patient_allergy TEXT;
BEGIN
    -- 1. Βρίσκουμε τη μοναδική αλλεργία του ασθενή
    SELECT allergies INTO v_patient_allergy
    FROM patients
    WHERE patient_id = NEW.patient_id;

    -- 2. Αν ο ασθενής έχει αλλεργία, κάνουμε τον έλεγχο
    IF v_patient_allergy IS NOT NULL THEN
        -- Ψάχνουμε αν το φάρμακο έχει την ουσία (ΑΓΝΟΩΝΤΑΣ ΠΕΖΑ/ΚΕΦΑΛΑΙΑ)
        IF EXISTS (
            SELECT 1 
            FROM medicine_substances 
            WHERE drug_id = NEW.drug_id 
              -- Η ΜΑΓΕΙΑ ΕΙΝΑΙ ΣΕ ΑΥΤΗ ΤΗ ΓΡΑΜΜΗ:
              AND LOWER(active_substance) = LOWER(v_patient_allergy)
        ) THEN
            RAISE EXCEPTION 'ΑΠΑΓΟΡΕΥΣΗ: Ο ασθενής (ID: %) έχει αλλεργία στη δραστική ουσία "%" αυτού του φαρμάκου!', NEW.patient_id, v_patient_allergy;
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER check_allergy_before_prescription
BEFORE INSERT OR UPDATE ON prescription
FOR EACH ROW
EXECUTE FUNCTION prevent_allergic_prescription();



CREATE OR REPLACE FUNCTION check_room_capacity()
RETURNS TRIGGER AS $$
DECLARE
    current_patients INT;
    max_capacity INT;
BEGIN
    
    SELECT COUNT(*) INTO current_patients 
    FROM admission 
    WHERE room_id = NEW.room_id AND discharge_date IS NULL;

    
    SELECT capacity INTO max_capacity 
    FROM rooms 
    WHERE room_id = NEW.room_id;


    IF current_patients >= max_capacity THEN
        RAISE EXCEPTION 'Ο θάλαμος με ID % είναι πλήρης! (Χωρητικότητα: %)', NEW.room_id, max_capacity;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_check_capacity
BEFORE INSERT ON admission
FOR EACH ROW
EXECUTE FUNCTION check_room_capacity();




CREATE OR REPLACE FUNCTION update_ward_status()
RETURNS TRIGGER AS $$
BEGIN

    UPDATE rooms 
    SET room_status = CASE 
        WHEN (SELECT COUNT(*) FROM admission WHERE room_id = NEW.room_id AND discharge_date IS NULL) >= capacity 
        THEN 'Κατειλημμέν0'
        ELSE 'Διαθέσιμο'
    END
    WHERE room_id = NEW.room_id;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_ward_status
AFTER INSERT OR UPDATE OF discharge_date ON admission
FOR EACH ROW
EXECUTE FUNCTION update_ward_status();




CREATE OR REPLACE FUNCTION check_individual_shift_constraints()
RETURNS TRIGGER AS $$
DECLARE
    v_type VARCHAR;
    v_date DATE;
    v_shift_type type_shift_types;
    v_count_month INTEGER;
    v_consecutive_nights INTEGER;
BEGIN

    SELECT personnel_type INTO v_type 
    FROM personnel 
    WHERE personnel_id = NEW.personnel_id;

    SELECT shift_date, shift_type INTO v_date, v_shift_type 
    FROM shift 
    WHERE shift_id = NEW.shift_id;

  IF EXISTS (
        SELECT 1 
        FROM personnel_shifts pe
        JOIN shift e ON pe.shift_id = e.shift_id
        WHERE pe.personnel_id = NEW.personnel_id
          AND e.shift_date = v_date 
          AND e.shift_type = v_shift_type
    ) THEN
        RAISE EXCEPTION 'Σύγκρουση Βαρδιών: Ο υπάλληλος είναι ήδη δηλωμένος σε άλλη βάρδια την ίδια ακριβώς μέρα και ώρα!';
    END IF;

    -- --- ΚΑΝΟΝΑΣ 1: Μηνιαία Όρια ---
    SELECT COUNT(*) INTO v_count_month
    FROM personnel_shifts pe
    JOIN shift e ON pe.shift_id = e.shift_id
    WHERE pe.personnel_id = NEW.personnel_id
      AND EXTRACT(MONTH FROM e.shift_date) = EXTRACT(MONTH FROM v_date)
      AND EXTRACT(YEAR FROM e.shift_date) = EXTRACT(YEAR FROM v_date);

    IF (v_type = 'Ιατρός' AND v_count_month >= 15) THEN
        RAISE EXCEPTION 'Ο ιατρός έχει συμπληρώσει το όριο (15) για αυτόν το μήνα.';
    ELSIF (v_type = 'Νοσηλευτής' AND v_count_month >= 20) THEN
        RAISE EXCEPTION 'Ο νοσηλευτής έχει συμπληρώσει το όριο (20) για αυτόν το μήνα.';
    ELSIF (v_type = 'Διοικητικό Προσωπικό' AND v_count_month >= 25) THEN
        RAISE EXCEPTION 'Ο διοικητικός υπάλληλος έχει συμπληρώσει το όριο (25).';
    END IF;

    IF EXISTS (
        SELECT 1 FROM personnel_shifts pe
        JOIN shift e ON pe.shift_id = e.shift_id
        WHERE pe.personnel_id = NEW.personnel_id
          AND (
            (e.shift_date = v_date AND v_shift_type = 'ΑΠΟΓΕΥΜΑ' AND e.shift_type = 'ΠΡΩΙ') OR
            (e.shift_date = v_date AND v_shift_type = 'ΠΡΩΙ' AND e.shift_type = 'ΑΠΟΓΕΥΜΑ') OR
            (e.shift_date = v_date AND v_shift_type = 'ΝΥΧΤΑ' AND e.shift_type = 'ΑΠΟΓΕΥΜΑ') OR
            (e.shift_date = v_date AND v_shift_type = 'ΑΠΟΓΕΥΜΑ' AND e.shift_type = 'ΝΥΧΤΑ') OR
            (e.shift_date = v_date - 1 AND v_shift_type = 'ΠΡΩΙ' AND e.shift_type = 'ΝΥΧΤΑ') OR
            (e.shift_date = v_date + 1 AND v_shift_type = 'ΝΥΧΤΑ' AND e.shift_type = 'ΠΡΩΙ')
          )
    ) THEN
        RAISE EXCEPTION 'Παραβίαση 8ωρης ανάπαυσης! Ο υπάλληλος δουλεύει σε διαδοχική βάρδια.';
    END IF;

    IF v_shift_type = 'ΝΥΧΤΑ' THEN
        SELECT COUNT(*) INTO v_consecutive_nights
        FROM shift e
        JOIN personnel_shifts pe ON e.shift_id = pe.shift_id
        WHERE pe.personnel_id = NEW.personnel_id 
          AND e.shift_type = 'ΝΥΧΤΑ'
          AND e.shift_date IN (v_date - 1, v_date - 2);

        IF v_consecutive_nights >= 2 THEN
            RAISE EXCEPTION 'Απαγορεύεται η 3η συνεχόμενη νυχτερινή βάρδια.';
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_check_individual_constraints
BEFORE INSERT ON personnel_shifts
FOR EACH ROW
EXECUTE FUNCTION check_individual_shift_constraints();




CREATE OR REPLACE FUNCTION check_shift_validity()
RETURNS TRIGGER AS $$
DECLARE
    count_doctors INTEGER;
    count_nurses INTEGER;
    count_admins INTEGER;
    has_apprentice BOOLEAN;
    has_supervisor BOOLEAN;
BEGIN

    IF (NEW.shift_status = 'COMPLETED' AND OLD.shift_status = 'DRAFT') THEN
        
        SELECT 
            COUNT(*) FILTER (WHERE p.personnel_type = 'Ιατρός'),
            COUNT(*) FILTER (WHERE p.personnel_type = 'Νοσηλευτής'),
            COUNT(*) FILTER (WHERE p.personnel_type = 'Διοικητικό Προσωπικό') 

        INTO count_doctors, count_nurses, count_admins
        FROM personnel_shifts pe
        JOIN personnel p ON pe.personnel_id = p.personnel_id
        WHERE pe.shift_id = NEW.shift_id;

        IF COALESCE(count_doctors, 0) < 3 OR COALESCE(count_nurses, 0) < 6 OR COALESCE(count_admins, 0) < 2 THEN
            RAISE EXCEPTION 'Ανεπαρκές προσωπικό: Απαιτούνται 3 ιατροί, 6 νοσηλευτές και 2 διοικητικοί.';
        END IF;

        SELECT 
            EXISTS(SELECT 1 FROM personnel_shifts pe 
                   JOIN doctors i ON pe.personnel_id = i.doctor_id 
                   WHERE pe.shift_id = NEW.shift_id AND i.rank = 'Ειδικευόμενος'),
            EXISTS(SELECT 1 FROM personnel_shifts pe 
                   JOIN doctors i ON pe.personnel_id = i.doctor_id 
                   WHERE pe.shift_id = NEW.shift_id AND i.rank IN ('Επιμελητής Α', 'Διευθυντής'))
        INTO has_apprentice, has_supervisor;

        IF has_apprentice AND NOT has_supervisor THEN
            RAISE EXCEPTION 'Βρέθηκε Ειδικευόμενος ιατρός χωρίς την παρουσία Επιμελητή Α ή Διευθυντή.';
        END IF;

    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Δημιουργία του Trigger
CREATE TRIGGER trigger_validate_shift
BEFORE UPDATE ON shift
FOR EACH ROW
EXECUTE FUNCTION check_shift_validity();

ALTER TABLE prescription
ADD CONSTRAINT unique_prescription_combo 
UNIQUE (doctor_id, patient_id, drug_id, start_date);

ALTER TABLE shift
ADD CONSTRAINT unique_edpartment_date_shift
UNIQUE (department_id, shift_date, shift_type);