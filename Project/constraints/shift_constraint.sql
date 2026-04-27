ALTER TABLE shift
ADD CONSTRAINT unique_edpartment_date_shift
UNIQUE (department_id, shift_date, shift_type);