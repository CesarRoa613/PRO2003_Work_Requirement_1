# PRO2003 Work Requirement 1
## AI Model Evaluation Database

### Domain

This project contains a small PostgreSQL database for evaluating AI models.

The database is designed to keep track of AI features, test cases, AI models, and evaluation runs. A feature can have several test cases, and each test case can be evaluated using different AI models.

### Database Design

The database contains four related tables:

- `features` – stores the AI features that are being tested.
- `test_cases` – stores individual test cases connected to a feature.
- `models` – stores the AI models used during evaluation.
- `evaluation_runs` – stores the result of running a model against a test case.

### Relationships

There is a one-to-many relationship between `features` and `test_cases`.

One feature can have many test cases, while each test case belongs to one feature.

There is also a many-to-many relationship between `test_cases` and `models`.

This relationship is resolved through the intermediate table `evaluation_runs`. Each evaluation run connects one test case with one model and stores the result of that evaluation.

### Keys and Constraints

Each table has a primary key.

Foreign keys are used to connect the tables:

- `test_cases.feature_id` references `features.feature_id`
- `evaluation_runs.test_case_id` references `test_cases.test_case_id`
- `evaluation_runs.model_id` references `models.model_id`

Required values use `NOT NULL`.

The `result` column in `evaluation_runs` uses a `CHECK` constraint so that only `pass` or `fail` can be stored.

### Files

- `schema.sql` contains the PostgreSQL DDL statements used to create the database.
- `er_model.png` contains the ER model using Crow's Foot relationships.
---

# PRO2003 Work Requirement 2

## Administer PostgreSQL Database

For Work Requirement 2, the database from Work Requirement 1 was populated with realistic test data and used to practice modifying, retrieving, combining, and analyzing relational data with SQL.

The work was completed using PostgreSQL 18 and pgAdmin 4.

## Test Data

The database was populated with data for:

- 4 AI features
- 8 test cases
- 4 AI models
- 16 evaluation runs

The test data contains different features, models, test cases, and both `pass` and `fail` evaluation results.

The file `populate_data.sql` contains the SQL statements used to populate the database.

## Data Modification

The file `modify_data.sql` demonstrates:

- `UPDATE`
- `DELETE FROM`

Before modifying or deleting data, the relevant rows were checked using `SELECT` statements.

## Queries

The file `queries.sql` contains eight documented `SELECT` queries.

The queries demonstrate:

- retrieving related data from multiple tables
- `JOIN ... ON`
- `LEFT JOIN`
- aggregate functions such as `COUNT`
- `COUNT(DISTINCT ...)`
- `GROUP BY`
- `HAVING`
- filtering with `WHERE`
- a subquery using `IN`

Each query includes SQL comments describing its purpose.

## Query Result Examples

### Query 1 – Joining related tables

This query combines evaluation runs with their related feature, test case, and AI model.

![Query 1 - JOIN](screenshots/query_01_join.png)

### Query 3 – GROUP BY and HAVING

This query counts passing evaluations for each model and uses `HAVING` to return models with at least three passing evaluations.

![Query 3 - GROUP BY and HAVING](screenshots/query_03_group_by_having.png)

### Query 4 – Subquery

This query uses a subquery to find AI models that have at least one failed evaluation.

![Query 4 - Subquery](screenshots/query_04_subquery.png)

### Query 8 – COUNT DISTINCT

This query counts how many different AI models have been evaluated for each feature.

![Query 8 - COUNT DISTINCT](screenshots/query_08_count_distinct.png)

## Files

- `schema.sql` – creates the database tables and constraints
- `populate_data.sql` – inserts realistic test data
- `modify_data.sql` – demonstrates updating and deleting data
- `queries.sql` – contains eight documented SELECT queries
- `er_model.png` – ER model from Work Requirement 1
- `screenshots/` – screenshots showing selected query results
# PRO2003 Work Requirement 3

## Improve and Protect Your PostgreSQL Database

### 1. Database Normalization – Third Normal Form (3NF)

The existing AI Model Evaluation Database was reviewed to determine whether its structure follows Third Normal Form (3NF).

The database contains four related tables: `features`, `test_cases`, `models`, and `evaluation_runs`.

**First Normal Form (1NF):** Each table has a primary key, and the columns store individual values rather than repeating groups.

**Second Normal Form (2NF):** All four tables use single-column primary keys. Non-key attributes therefore do not have partial dependencies on these primary keys.

**Third Normal Form (3NF):** Based on the intended relationships and functional dependencies, the non-key attributes describe their respective entities without problematic transitive dependencies.

- `features` stores information about individual AI features.
- `test_cases` stores test cases and references their associated features through a foreign key.
- `models` stores AI model information.
- `evaluation_runs` connects test cases and models while storing the outcome of each evaluation.

