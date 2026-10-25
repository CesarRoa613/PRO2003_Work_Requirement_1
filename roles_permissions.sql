-- PRO2003 Work Requirement 3
-- Create a restricted application role.
--
-- Purpose:
-- Allow application-level CRUD operations without
-- granting administrative database privileges.
--
-- NOLOGIN means this role cannot log in directly.
-- A separate login user can be assigned this role in WR4.

CREATE ROLE pro2003_app NOLOGIN;

-- Allow the role to connect to the project database.
GRANT CONNECT ON DATABASE pro2003_ai_evaluation
TO pro2003_app;

-- Allow access to objects in the public schema.
GRANT USAGE ON SCHEMA public
TO pro2003_app;

-- Allow CRUD operations on existing tables.
GRANT SELECT, INSERT, UPDATE, DELETE
ON ALL TABLES IN SCHEMA public
TO pro2003_app;

-- Allow use of SERIAL sequences when inserting records.
GRANT USAGE, SELECT
ON ALL SEQUENCES IN SCHEMA public
TO pro2003_app;