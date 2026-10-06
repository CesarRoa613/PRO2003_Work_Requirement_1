-- PRO2003 Work Requirement 2
-- Demonstrate safe modification and deletion of data.

-- Check the row before updating it.
SELECT test_case_id, name, expected_result
FROM test_cases
WHERE name = 'Generate SQL query';

-- Update one specific test case with a more precise expected result.
UPDATE test_cases
SET expected_result = 'A valid SQL query that returns the requested data without syntax errors.'
WHERE name = 'Generate SQL query';

-- Verify that the update was applied correctly.
SELECT test_case_id, name, expected_result
FROM test_cases
WHERE name = 'Generate SQL query';


-- Add a temporary row so DELETE FROM can be demonstrated safely.
INSERT INTO features (name, description)
VALUES (
    'Temporary Test Feature',
    'Temporary data used to demonstrate DELETE FROM.'
);

-- Check which row will be deleted.
SELECT feature_id, name, description
FROM features
WHERE name = 'Temporary Test Feature';

-- Delete only the intended temporary row.
DELETE FROM features
WHERE name = 'Temporary Test Feature';

-- Verify that the row has been deleted.
SELECT feature_id, name, description
FROM features
WHERE name = 'Temporary Test Feature';