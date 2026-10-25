-- PRO2003 Work Requirement 3
-- Demonstrate a meaningful transaction with multiple SQL statements.
--
-- Scenario:
-- Review a SQL generation test case and its failed evaluation.
-- Both related changes should be saved together.

BEGIN;

-- Update the expected result for the SQL generation test case.
UPDATE test_cases
SET expected_result =
    'A valid SQL query that returns the requested data without syntax errors and uses the correct table relationships.'
WHERE name = 'Generate SQL query';

-- Update the evaluation notes for the Gemini model.
UPDATE evaluation_runs
SET notes =
    'The generated query did not return the requested data; reviewed against the updated expected result.'
WHERE test_case_id = (
    SELECT test_case_id
    FROM test_cases
    WHERE name = 'Generate SQL query'
)
AND model_id = (
    SELECT model_id
    FROM models
    WHERE name = 'Gemini 2.5 Pro'
)
AND result = 'fail';

-- Save both changes as one transaction.
COMMIT;