import random
from datetime import datetime, timedelta

# --- ΒΑΣΙΚΕΣ ΡΥΘΜΙΣΕΙΣ (ΣΥΝΟΛΟ ~3500) ---
TOTAL_PATIENTS = 400
TARGET_ADMISSIONS = 1000 
TARGET_DISCHARGES = 2500 
OUTPUT_FILE = "insert_emergency_cases.sql"

# Subquery για έγκυρο νοσηλευτή του ΤΕΠ
NURSE_SQL = "(SELECT nurse_id FROM nurses WHERE department_id = 16 ORDER BY RANDOM() LIMIT 1)"

print(f"Στόχος: ~{TARGET_ADMISSIONS + TARGET_DISCHARGES} περιστατικά. Κατανομή ανά ασθενή...")

# 1. Φτιάχνουμε τη "δεξαμενή" με όλες τις εκβάσεις
all_outcomes = ['Νοσηλεία'] * TARGET_ADMISSIONS + ['Αποχώρηση'] * TARGET_DISCHARGES
random.shuffle(all_outcomes)

# 2. Αρχικοποιούμε το ιστορικό κάθε ασθενή
patient_timelines = {i: [] for i in range(1, TOTAL_PATIENTS + 1)}

# Προ-ρυθμίζουμε τους ασθενείς για τα Queries 3 & 9 
patient_timelines[10] = ['Νοσηλεία'] * 5  
patient_timelines[20] = ['Νοσηλεία'] * 1  
patient_timelines[21] = ['Νοσηλεία'] * 2  

for _ in range(8):
    if 'Νοσηλεία' in all_outcomes:
        all_outcomes.remove('Νοσηλεία')

# Μοιράζουμε τις υπόλοιπες εκβάσεις τυχαία στους υπόλοιπους ασθενείς
for outcome in all_outcomes:
    patient_id = random.choice([p for p in range(1, TOTAL_PATIENTS + 1) if p not in (10, 20, 21)])
    patient_timelines[patient_id].append(outcome)

# Συνάρτηση για απόλυτα τυχαία ημερομηνία σε ένα εύρος
def random_date(start, end):
    delta = end - start
    return start + timedelta(seconds=random.randint(0, int(delta.total_seconds())))

print("Υπολογισμός χρονολογικών αφίξεων (Ομοιόμορφη Κατανομή 2025 - 2026)...")

# Το εύρος της διετίας (Αφήνουμε λίγο χώρο στο τέλος μήπως χρειαστεί να "σπρώξουμε" ημερομηνίες)
START_PERIOD = datetime(2025, 1, 1)
END_PERIOD = datetime(2026, 11, 20) 

cases = []

# 3. Φτιάχνουμε το χρονολόγιο για κάθε ασθενή
for patient_id, outcomes in patient_timelines.items():
    if not outcomes:
        continue
        
    # Διαλέγουμε N τυχαίες ημερομηνίες απλωμένες σε ΟΛΗ τη διετία
    raw_dates = [random_date(START_PERIOD, END_PERIOD) for _ in range(len(outcomes))]
    raw_dates.sort() # Τις βάζουμε σε χρονολογική σειρά
    
    last_arrival = None
    last_outcome = None
    
    for i, outcome in enumerate(outcomes):
        proposed_arrival = raw_dates[i]
        
        # Εφαρμογή του κανόνα ασφαλείας
        if last_arrival is not None:
            if last_outcome == 'Νοσηλεία':
                # Αν η προηγούμενη ήταν νοσηλεία, απαιτούμε 40-50 μέρες κενό
                min_allowed_date = last_arrival + timedelta(days=random.randint(40, 50))
            else:
                # Αν ήταν απλή αποχώρηση, αρκούν 3-15 μέρες κενό
                min_allowed_date = last_arrival + timedelta(days=random.randint(3, 15))
                
            # Αν η τυχαία ημερομηνία έπεσε πολύ νωρίς, τη "σπρώχνουμε" μπροστά
            if proposed_arrival < min_allowed_date:
                proposed_arrival = min_allowed_date
        
        # Αν με τα "σπρωξίματα" βγήκαμε εκτός 2026, σταματάμε να γράφουμε γι' αυτόν τον ασθενή
        if proposed_arrival > datetime(2026, 12, 31, 23, 59):
            break
            
        last_arrival = proposed_arrival
        last_outcome = outcome
        
        if outcome == 'Νοσηλεία':
            level = random.randint(1, 3)
            symptoms = 'Σοβαρή αδιαθεσία / Πόνος'
        else:
            level = random.choices([3, 4, 5], weights=[20, 50, 30])[0]
            symptoms = 'Ελαφρύς τραυματισμός / Οδηγίες'
            
        cases.append({
            'patient_id': patient_id,
            'level': level,
            'outcome': outcome,
            'symptoms': symptoms,
            'arrival': proposed_arrival
        })

# 4. Ταξινομούμε ΟΛΑ τα περιστατικά χρονολογικά (για τη Stored Procedure)
cases.sort(key=lambda x: x['arrival'])

# 5. Δημιουργία των INSERT statements
sql_inserts = []
for case in cases:
    # ΠΡΟΣΟΧΗ: handled_time = NULL, admission_id = NULL
    sql_inserts.append(f"({case['patient_id']}, NULL, {NURSE_SQL}, '{case['symptoms']}', '{case['level']}', '{case['outcome']}', '{case['arrival'].strftime('%Y-%m-%d %H:%M:%S')}', NULL)")

# --- ΕΞΑΓΩΓΗ SQL ---
with open(OUTPUT_FILE, "w", encoding="utf-8") as file:
    file.write("-- Εισαγωγή Περιστατικών στα Επείγοντα (Ομοιόμορφη Κατανομή 2025-2026)\n")
    file.write("INSERT INTO emergency_case (patient_id, admission_id, triage, symptoms, emergency_level, outcome, arrival_time, handled_time) VALUES\n")
    file.write(",\n".join(sql_inserts) + ";\n")

print(f"Επιτυχία! Δημιουργήθηκαν {len(cases)} περιστατικά στο '{OUTPUT_FILE}'.")