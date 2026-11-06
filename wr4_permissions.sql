-- PRO2003 Work Requirement 4
-- Least-privilege permissions for the Flask application.
--
-- Run as a PostgreSQL administrator in:
-- pro2003_ai_evaluation_restored
--
-- Prerequisites:
-- Roles pro2003_app and pro2003_flask already exist.
-- The four project tables have been created.
--
-- This script contains no passwords.

-- Database and schema access.
GRANT CONNECT
ON DATABASE pro2003_ai_evaluation_restored
TO pro2003_app;

GRANT USAGE
ON SCHEMA public
TO pro2003_app;

-- Remove previously granted table privileges.
-- This also makes the script safe to rerun after
-- the earlier broad WR4 grants.
REVOKE ALL PRIVILEGES
ON TABLE
    public.features,
    public.test_cases,
    public.models,
    public.evaluation_runs
FROM pro2003_app;

-- Reference tables: read-only access.
GRANT SELECT
ON TABLE
    public.features,
    public.test_cases,
    public.models
TO pro2003_app;

-- Evaluation records: the API needs full CRUD.
GRANT SELECT, INSERT, UPDATE, DELETE
ON TABLE public.evaluation_runs
TO pro2003_app;

-- Remove previous broad sequence privileges.
REVOKE ALL PRIVILEGES
ON ALL SEQUENCES IN SCHEMA public
FROM pro2003_app;

-- Allow nextval() when the API inserts evaluations.
GRANT USAGE
ON SEQUENCE public.evaluation_runs_evaluation_run_id_seq
TO pro2003_app;

-- Flask inherits the restricted permissions.
GRANT pro2003_app
TO pro2003_flask
WITH INHERIT TRUE, SET FALSE, ADMIN FALSE;
