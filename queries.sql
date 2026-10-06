-- PRO2003 Work Requirement 2
-- Documented SELECT queries for retrieving and analyzing
-- data from the AI Model Evaluation Database.


-- Query 1:
-- Show all evaluation runs together with their related feature,
-- test case, model, result, and notes.
SELECT
    er.evaluation_run_id,
    f.name AS feature,
    tc.name AS test_case,
    m.name AS model,
    er.result,
    er.notes
FROM evaluation_runs AS er
JOIN test_cases AS tc
    ON er.test_case_id = tc.test_case_id
JOIN features AS f
    ON tc.feature_id = f.feature_id
JOIN models AS m
    ON er.model_id = m.model_id
ORDER BY er.evaluation_run_id;


-- Query 2:
-- Count how many pass and fail results each AI model has.
SELECT
    m.name AS model,
    er.result,
    COUNT(*) AS result_count
FROM evaluation_runs AS er
JOIN models AS m
    ON er.model_id = m.model_id
GROUP BY m.name, er.result
ORDER BY m.name, er.result;


-- Query 3:
-- Show models that have at least three passing evaluations.
-- HAVING filters the grouped results after COUNT has been calculated.
SELECT
    m.name AS model,
    COUNT(*) AS pass_count
FROM evaluation_runs AS er
JOIN models AS m
    ON er.model_id = m.model_id
WHERE er.result = 'pass'
GROUP BY m.name
HAVING COUNT(*) >= 3
ORDER BY pass_count DESC;


-- Query 4:
-- Show the AI models that have at least one failed evaluation.
-- The inner SELECT is a subquery that finds model IDs with failed results.
SELECT
    name,
    provider
FROM models
WHERE model_id IN (
    SELECT model_id
    FROM evaluation_runs
    WHERE result = 'fail'
)
ORDER BY name;


-- Query 5:
-- Show the details of all failed evaluations.
SELECT
    tc.name AS test_case,
    m.name AS model,
    er.result,
    er.notes
FROM evaluation_runs AS er
JOIN test_cases AS tc
    ON er.test_case_id = tc.test_case_id
JOIN models AS m
    ON er.model_id = m.model_id
WHERE er.result = 'fail'
ORDER BY tc.name, m.name;


-- Query 6:
-- Count how many test cases belong to each feature.
-- LEFT JOIN also keeps a feature in the result if it has no test cases.
SELECT
    f.name AS feature,
    COUNT(tc.test_case_id) AS test_case_count
FROM features AS f
LEFT JOIN test_cases AS tc
    ON f.feature_id = tc.feature_id
GROUP BY f.feature_id, f.name
ORDER BY f.name;


-- Query 7:
-- Count how many passing evaluation runs each feature has.
SELECT
    f.name AS feature,
    COUNT(*) AS passed_evaluations
FROM evaluation_runs AS er
JOIN test_cases AS tc
    ON er.test_case_id = tc.test_case_id
JOIN features AS f
    ON tc.feature_id = f.feature_id
WHERE er.result = 'pass'
GROUP BY f.feature_id, f.name
ORDER BY passed_evaluations DESC, f.name;


-- Query 8:
-- Show how many different AI models have been evaluated
-- for each feature.
SELECT
    f.name AS feature,
    COUNT(DISTINCT m.model_id) AS models_tested
FROM features AS f
JOIN test_cases AS tc
    ON f.feature_id = tc.feature_id
JOIN evaluation_runs AS er
    ON tc.test_case_id = er.test_case_id
JOIN models AS m
    ON er.model_id = m.model_id
GROUP BY f.feature_id, f.name
ORDER BY f.name;