
# PRO2003 WR4 – Automated Tests

## Purpose

Automated integration tests for the Flask API and PostgreSQL database.

The tests cover CRUD, validation, foreign-key constraints,
HTTP responses, transaction rollback and database safety checks.

## Requirements

- Python with a virtual environment
- PostgreSQL
- Project files: schema.sql and tests/seed.sql
- Test dependencies from requirements-test.txt

Install dependencies from the project root:

```powershell
python -m pip install -r requirements-test.txt
```

## Test database setup

Use a dedicated PostgreSQL database and a restricted login role.

- Database: `pro2003_wr4_pytest`
- Login role: `pro2003_pytest`
- Database owner: `postgres`

### 1. Create the test role

In pgAdmin, connect as a PostgreSQL administrator.

Under Login/Group Roles, create `pro2003_pytest`.

Configure the role with:

- Can login: Yes
- Superuser: No
- Create roles: No
- Create databases: No
- Inherit rights from parent roles: No

Set a unique password privately. Do not store it in Git.

If the role already exists, verify these settings instead
of creating a duplicate.

### 2. Create the test database

Under Databases in pgAdmin, create:

- Database: `pro2003_wr4_pytest`
- Owner: `postgres`

Use a new, empty database.

### 3. Create the database schema

Open Query Tool for `pro2003_wr4_pytest` as `postgres`.

Run the project-root file `schema.sql` once.

This creates the four tables and their constraints.

### 4. Insert the fixed test dataset

In the same database, run `tests/seed.sql` once.

Expected initial row counts:

| Table | Rows |
|---|---:|
| features | 4 |
| test_cases | 8 |
| models | 4 |
| evaluation_runs | 16 |

Do not run the seed script repeatedly against a
populated database. It is intended for a fresh database.

### 5. Apply database permissions

Run `tests/grants.sql` as `postgres`, while connected
to `pro2003_wr4_pytest`.

The script verifies the database and test role before
assigning permissions.

The test role receives:

- CONNECT on the test database
- USAGE on schema public
- SELECT on features, test_cases and models
- SELECT, INSERT, UPDATE, DELETE on evaluation_runs
- USAGE on evaluation_runs_evaluation_run_id_seq

The test role must not have CREATE access to schema public
or write access to the development database.

### 6. Verify the baseline

Run this query against the test database:

```sql
SELECT
    (SELECT COUNT(*) FROM features) AS features,
    (SELECT COUNT(*) FROM test_cases) AS test_cases,
    (SELECT COUNT(*) FROM models) AS models,
    (SELECT COUNT(*) FROM evaluation_runs) AS evaluation_runs;
```

Expected result: 4, 8, 4, 16.

The existing pytest fixtures additionally verify the
configured and actual PostgreSQL database and login role.


## Local test configuration

Create .env.test in the project root:

```dotenv
DB_HOST=127.0.0.1
DB_PORT=5432
DB_NAME=pro2003_wr4_pytest
DB_USER=pro2003_pytest
DB_PASSWORD=your_private_test_password
```

Use the actual PostgreSQL host and port for your installation.

Never commit .env.test or real passwords.

## Run tests

From the project root:

```powershell
python -m pytest -q tests/
```

The current suite contains 30 test cases.

## Isolation and safety

The test fixture checks the configured and actual
PostgreSQL database and login role.

Tests use an outer database transaction and SAVEPOINTs.
The outer transaction is rolled back after each test,
including when a test fails.

Tests assume the initial 16 evaluation records exist.

PostgreSQL sequences may advance despite transaction rollback.

Do not run the integration tests against a production database.

## Scope

This is a local, sequential integration-test suite.
It does not establish production readiness, concurrency
correctness or performance under load.
