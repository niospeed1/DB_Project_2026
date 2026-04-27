import random
from faker import Faker

# Αρχικοποίηση του Faker με Ελληνικά δεδομένα
fake = Faker('el_GR')

# --- Ρυθμίσεις Παραμέτρων ---
TOTAL_NURSES = 650
VATHMIDES = ['Βοηθός Νοσηλευτή', 'Νοσηλευτής', 'Προϊστάμενος']
# Βάρη πιθανοτήτων: 30% Βοηθοί, 60% Νοσηλευτές, 10% Προϊστάμενοι
WEIGHTS = [30, 60, 10] 

sql_statements = []

sql_statements.append("-- ==========================================")
sql_statements.append(f"-- AUTO-GENERATED SQL ΓΙΑ {TOTAL_NURSES} ΝΟΣΗΛΕΥΤΕΣ")
sql_statements.append("-- ==========================================\n")

# Χρησιμοποιούμε Transaction για να εκτελεστούν ταχύτατα
sql_statements.append("BEGIN;\n")

for _ in range(TOTAL_NURSES):
    # Δημιουργία Γενικών Στοιχείων με fake.unique για αποφυγή διπλοτύπων
    amka = fake.unique.numerify(text='###########')
    first_name = fake.first_name()
    last_name = fake.last_name()
    age = random.randint(22, 60)
    email = fake.unique.ascii_company_email()
    phone_number = fake.numerify(text='69########')
    
    # Ημερομηνία σε σωστό format για την PostgreSQL (YYYY-MM-DD)
    hire_date = fake.date_between(start_date='-15y', end_date='today').strftime('%Y-%m-%d')
    
    # Τυχαία επιλογή βαθμίδας βάσει των ποσοστών που ορίσαμε
    rank = random.choices(VATHMIDES, weights=WEIGHTS, k=1)[0]
    
    # Δημιουργία της κλήσης της συνάρτησης! 
    # Προσοχή: Τα strings μπαίνουν σε μονά εισαγωγικά (' ')
    sql = (
        f"SELECT insert_nurse("
        f"'{amka}', '{first_name}', '{last_name}', {age}, "
        f"'{email}', '{phone_number}', '{hire_date}', '{rank}'"
        f");"
    )
    
    sql_statements.append(sql)

# Κλείσιμο του Transaction
sql_statements.append("\nCOMMIT;")

# Εξαγωγή του SQL κώδικα στο αρχείο
with open("insert_nurses_data.sql", "w", encoding="utf-8") as f:
    for stmt in sql_statements:
        f.write(stmt + "\n")

print(f"Επιτυχής δημιουργία! Τα δεδομένα αποθηκεύτηκαν στο αρχείο 'insert_nurses_data.sql'.")