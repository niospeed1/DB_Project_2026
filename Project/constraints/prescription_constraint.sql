ALTER TABLE prescription
ADD CONSTRAINT unique_prescription_combo 
UNIQUE (doctor_id, patient_id, drug_id, start_date);