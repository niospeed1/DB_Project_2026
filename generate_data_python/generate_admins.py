import random
from faker import Faker

# Αρχικοποίηση του Faker με Ελληνικά δεδομένα
fake = Faker('el_GR')

# --- Ρυθμίσεις Παραμέτρων ---
TOTAL_ADMINS = 200  # Μπορείς να το αλλάξεις ανάλογα με το πόσους χρειάζεσαι

# 2 βασικά + 5 επιπλέον καθήκοντα
KATHIKONTA = [
    'Γραμματέας', 
    'Λογιστής', 
    'Υπάλληλος Προμηθειών', 
    'Υπάλληλος Μισθοδοσίας', 
    'Υπεύθυνος Αρχείου', 
    'Ταμίας', 
    'Υπάλληλος IT/Μηχανογράφησης'
]

sql_statements = []

sql_statements.append("-- ==========================================")
sql_statements.append(f"-- AUTO-GENERATED SQL ΓΙΑ {TOTAL_ADMINS} ΔΙΟΙΚΗΤΙΚΟΥΣ ΥΠΑΛΛΗΛΟΥΣ")
sql_statements.append("-- ==========================================\n")

# Χρησιμοποιούμε Transaction για ταχύτατη εισαγωγή
sql_statements.append("BEGIN;\n")

for _ in range(TOTAL_ADMINS):
    # 1. Δημιουργία Γενικών Στοιχείων (με fake.unique για αποφυγή διπλοτύπων)
    amka = fake.unique.numerify(text='###########')
    onoma = fake.first_name()
    eponimo = fake.last_name()
    hlikia = random.randint(24, 65)
    email = fake.unique.ascii_company_email()
    thlefono = fake.numerify(text='69########')
    proslhpsh = fake.date_between(start_date='-20y', end_date='today').strftime('%Y-%m-%d')
    
    # 2. Τυχαία επιλογή Καθήκοντος
    kathikon = random.choice(KATHIKONTA)
    
    # 3. Δημιουργία Αριθμού Γραφείου σύμφωνα με τους κανόνες
    # 1ο ψηφίο: 1 έως 3
    # 2ο ψηφίο: 1 έως 5
    # 3ο και 4ο ψηφίο: 00 έως 99 (χρησιμοποιούμε :02d για να βάζει μηδενικό μπροστά αν τύχει π.χ. το 5 -> 05)
    digit_1 = random.randint(1, 3)
    digit_2 = random.randint(1, 5)
    digits_3_4 = random.randint(0, 99)
    grafeio = f"{digit_1}{digit_2}{digits_3_4:02d}"
    
    # Δημιουργία της κλήσης της συνάρτησης insert_dioikitiko_prosopiko
    sql = (
        f"SELECT insert_dioikitiko_prosopiko("
        f"'{amka}', '{onoma}', '{eponimo}', {hlikia}, "
        f"'{email}', '{thlefono}', '{proslhpsh}', '{kathikon}', '{grafeio}'"
        f");"
    )
    
    sql_statements.append(sql)

# Κλείσιμο του Transaction
sql_statements.append("\nCOMMIT;")

# Εξαγωγή του SQL κώδικα στο αρχείο
with open("insert_dioikitiko_data.sql", "w", encoding="utf-8") as f:
    for stmt in sql_statements:
        f.write(stmt + "\n")

print(f"Επιτυχής δημιουργία! Τα δεδομένα αποθηκεύτηκαν στο αρχείο 'insert_dioikitiko_data.sql'.")