Separating these entities reduces unnecessary data duplication and helps maintain data consistency.

**Conclusion:** Based on the current database design and its intended functional dependencies, the database satisfies 3NF. No structural changes are necessary at this stage.
### 2. Indexing and Query Performance

An index was created on `evaluation_runs.model_id` to evaluate whether it could improve queries filtering evaluation runs by AI model.

The query was evaluated using `EXPLAIN (ANALYZE, BUFFERS)` before and after creating the index.

**Index:**

```sql
CREATE INDEX IF NOT EXISTS idx_evaluation_runs_model_id
ON evaluation_runs (model_id);
```

**Query Plan Comparison**

| Measurement | Before Index | After Index |
|---|---|---|
| Scan Method | Seq Scan | Seq Scan |
| Rows Returned | 4 | 4 |
| Rows Removed by Filter | 12 | 12 |
| Planning Time | 7.861 ms | 3.181 ms |
| Execution Time | 2.574 ms | 0.168 ms |
| Index Used | No | No |

**Evaluation:**

PostgreSQL used a sequential scan both before and after the index was created.

The `evaluation_runs` table contains only 16 rows, so scanning the entire table may be more efficient than using an index.

Although execution time was lower in the second measurement, the query plan did not use the new index. The difference may have been influenced by caching and disk access rather than the index itself.

**Conclusion:** The index was successfully created and evaluated, but no performance improvement attributable to the index was demonstrated. It may become more useful as the database grows.

The SQL script is available in `index.sql`.

**Before Index:**

![Query plan before index](screenshots/wr3_index_before.png)

**After Index:**

![Query plan after index](screenshots/wr3_index_after.png)

### 3. Transactions

A PostgreSQL transaction was implemented to demonstrate how multiple related database changes can be performed as one atomic operation.

**Scenario:**

The expected result for the `Generate SQL query` test case was updated together with the evaluation notes for the `Gemini 2.5 Pro` model.

Both changes belong to the same evaluation review and should be saved together.

**Implementation:**

The transaction is defined in `transaction.sql` and contains:

- `BEGIN` to start the transaction.
- Two `UPDATE` statements modifying related records.
- `COMMIT` to save both changes.

If an error occurs before the transaction is committed, the transaction can be rolled back to prevent partial changes.

**Verification:**

The transaction executed successfully in pgAdmin.

A follow-up SELECT query confirmed that both `expected_result` and `notes` contained their updated values.

**Conclusion:**

The transaction demonstrated atomic execution of multiple related SQL statements while maintaining consistency between the test case and its evaluation.

**Transaction verification screenshot:**

![Transaction verification](screenshots/wr3_transaction.png)

### 4. Database Roles and Permissions

A restricted PostgreSQL role named `pro2003_app` was created to demonstrate database access control and the principle of least privilege.

**Purpose:**

The role provides permissions for application-level CRUD operations without granting database administrator privileges.

**Implementation:**

The SQL script `roles_permissions.sql` creates the role using `NOLOGIN` and grants the following permissions:

- `CONNECT` on the project database.
- `USAGE` on the `public` schema.
- `SELECT`, `INSERT`, `UPDATE`, and `DELETE` on existing tables.
- `USAGE` and `SELECT` on existing sequences to support inserts using SERIAL columns.

The role cannot log in directly and does not have superuser privileges or permission to create tables in the `public` schema.

**Verification:**

PostgreSQL privilege functions were used to verify the role's permissions.

The results confirmed:

- Login permission: false
- Superuser: false
- CREATE permission on the public schema: false
- SELECT, INSERT, UPDATE, DELETE: true

A practical test was also performed using `SET LOCAL ROLE pro2003_app` inside a transaction.

The test confirmed that the role could read all 16 records from `evaluation_runs` and did not have CREATE permission on the public schema.

The test ended with `ROLLBACK`, restoring the original role without modifying database data.

**Conclusion:**

The restricted role was successfully created and verified. It provides the permissions needed for application-level data operations while limiting administrative access.

**Permissions verification screenshot:**

![Role permissions verification](screenshots/wr3_role_permissions.png)

### 5. Database Backup and Restore

A full backup of the PostgreSQL database was created and successfully restored into a separate database using pgAdmin 4.

**Purpose:**

The goal was to demonstrate how a PostgreSQL database can be backed up and recovered without overwriting the original database.

**Backup Procedure:**

1. Open pgAdmin 4 and connect to PostgreSQL 18.
2. Right-click the original database `pro2003_ai_evaluation`.
3. Select `Backup`.
4. Choose `Custom` as the backup format.
5. Save the backup as `pro2003_ai_evaluation_wr3.backup`.
6. Keep the remaining options at their default values and run the backup.

Result: `Successfully completed`.

**Restore Procedure:**

