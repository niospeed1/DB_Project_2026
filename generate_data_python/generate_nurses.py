import random
from faker import Faker

# Αρχικοποίηση του Faker με Ελληνικά δεδομένα
fake = Faker('el_GR')

# --- Ρυθμίσεις Παραμέτρων ---
TOTAL_NURSES = 600
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
    onoma = fake.first_name()
    eponimo = fake.last_name()
    hlikia = random.randint(22, 60)
    email = fake.unique.ascii_company_email()
    thlefono = fake.numerify(text='69########')
    
    # Ημερομηνία σε σωστό format για την PostgreSQL (YYYY-MM-DD)
    proslhpsh = fake.date_between(start_date='-15y', end_date='today').strftime('%Y-%m-%d')
    
    # Τυχαία επιλογή βαθμίδας βάσει των ποσοστών που ορίσαμε
    vathmida = random.choices(VATHMIDES, weights=WEIGHTS, k=1)[0]
    
    # Δημιουργία της κλήσης της συνάρτησης! 
    # Προσοχή: Τα strings μπαίνουν σε μονά εισαγωγικά (' ')
    sql = (
        f"SELECT insert_noshleuths("
        f"'{amka}', '{onoma}', '{eponimo}', {hlikia}, "
        f"'{email}', '{thlefono}', '{proslhpsh}', '{vathmida}'"
        f");"
    )
    
    sql_statements.append(sql)

# Κλείσιμο του Transaction
sql_statements.append("\nCOMMIT;")

# Εξαγωγή του SQL κώδικα στο αρχείο
with open("insert_noshleutes_data.sql", "w", encoding="utf-8") as f:
    for stmt in sql_statements:
        f.write(stmt + "\n")

print(f"Επιτυχής δημιουργία! Τα δεδομένα αποθηκεύτηκαν στο αρχείο 'insert_noshleutes_data.sql'.")