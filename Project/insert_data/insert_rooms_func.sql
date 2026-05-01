CREATE OR REPLACE FUNCTION generate_random_rooms()
RETURNS void AS $$
DECLARE
    dept RECORD;
    i INTEGER;
    rand_status_num INTEGER;
    rand_type_idx INTEGER;
    selected_status VARCHAR(50);
    selected_type VARCHAR(50);
    
    normal_room_types VARCHAR[] := ARRAY['Μονόκλινο', 'Δίκλινο', 'Τρίκλινο', 'Τετράκλινο', 'Θάλαμος 6 κλινών'];
BEGIN
    
    FOR dept IN SELECT department_id, number_of_rooms, department_description FROM departments LOOP
        
        IF dept.number_of_rooms IS NOT NULL AND dept.number_of_rooms > 0 THEN
            
            FOR i IN 1..dept.number_of_rooms LOOP
                
                rand_status_num := floor(random() * 100 + 1)::int;
                IF rand_status_num <= 95 THEN
                    selected_status := 'Διαθέσιμο';
                ELSE
                    selected_status := 'Υπό συντήρηση';
                END IF;

                IF dept.department_description LIKE '%ΜΕΘ%' THEN
                
                    selected_type := 'ΜΕΘ';
                    
                ELSIF dept.department_description IN ('Χειρουργικό', 'Ορθοπεδικό', 'Μαιευτικό-Γυναικολογικό', 'Οφθαλμολογικό', 'ΩΡΛ', 'Ουρολογικό') 
                      AND random() <= 0.5 THEN
                    
                    selected_type := 'Χειρουργείο';
                    
                ELSE
                    
                    rand_type_idx := floor(random() * array_length(normal_room_types, 1) + 1)::int;
                    selected_type := normal_room_types[rand_type_idx];
                END IF;

                
                INSERT INTO rooms (room_type, room_status, department_id)
                VALUES (selected_type, selected_status, dept.department_id);
                
            END LOOP;
        END IF;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

SELECT generate_random_rooms();

UPDATE rooms
SET capacity = CASE 
    WHEN room_type = 'Μονόκλινο' THEN 1
    WHEN room_type = 'Δίκλινο' THEN 2
    WHEN room_type = 'Τρίκλινο' THEN 3
    WHEN room_type = 'Τετράκλινο' THEN 4
    WHEN room_type = 'Θάλαμος 6 κλινών' THEN 6
    WHEN room_type = 'ΜΕΘ' THEN 1 
    ELSE 1 
END;