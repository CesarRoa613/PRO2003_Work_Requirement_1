-- PRO2003 Work Requirement 3
-- Index creation and query plan evaluation.
--
-- Purpose:
-- Evaluate whether an index on evaluation_runs.model_id
-- is useful when retrieving evaluations for a specific AI model.
--
-- BEFORE INDEX:
-- Scan method: Seq Scan
-- Rows returned: 4
-- Execution Time: 2.574 ms
--
-- AFTER INDEX:
-- Scan method: Seq Scan
-- Rows returned: 4
-- Execution Time: 0.168 ms
--
-- Conclusion:
-- PostgreSQL did not use the new index.
-- The table contains only 16 rows, so a sequential scan
-- may be more efficient.
-- The lower execution time does not prove that the index
-- improved performance. Caching can influence the results.
--
-- The original before/after results are documented
-- with screenshots in the README.

-- Create the index if it does not already exist.
CREATE INDEX IF NOT EXISTS idx_evaluation_runs_model_id
ON evaluation_runs (model_id);

-- Inspect the query plan with the index available.
EXPLAIN (ANALYZE, BUFFERS)
SELECT
    evaluation_run_id,
    test_case_id,
    result,
    notes
FROM evaluation_runs
WHERE model_id = (
    SELECT model_id
    FROM models
    WHERE name = 'GPT-5.6'
);