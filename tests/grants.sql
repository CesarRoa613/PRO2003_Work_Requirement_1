
-- PRO2003 WR4 - Test database permissions
-- Run as PostgreSQL administrator.
-- Connect to pro2003_wr4_pytest before executing.
-- Requires the test role, schema and seed data to exist.
-- Safe to run repeatedly.

BEGIN;

-- Stop immediately if connected to the wrong database
-- or if the test role has unsafe administrative privileges.
DO $$
BEGIN
    IF current_database() <> 'pro2003_wr4_pytest' THEN
        RAISE EXCEPTION
            'Wrong database: expected pro2003_wr4_pytest';
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM pg_roles
        WHERE rolname = 'pro2003_pytest'
          AND rolcanlogin
          AND NOT rolsuper
          AND NOT rolcreatedb
          AND NOT rolcreaterole
          AND NOT rolinherit
    ) THEN
        RAISE EXCEPTION
            'Missing or unsafe pro2003_pytest role';
    END IF;
END
$$;

-- Reset direct privileges only on the known test tables.
REVOKE ALL PRIVILEGES
ON TABLE
    public.features,
    public.test_cases,
    public.models,
    public.evaluation_runs
FROM pro2003_pytest;

-- Reset direct privileges only on the evaluation sequence.
REVOKE ALL PRIVILEGES
ON SEQUENCE public.evaluation_runs_evaluation_run_id_seq
FROM pro2003_pytest;

-- Allow access to the dedicated test database.
GRANT CONNECT ON DATABASE pro2003_wr4_pytest
TO pro2003_pytest;

GRANT USAGE ON SCHEMA public
TO pro2003_pytest;

REVOKE CREATE ON SCHEMA public
FROM pro2003_pytest;

-- Reference tables: read-only.
GRANT SELECT
ON TABLE
    public.features,
    public.test_cases,
    public.models
TO pro2003_pytest;

-- Evaluation records: CRUD.
GRANT SELECT, INSERT, UPDATE, DELETE
ON TABLE public.evaluation_runs
TO pro2003_pytest;

-- Required for SERIAL-generated evaluation IDs.
GRANT USAGE
ON SEQUENCE public.evaluation_runs_evaluation_run_id_seq
TO pro2003_pytest;

COMMIT;
