import random
from faker import Faker

# Αρχικοποίηση του Faker με ελληνικά δεδομένα
fake = Faker('el_GR')

NUM_PATIENTS = 400
OUTPUT_FILE = 'insert_patients_data.sql'

# Δεδομένα από τον πίνακα: Ουσίες και τα αντίστοιχα "βάρη" τους (πιθανότητες)
ALLERGY_SUBSTANCES = [
    None,  # Αντιστοιχεί στο "NULL / No known drug allergy"
    "Amoxicillin", "Ampicillin", "Acetylsalicylic acid", "Ibuprofen",
    "Ceftriaxone", "Ciprofloxacin", "Naproxen", "Azithromycin",
    "Carbamazepine", "Lamotrigine", "Clindamycin", "Vancomycin",
    "Phenytoin", "Paracetamol", "Allopurinol"
]

ALLERGY_WEIGHTS = [
    8895, 300, 140, 110, 100,
    80, 70, 50, 40,
    35, 35, 35, 30,
    30, 25, 25
]

def escape_sql_string(value):
    """Βοηθητική συνάρτηση για να χειρίζεται τα NULL και να κάνει escape τα ' στα strings"""
    if value is None:
        return "NULL"
    safe_string = str(value).replace("'", "''")
    return f"'{safe_string}'"

def generate_mock_data():
    values_list = []
    
    for _ in range(NUM_PATIENTS):
        sex = random.choice(['Άρρεν', 'Θήλυ'])
        
        if sex == 'Άρρεν':
            first_name = fake.first_name_male()
            last_name = fake.last_name_male()
        else:
            first_name = fake.first_name_female()
            last_name = fake.last_name_female()

        patronym = fake.first_name_male()
        amka = fake.numerify(text='###########')
        age = random.randint(18, 95)
        weight = round(random.uniform(50.0, 130.0), 2)
        phone_number = fake.phone_number()
        height = round(random.uniform(150.0, 200.0), 2)
        
        address = fake.address().replace('\n', ', ') 
        email = fake.ascii_safe_email()
        profession = fake.job()
        
        nationality = random.choice(['Ελληνική'] * 8 + ['Κυπριακή', 'Αλβανική', 'Βρετανική'])
        contact_person = fake.name()
        insurance_provider = random.choice(['ΕΟΠΥΥ', 'ΕΦΚΑ', 'Ιδιωτική (Εθνική)', 'Ιδιωτική (Interamerican)', 'Ανασφάλιστος'])
        
        # Επιλογή αλλεργίας με βάση τα στατιστικά βάρη (k=1 σημαίνει ότι διαλέγουμε 1 στοιχείο)
        # Το random.choices επιστρέφει λίστα, οπότε παίρνουμε το [0] στοιχείο
        allergies = random.choices(ALLERGY_SUBSTANCES, weights=ALLERGY_WEIGHTS, k=1)[0]

        # Σύνθεση της γραμμής του SQL Value
        val = f"({escape_sql_string(patronym)}, {escape_sql_string(amka)}, {escape_sql_string(first_name)}, {escape_sql_string(last_name)}, {age}, {escape_sql_string(sex)}, {weight}, {escape_sql_string(phone_number)}, {height}, {escape_sql_string(address)}, {escape_sql_string(email)}, {escape_sql_string(profession)}, {escape_sql_string(nationality)}, {escape_sql_string(contact_person)}, {escape_sql_string(insurance_provider)}, {escape_sql_string(allergies)})"
        
        values_list.append(val)

    insert_header = """INSERT INTO patients (
    patronym, amka, first_name, last_name, age, sex, weight, phone_number, height, 
    address, email, profession, nationality, contact_person, insurance_provider, allergies
) VALUES\n"""
    
    final_sql = insert_header + ",\n".join(values_list) + ";"
    return final_sql

if __name__ == "__main__":
    sql_query = generate_mock_data()
    
    with open(OUTPUT_FILE, 'w', encoding='utf-8') as f:
        f.write(sql_query)
        
    print(f"Επιτυχία! Το αρχείο '{OUTPUT_FILE}' δημιουργήθηκε με τα ακριβή στατιστικά αλλεργιών.")