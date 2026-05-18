# Ygeiopolis General Hospital
## Database semester project, for "Databases" course of the ECE NTUA school

Welcome to the Ygeiopolis General Hospital database. This project aims to implement a realistic database for a hospital, including the various entities that comprise it. It efficiently stores and manages critical hospital data, including core entities such as personnel (categorized into doctors, nurses, and administrative staff), patients and hospital departments with their respective rooms. Furthermore, it tracks clinical and operational workflows, including patient admissions, medical acts, laboratory exams, shifts, prescriptions, and patient evaluations.

All the essential files required to initialize, configure, and execute the Hospital Database are contained within this repository.

## Directory Features

- **Database Management**: Built with PostgreSQL to ensure powerful and reliable data storage.
- **Database Administration** Managed and queried using DBeaver and Neon.tech as the primary SQL client.
- **Generating Data**: Features Python scripts designed to generate realistic dummy data for testing and database population.
- **Triggers and Procedures**: Includes custom triggers to ensure data constraints are maintained, as well as functions and procedures that properly populate the database.

## Database Features

- **Personnel Management**: Stores and categorizes hospital staff into doctors, nurses, and administrative personnel, tracking roles, specialties, ranks, and organizational hierarchies (supervisors).
- **Patient Records**: Maintains comprehensive patient profiles, including demographic information, physical attributes, contact details, emergency contacts, insurance providers, and allergy history.
- **Admission Tracking**: Manages the complete lifecycle of inpatient stays, logging admission and discharge dates, room/bed assignments, financial costs, and admission/discharge diagnosis. 
- **Clinical Workflows & Interventions**: Tracks medical acts performed during admissions, including duration, costs, responsible surgeons, and supporting assistant personnel. 
- **Laboratory Exams & Diagnostics**: Records laboratory examinations ordered for patients, linking them to specific clinical cases, tracking dates, categories, results, and supervising doctors. 
- **Emergency Case Processing**: Handles emergency room inflows using triage and FIFO logic, logging arrival times, symptom descriptions, emergency severity levels, and clinical outcomes.
- **Shift Scheduling**: Manages the hospital's daily staffing needs by scheduling personnel across various shift types (morning, afternoon, night) and departments.
- **Quality of Care Evaluations**: Stores  patient feedback regarding medical care, nursing staff, hygiene, food quality, and overall experience, alongside direct doctor evaluations.

## Assumptions

1. Every hospital admission originates from the Emergency Room.
2. The generated data covers a 2-year period of hospital operations, specifically from 2025 to 2026.
3. Complete staffing shifts are only populated and scheduled for the duration of May 2026.
4. Diagnoses, medical acts, and lab exams are randomly selected for each admission and have no medical basis.


## Technical Details

### Technologies Used:

- **PostgreSQL**: PostgreSQL was used as the primary relational database management system for setting up, storing, and managing the hospital database.
- **DBeaver**: DBeaver was utilized as the database administration tool and SQL client to interact with the database.
- **Neon.tech**: Neon was used as our cloud-based serverless PostgreSQL platform to host the database, enabling all team members to work and collaborate remotely on a shared environment.
- **Python**: Python was used for writing data generation scripts to create realistic dummy data and populate the database.

### Tech Stack: 

- **PostgreSQL**: 17.8
- **DBeaver**: 26.0.3
- **Python**: 3.12.1

## Installation & Setup

To set up and initialize the hospital database locally, please follow the steps below:

1. **Prepare the data files**:

   Ensure that the following CSV files are located in the **same directory/folder** as your SQL scripts. These files are required to populate the database lookup tables:
   * `drugs.csv`
   * `ken.csv`
   * `medical_acts.csv`
   * `lab_exams.csv`
   * `icd.csv`

2. **Create the schema**:

   Execute the `install.sql` script in your PostgreSQL environment (via DBeaver or your terminal) to create the database, tables, types, and constraints:
   ```bash
   psql -u [username] -d [database_name] < install.sql

3. **Load the data**:
    ```bash
    psql -u [username] -d [database_name] < load.sql
