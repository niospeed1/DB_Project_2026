import random
from faker import Faker

# Αρχικοποίηση Faker
fake = Faker('el_GR')

TOTAL_DOCTORS = 400


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
    ('Διευθυντής', int(TOTAL_DOCTORS * 0.10)),
    ('Επιμελητής Α', int(TOTAL_DOCTORS * 0.20)),
    ('Επιμελητής Β', int(TOTAL_DOCTORS * 0.30)),
    ('Ειδικευόμενος', int(TOTAL_DOCTORS * 0.40))
]

sql_statements = []
sql_statements.append("-- ==========================================")
sql_statements.append(f"-- AUTO-GENERATED SQL INSERTS ΓΙΑ {TOTAL_DOCTORS} ΙΑΤΡΟΥΣ")
sql_statements.append("-- ΜΕ ΑΛΑΝΘΑΣΤΗ ΑΝΤΙΣΤΟΙΧΙΣΗ ΜΕΣΩ ONOMATOΣ (VARCHAR)")
sql_statements.append("-- ==========================================\n")
sql_statements.append("BEGIN;\n")

for vathmida, count in hierarchy:
    for _ in range(count):
        amka = fake.unique.numerify(text='###########')
        onoma = fake.first_name()
        eponimo = fake.last_name()
        hlikia = random.randint(28, 65)
        email = fake.unique.ascii_company_email()
        thlefono = fake.numerify(text='69########')
        proslhpsh = fake.date_between(start_date='-10y', end_date='today').strftime('%Y-%m-%d')
        
        # Επιλογή Ειδικότητας
        eidikothta = random.choice(SPECIALTIES)
        arithmos_adeias = fake.unique.numerify(text='ΑΔ-#####')
        arithmos_sullogou = fake.unique.numerify(text='ΙΣ-#####')
        
        # Ανάθεση στα σωστά τμήματα (Ονόματα, όχι IDs)
        allowed_departments = SPECIALTY_MAPPING[eidikothta]
        max_depts = min(3, len(allowed_departments))
        num_departments = random.randint(1, max_depts)
        
        assigned_departments = random.sample(allowed_departments, num_departments)
        
        # Φορμάρισμα λίστας κειμένων για PostgreSQL (π.χ. ARRAY['Χειρουργικό', 'ΜΕΘ (Εντατική)'])
        array_elements = ", ".join(f"'{dept}'" for dept in assigned_departments)
        sql_array_format = f"ARRAY[{array_elements}]"
        
        sql = (
            f"SELECT insert_iatros("
            f"'{amka}', '{onoma}', '{eponimo}', {hlikia}, "
            f"'{email}', '{thlefono}', '{proslhpsh}', "
            f"'{eidikothta}', '{vathmida}', "
            f"'{arithmos_adeias}', '{arithmos_sullogou}', "
            f"{sql_array_format}::VARCHAR[]"
            f");"
        )
        sql_statements.append(sql)

sql_statements.append("\nCOMMIT;")

with open("insert_iatroi_names_data.sql", "w", encoding="utf-8") as f:
    for stmt in sql_statements:
        f.write(stmt + "\n")

print("Επιτυχής δημιουργία! Τα δεδομένα αποθηκεύτηκαν στο αρχείο 'insert_iatroi_names_data.sql'.")
