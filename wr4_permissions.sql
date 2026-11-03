
-- PRO2003 Work Requirement 4
-- Configure application permissions for the Flask database.
--
-- Run as a PostgreSQL administrator in:
-- pro2003_ai_evaluation_restored
--
-- Prerequisites:
-- 1. The database and its four tables already exist.
-- 2. Role pro2003_app exists (NOLOGIN).
-- 3. User pro2003_flask exists (LOGIN).
-- 4. Set the login user's password privately in pgAdmin.
--
-- This script contains no passwords.

-- Allow connections to the WR4 development database.
GRANT CONNECT
ON DATABASE pro2003_ai_evaluation_restored
TO pro2003_app;

-- Allow access to the public schema.
GRANT USAGE
ON SCHEMA public
TO pro2003_app;

-- Allow CRUD operations on existing tables.
GRANT SELECT, INSERT, UPDATE, DELETE
ON ALL TABLES IN SCHEMA public
TO pro2003_app;

-- Allow generated IDs when inserting records.
GRANT USAGE, SELECT
ON ALL SEQUENCES IN SCHEMA public
TO pro2003_app;

-- Give Flask inherited application permissions,
-- without role switching or membership administration.
GRANT pro2003_app
TO pro2003_flask
WITH INHERIT TRUE, SET FALSE, ADMIN FALSE;
