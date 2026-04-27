CREATE TABLE personnel (
    personnel_id SERIAL PRIMARY KEY,
    personnel_type VARCHAR(50) NOT NULL,
    amka CHAR(11) NOT NULL UNIQUE,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    age INT,
    email VARCHAR(100),
    phone_number VARCHAR(20),
    hire_date DATE
);

CREATE TABLE doctors (
    doctor_id INT PRIMARY KEY,
    license_number VARCHAR(30) NOT NULL UNIQUE,
    association_number VARCHAR(30) NOT NULL UNIQUE,
    specialty VARCHAR(100) NOT NULL,
    rank VARCHAR(50),
    CONSTRAINT fk_doctors_personnel
        FOREIGN KEY (doctor_id)
        REFERENCES personnel(personnel_id)
);

ALTER TABLE doctors ADD COLUMN supervisor_id INT NULL;

ALTER TABLE doctors 
ADD CONSTRAINT fk_supervisor
FOREIGN KEY (supervisor_id)
REFERENCES doctors(doctor_id);

CREATE TABLE nurses (
    nurse_id INT PRIMARY KEY,
    rank VARCHAR(50),
    CONSTRAINT fk_nurses_personnel
        FOREIGN KEY (nurse_id)
        REFERENCES personnel(personnel_id)
);

CREATE TABLE administrative_personnel (
    admin_id INT PRIMARY KEY,
    duty VARCHAR(100) NOT NULL,
    office VARCHAR(100),
    CONSTRAINT fk_administrative_personnel_personnel
        FOREIGN KEY (admin_id)
        REFERENCES personnel(personnel_id)
);

CREATE TABLE departments (
    department_id SERIAL PRIMARY KEY,
    department_description VARCHAR(150) NOT NULL,
    number_of_beds INT NOT NULL,
    floor INT,
    building VARCHAR(100),
    director INT,
    CONSTRAINT fk_departments_director
        FOREIGN KEY (director)
        REFERENCES doctors(doctor_id)
);

ALTER TABLE nurses
ADD COLUMN department_id INT;

ALTER TABLE nurses
ADD CONSTRAINT fk_nurses_departments
FOREIGN KEY (department_id)
REFERENCES departments(department_id);

ALTER TABLE administrative_personnel
ADD COLUMN department_id INT;

ALTER TABLE administrative_personnel
ADD CONSTRAINT fk_administrative_personnel_departments
FOREIGN KEY (department_id)
REFERENCES departments(department_id);

CREATE TABLE doctor_department (
    doctor_id INT,
    department_id INT,
    CONSTRAINT pk_doctor_department
        PRIMARY KEY (doctor_id, department_id),
    CONSTRAINT fk_doctor_department_doctors
        FOREIGN KEY (doctor_id)
        REFERENCES doctors(doctor_id),
    CONSTRAINT fk_doctor_department_departments
        FOREIGN KEY (department_id)
        REFERENCES departments(department_id)
);

CREATE TABLE beds (
    bed_id SERIAL PRIMARY KEY,
    bed_type VARCHAR(50) NOT NULL,
    bed_status VARCHAR(50) NOT NULL,
    department_id INT,
    CONSTRAINT fk_beds_departments
        FOREIGN KEY (department_id)
        REFERENCES departments(department_id)
);

CREATE TABLE shift (
    shift_id SERIAL PRIMARY KEY,
    department_id INT NOT NULL,
    shift_date DATE NOT NULL,
    shift_type VARCHAR(50) NOT NULL,
    CONSTRAINT fk_shift_departments
        FOREIGN KEY (department_id)
        REFERENCES departments(department_id)
);

CREATE TYPE type_shift_types AS ENUM ('ΠΡΩΙ', 'ΑΠΟΓΕΥΜΑ', 'ΝΥΧΤΑ');

ALTER TABLE shift 
ALTER COLUMN shift_type TYPE type_shift_types 
USING shift_type::type_shift_types;

ALTER TABLE shift 
ADD COLUMN shift_status VARCHAR(20) DEFAULT 'DRAFT' NOT NULL;

CREATE TABLE personnel_shifts (
    shift_id INT,
    personnel_id INT,
    CONSTRAINT pk_personnel_shifts
        PRIMARY KEY (shift_id, personnel_id),
    CONSTRAINT fk_personnel_shifts_shift
        FOREIGN KEY (shift_id)
        REFERENCES shift(shift_id),
    CONSTRAINT fk_personnel_shifts_personnel
        FOREIGN KEY (personnel_id)
        REFERENCES personnel(personnel_id)
);

CREATE TABLE patients (
    patient_id SERIAL PRIMARY KEY,
    patronym VARCHAR(100),
    amka CHAR(11) NOT NULL UNIQUE,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    age INT,
    sex VARCHAR(20),
    weight NUMERIC(5,2),
    phone_number VARCHAR(20),
    height NUMERIC(5,2),
    address VARCHAR(200),
    email VARCHAR(100),
    profession VARCHAR(100),
    nationality VARCHAR(100),
    contact_person VARCHAR(100),
    insurance_provider VARCHAR(100),
    allergies TEXT
);

CREATE TABLE diagnosis (
    icd_id TEXT NOT NULL PRIMARY KEY,
    icd_description TEXT NOT NULL
);

CREATE TABLE medicine (
    drug_id SERIAL PRIMARY KEY,
    drug_name TEXT NOT NULL,
    active_substance TEXT NOT NULL,
    CONSTRAINT unique_farmako_ousia UNIQUE (drug_name, active_substance)
);