1. Create a new empty database named `pro2003_ai_evaluation_restored`, owned by `postgres`.
2. Right-click the new database and select `Restore`.
3. Select the previously created Custom-format backup file.
4. Keep the default restore settings without enabling `Clean before restore`.
5. Run the restore operation.

Result: `Successfully completed`.

**Verification:**

The following SQL query was executed against the restored database:

```sql
SELECT
    current_database() AS database_name,
    (SELECT COUNT(*) FROM public.features) AS features,
    (SELECT COUNT(*) FROM public.test_cases) AS test_cases,
    (SELECT COUNT(*) FROM public.models) AS models,
    (SELECT COUNT(*) FROM public.evaluation_runs) AS evaluation_runs;
```

The restored database returned:

| Table | Restored Rows |
|---|---:|
| features | 4 |
| test_cases | 8 |
| models | 4 |
| evaluation_runs | 16 |

All four tables were present and contained the expected number of records.

**Conclusion:**

The backup and restore procedures completed successfully. The restored database was verified separately, while the original database was preserved.

The backup file is stored locally and is not included in the GitHub repository.

**Restore verification screenshot:**

![Restore verification](screenshots/wr3_restore_verification.png)

---

# PRO2003 Work Requirement 4

## Integrate PostgreSQL with a Python Flask Application

### Overview

This work requirement extends the AI Model Evaluation Database
with a Python Flask REST API connected to PostgreSQL.

The application supports four CRUD operations:

- Create an evaluation using HTTP POST.
- Read evaluations using HTTP GET.
- Update an evaluation using HTTP PATCH.
- Delete an evaluation using HTTP DELETE.

The GET endpoint combines data from four related tables:
`evaluation_runs`, `test_cases`, `features`, and `models`.

### Technology and Data Access

- Python 3.14
- Flask
- Psycopg 3
- PostgreSQL 18
- python-dotenv

The application uses Psycopg 3 with direct SQL instead of an ORM.

This approach was chosen because the project already contains
a relational PostgreSQL schema and documented SQL queries.
It demonstrates SQL, JOIN operations, and parameterized queries
directly without introducing unnecessary complexity.

### Application Files

- `app.py` – Flask application, API routes, and error handling.
- `db.py` – PostgreSQL connection using environment variables.
- `requirements.txt` – Python dependencies.
- `.env.example` – Example database configuration without secrets.
- `wr4_permissions.sql` – Application database permissions.

The actual `.env` file is excluded from Git.

### Local Setup

Prerequisites:

- Python installed.
- PostgreSQL installed and running.
- A PostgreSQL database with the four project tables.
- A database login with the required application permissions.

For a fresh database, create `pro2003_ai_evaluation_restored`
in pgAdmin, then execute `schema.sql` followed by
`populate_data.sql` against that database.

The expected initial dataset contains:

- 4 features
- 8 test cases
- 4 models
- 16 evaluation runs


### PostgreSQL Role Setup

On a fresh PostgreSQL installation, connect as a
PostgreSQL administrator in pgAdmin 4.

Open the Query Tool for `pro2003_ai_evaluation_restored`.

Create the two application roles:

```sql
CREATE ROLE pro2003_app NOLOGIN;
CREATE ROLE pro2003_flask LOGIN;
```

Run these statements only once, when the roles do not
already exist.

In pgAdmin, open Login/Group Roles and select
Properties for `pro2003_flask`.

Under Definition, set a strong, private password.

Confirm that `pro2003_flask`:

- Can log in.
- Is not a superuser.
- Cannot create databases.
- Cannot create roles.

Next, execute `wr4_permissions.sql` as a PostgreSQL
administrator while connected to
`pro2003_ai_evaluation_restored`.

The script grants the required permissions and assigns
`pro2003_app` to `pro2003_flask` with:

- INHERIT TRUE
- SET FALSE
- ADMIN FALSE

The separate `roles_permissions.sql` file belongs
to WR3 and targets the original project database.
It is not required for this fresh WR4 setup.

Never store the Flask user's password in SQL files
or Git. Configure it only in PostgreSQL and the
local `.env` file.


### Python Setup

Open a terminal in the project directory.

Create a virtual environment:

```powershell
py -m venv .venv
```

Activate the environment in PowerShell:

```powershell
.\.venv\Scripts\Activate.ps1
```

Install dependencies:

```powershell
python -m pip install -r requirements.txt
```

Create the local environment configuration:

```powershell
Copy-Item .env.example .env
```

Edit `.env` with the correct local PostgreSQL settings and
the password for `pro2003_flask`.

Start the Flask development server:

```powershell
python -m flask --app app run --debug
```

The local API is available at:

`http://127.0.0.1:5000/`

The Flask development server is intended for local testing,
not production deployment.

### API Endpoints

The Flask API provides the following endpoints:

