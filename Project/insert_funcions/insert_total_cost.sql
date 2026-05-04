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