CREATE TABLE ken (
    ken_id SERIAL PRIMARY KEY,
    cost NUMERIC(10,2) NOT NULL,
    mdn VARCHAR(50) NOT NULL,
    ken_description TEXT NOT NULL
);

CREATE TABLE admission (
    admission_id SERIAL PRIMARY KEY,
    patient_id INT NOT NULL,
    department_id INT NOT NULL,
    admission_date DATE NOT NULL,
    discharge_date DATE,
    admission_diagnosis TEXT,
    discharge_diagnosis TEXT,
    ken_id INT,
    lab_exams TEXT,
    medical_act TEXT,
    medication TEXT,
    admission_evaluation TEXT,
    bed_id INT,
    CONSTRAINT fk_admission_patients
        FOREIGN KEY (patient_id)
        REFERENCES patients(patient_id),
    CONSTRAINT fk_admission_departments
        FOREIGN KEY (department_id)
        REFERENCES departments(department_id),
    CONSTRAINT fk_admission_diagnwsh_eisagwghs
        FOREIGN KEY (admission_diagnosis)
        REFERENCES diagnosis(icd_id),
    CONSTRAINT fk_admission_diagnwsh_eksodou
        FOREIGN KEY (discharge_diagnosis)
        REFERENCES diagnosis(icd_id),
    CONSTRAINT fk_admission_ken
        FOREIGN KEY (ken_id)
        REFERENCES ken(ken_id),
    CONSTRAINT fk_admission_beds
        FOREIGN KEY (bed_id)
        REFERENCES beds(bed_id)
);

CREATE TABLE admission_evaluation (
    aksiologhsh_id SERIAL PRIMARY KEY,
    admission_id INT NOT NULL UNIQUE,
    medical_care INT,
    nursing_care INT,
    hygiene INT,
    food INT,
    overall_experience INT,
    CONSTRAINT fk_aksiologhsh_admissions_admission
        FOREIGN KEY (admission_id)
        REFERENCES admission(admission_id)
);

CREATE TABLE prescription (
    prescription_id SERIAL PRIMARY KEY,
    doctor_id INT NOT NULL,
    patient_id INT NOT NULL,
    drug_id INT NOT NULL,
    admission_id INT,
    dose VARCHAR(100) NOT NULL,
    frequency VARCHAR(100) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE,
    CONSTRAINT fk_suntagografhsh_doctors
        FOREIGN KEY (doctor_id)
        REFERENCES doctors(doctor_id),
    CONSTRAINT fk_suntagografhsh_patients
        FOREIGN KEY (patient_id)
        REFERENCES patients(patient_id),
    CONSTRAINT fk_suntagografhsh_medic
        FOREIGN KEY (drug_id)
        REFERENCES medicine(drug_id),
    CONSTRAINT fk_suntagografhsh_admission
        FOREIGN KEY (admission_id)
        REFERENCES admission(admission_id)
);

CREATE TABLE lab_exams (
    lab_exam_id SERIAL PRIMARY KEY,
    admission_id INT NOT NULL,
    lab_exam_type VARCHAR(100) NOT NULL,
    lab_exam_date DATE NOT NULL,
    lab_exam_result TEXT,
    lab_exam_cost INT,
    doctor_id INT,
    CONSTRAINT fk_ergastiriakes_eksetaseis_admission
        FOREIGN KEY (admission_id)
        REFERENCES admission(admission_id),
    CONSTRAINT fk_ergastiriakes_eksetaseis_doctors
        FOREIGN KEY (doctor_id)
        REFERENCES doctors(doctor_id)
);

CREATE TABLE emergency_case (
    case_id SERIAL PRIMARY KEY,
    patient_id INT NOT NULL,
    admission_id INT,
    triage INT NOT NULL,
    symptoms TEXT,
    emergency_level VARCHAR(50),
    outcome TEXT,
    CONSTRAINT fk_peristatiko_epeigontwn_patients
        FOREIGN KEY (patient_id)
        REFERENCES patients(patient_id),
    CONSTRAINT fk_peristatiko_epeigontwn_admission
        FOREIGN KEY (admission_id)
        REFERENCES admission(admission_id),
    CONSTRAINT fk_peristatiko_epeigontwn_nurses
        FOREIGN KEY (triage)
        REFERENCES nurses(nurse_id)
);

CREATE TABLE medical_acts (
    medical_act_id SERIAL PRIMARY KEY,
    medical_act_name VARCHAR(100) NOT NULL,
    medical_act_category VARCHAR(100),
    duration INT,
    medical_act_cost NUMERIC(10,2),
    location VARCHAR(100),
    surgeon_id INT,
    admission_id INT,
    CONSTRAINT fk_medical_act_doctors
        FOREIGN KEY (surgeon_id)
        REFERENCES doctors(doctor_id),
    CONSTRAINT fk_medical_act_admission
        FOREIGN KEY (admission_id)
        REFERENCES admission(admission_id)
);

CREATE TABLE medical_act_assistants (
    medical_act_id INT,
    personnel_id INT,
    CONSTRAINT pk_voithoi_praksis
        PRIMARY KEY (medical_act_id, personnel_id),
    CONSTRAINT fk_voithoi_praksis_medical_act
        FOREIGN KEY (medical_act_id)
        REFERENCES medical_acts(medical_act_id),
    CONSTRAINT fk_voithoi_praksis_personnel
        FOREIGN KEY (personnel_id)
        REFERENCES personnel(personnel_id)
);