| Method | Endpoint | Description |
|---|---|---|
| GET | `/` | Check that the Flask application is running |
| GET | `/api/evaluations` | Retrieve evaluations with related data |
| POST | `/api/evaluations` | Create a new evaluation |
| PATCH | `/api/evaluations/<evaluation_id>` | Update an existing evaluation |
| DELETE | `/api/evaluations/<evaluation_id>` | Delete an evaluation |

#### GET /api/evaluations

Returns evaluation data joined from four PostgreSQL tables:

- `evaluation_runs`
- `test_cases`
- `features`
- `models`

Successful response: `200 OK`.

The JSON response contains a `count` and an `evaluations`
array with evaluation IDs, feature names, test case names,
model names, providers, results, and notes.

Database failures return `500 Internal Server Error`.

#### POST /api/evaluations

Creates a new evaluation.

Example JSON request:

```json
{
  "test_case_id": 1,
  "model_id": 3,
  "result": "fail",
  "notes": "Example evaluation"
}
```

Required fields:

- `test_case_id`: positive integer referencing an existing test case.
- `model_id`: positive integer referencing an existing model.
- `result`: either `pass` or `fail`.

The `notes` field is optional and accepts a string or null.

Responses:

- `201 Created`: evaluation inserted successfully.
- `400 Bad Request`: invalid JSON, invalid field values, or
  a missing referenced test case or model.
- `500 Internal Server Error`: database operation failed.

SQL parameters are used instead of inserting client values
directly into SQL strings.

#### PATCH /api/evaluations/<evaluation_id>

Updates an existing evaluation.

Only `result` and `notes` can be modified through this endpoint.

Example request:

```json
{
  "result": "pass",
  "notes": "Evaluation reviewed and updated"
}
```

The client may provide one or both fields.

Responses:

- `200 OK`: evaluation updated successfully.
- `400 Bad Request`: invalid JSON or unsupported field.
- `404 Not Found`: evaluation ID does not exist.
- `500 Internal Server Error`: database operation failed.

#### DELETE /api/evaluations/<evaluation_id>

Deletes one evaluation identified by its ID.

Responses:

- `200 OK`: evaluation deleted successfully.
- `404 Not Found`: evaluation ID does not exist.
- `500 Internal Server Error`: database operation failed.

On success, the API returns the deleted evaluation
and a confirmation message.

### Testing and Verification

The Flask API was tested locally against the restored
PostgreSQL database `pro2003_ai_evaluation_restored`.

Testing included HTTP requests, Flask's built-in test client,
and independent SQL verification using pgAdmin 4.

#### Positive Tests

| Test | Expected Result | Actual Result |
|---|---|---|
| GET `/` | 200 and application JSON | Passed |
| GET `/api/evaluations` | 200 and 16 evaluations | Passed |
| SQL JOIN | Related data from four tables | Passed |
| POST `/api/evaluations` | 201 and new record | Passed |
| PATCH `/api/evaluations/17` | 200 and updated record | Passed |
| DELETE `/api/evaluations/17` | 200 and deleted record | Passed |

A temporary evaluation with ID 17 was created using POST,
updated from `fail` to `pass` using PATCH, and then removed
using DELETE.

Each database modification was verified independently in
pgAdmin using SQL SELECT statements.

#### Negative Tests

| Test | Expected HTTP Status | Result |
|---|---|---|
| POST with invalid result value | 400 | Passed |
| POST with non-existing test case ID | 400 | Passed |
| PATCH with non-existing evaluation ID | 404 | Passed |
| PATCH attempting to change model_id | 400 | Passed |
| DELETE with non-existing evaluation ID | 404 | Passed |

The tests confirmed that input validation, foreign key
constraints, allowed-field validation, and missing-record
handling produce the expected responses.

#### Database Integrity Verification

After the CRUD and negative tests, a final SQL check
confirmed:

- Total evaluations: 16
- Records with evaluation_run_id = 17: 0
- Records with test_case_id = 999999: 0

The temporary test record was removed, and the original
16 evaluation records remained in the development database.

#### Security Measures

- Database credentials are read from environment variables.
- The local `.env` file is excluded from Git.
- The Flask login uses inherited, restricted database permissions.
- SQL parameters are used for client-supplied values.
- Input validation rejects unsupported or invalid values.
- Database errors return JSON without exposing SQL error details
  to API clients.


The original WR4 checks were performed manually using local
development tools and Flask's test client.

An additional automated pytest integration-test suite is now
included in the `tests/` directory.

The suite currently contains 30 test cases covering CRUD,
JOIN relationships, input validation, HTTP error responses,
transaction rollback, and database safety checks.

The automated tests use a separate PostgreSQL test database,
a restricted database role, and transaction-based isolation.

For complete setup instructions, required database permissions,
test data, and execution commands, see:

[Automated Test Setup and Execution](tests/README.md)
