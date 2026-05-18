import random
from faker import Faker

# Αρχικοποίηση Faker
fake = Faker('el_GR')

TOTAL_DOCTORS = 600

# ΑΛΑΝΘΑΣΤΟ MAPPING: Αντιστοίχιση με τα ΑΚΡΙΒΗ κείμενα της βάσης σου
SPECIALTY_MAPPING = {
    'Παθολόγος': ['Παθολογικό', 'ΜΕΘ (Εντατική)', 'ΤΕΠ (Επείγοντα)'],
    'Καρδιολόγος': ['Καρδιολογικό', 'ΜΕΘ (Εντατική)', 'ΤΕΠ (Επείγοντα)'],
    'Χειρουργός': ['Χειρουργικό', 'ΜΕΘ (Εντατική)', 'ΤΕΠ (Επείγοντα)'],
    'Ορθοπεδικός': ['Ορθοπεδικό', 'ΤΕΠ (Επείγοντα)'],
    'Παιδίατρος': ['Παιδιατρικό', 'ΤΕΠ (Επείγοντα)'],
    'Γυναικολόγος': ['Μαιευτικό-Γυναικολογικό'],
    'Οφθαλμίατρος': ['Οφθαλμολογικό'],
    'Ωτορινολαρυγγολόγος (ΩΡΛ)': ['ΩΡΛ'],
    'Νευρολόγος': ['Νευρολογικό'],
    'Ψυχίατρος': ['Ψυχιατρικό'],
    'Δερματολόγος': ['Δερματολογικό'],
    'Ουρολόγος': ['Ουρολογικό', 'Χειρουργικό'],
    'Ογκολόγος': ['Ογκολογικό'],
    'Πνευμονολόγος': ['Πνευμονολογικό', 'ΜΕΘ (Εντατική)'],
    'Αναισθησιολόγος': ['Χειρουργικό', 'ΜΕΘ (Εντατική)', 'ΤΕΠ (Επείγοντα)'],
    'Αιματολόγος': ['Αιματολογικό']
}

SPECIALTIES = list(SPECIALTY_MAPPING.keys())

hierarchy = [
    ('Διευθυντής', int(TOTAL_DOCTORS * 0.15)),
    ('Επιμελητής Α', int(TOTAL_DOCTORS * 0.30)),
    ('Επιμελητής Β', int(TOTAL_DOCTORS * 0.25)),
    ('Ειδικευόμενος', int(TOTAL_DOCTORS * 0.30))
]

sql_statements = []
sql_statements.append("-- ==========================================")
sql_statements.append(f"-- AUTO-GENERATED SQL INSERTS ΓΙΑ {TOTAL_DOCTORS} ΙΑΤΡΟΥΣ")
sql_statements.append("-- ΜΕ ΑΛΑΝΘΑΣΤΗ ΑΝΤΙΣΤΟΙΧΙΣΗ ΜΕΣΩ first_nameTOΣ (VARCHAR)")
sql_statements.append("-- ==========================================\n")
sql_statements.append("BEGIN;\n")

for vathmida, count in hierarchy:
    for _ in range(count):
        amka = fake.unique.numerify(text='###########')
        first_name = fake.first_name()
        last_name = fake.last_name()
        age = random.randint(28, 65)
        email = fake.unique.ascii_company_email()
        phone_number = fake.numerify(text='69########')
        hire_date = fake.date_between(start_date='-10y', end_date='today').strftime('%Y-%m-%d')
        
        # Επιλογή Ειδικότητας
        rank = random.choice(SPECIALTIES)
        license_number = fake.unique.numerify(text='ΑΔ-#####')
        association_number = fake.unique.numerify(text='ΙΣ-#####')
        
        # Ανάθεση στα σωστά τμήματα (Ονόματα, όχι IDs)
        allowed_departments = SPECIALTY_MAPPING[rank]
        max_depts = min(3, len(allowed_departments))
        num_departments = random.randint(1, max_depts)
        
        assigned_departments = random.sample(allowed_departments, num_departments)
        
        # Φορμάρισμα λίστας κειμένων για PostgreSQL (π.χ. ARRAY['Χειρουργικό', 'ΜΕΘ (Εντατική)'])
        array_elements = ", ".join(f"'{dept}'" for dept in assigned_departments)
        sql_array_format = f"ARRAY[{array_elements}]"
        
        sql = (
            f"SELECT insert_doctor("
            f"'{amka}', '{first_name}', '{last_name}', {age}, "
            f"'{email}', '{phone_number}', '{hire_date}', "
            f"'{rank}', '{vathmida}', "
            f"'{license_number}', '{association_number}', "
            f"{sql_array_format}::VARCHAR[]"
            f");"
        )
        sql_statements.append(sql)

sql_statements.append("\nCOMMIT;")

with open("insert_doctor_names_data.sql", "w", encoding="utf-8") as f:
    for stmt in sql_statements:
        f.write(stmt + "\n")

print("Επιτυχής δημιουργία! Τα δεδομένα αποθηκεύτηκαν στο αρχείο 'insert_doctor_data.sql'.")