
-- PRO2003 Work Requirement 3
-- Index creation and query plan evaluation.
--
-- Purpose:
-- Investigate whether an index on evaluation_runs.model_id
-- improves retrieval of evaluations for a specific AI model.
--
-- Reproduction requirements:
-- Run only in a fresh, isolated PostgreSQL test database.
-- Create the schema using schema.sql.
-- Populate the database using tests/seed.sql.
-- The index idx_evaluation_runs_model_id must not exist.
--
-- Run the sections in order to capture both query plans.
--
-- Verified reproduction: 2026-11-07
--
-- BEFORE INDEX:
-- Scan method: Seq Scan
-- Actual rows: 4
-- Rows removed by filter: 12
-- Planning Time: 5.383 ms
-- Execution Time: 0.090 ms
-- Execution buffers: shared hit=2
--
-- AFTER INDEX:
-- Scan method: Seq Scan
-- Actual rows: 4
-- Rows removed by filter: 12
-- Planning Time: 4.843 ms
-- Execution Time: 0.086 ms
-- Execution buffers: shared hit=2
--
-- Evaluation:
-- PostgreSQL did not use the new index.
-- With only 16 evaluation records, a sequential scan
-- may be cheaper than an index scan.
--
-- The 0.004 ms difference in execution time does not
-- demonstrate a performance improvement caused by
-- the index. Measurement variation and caching can
-- influence the result.
--
-- The original WR3 measurements and screenshots
-- are also preserved in the project README.


BEGIN;


-- STEP 1: Verify the database and index state.
-- Stop if the database is not a dedicated reproduction
-- database or if the index already exists.

DO $$
BEGIN
    -- Reject execution outside a reproduction database.
    IF NOT starts_with(
        current_database(),
        'pro2003_wr4_repro_check_'
    ) THEN
        RAISE EXCEPTION
            'Unsafe database: use a dedicated reproduction database';
    END IF;

    -- A valid BEFORE measurement requires no existing index.
    IF EXISTS (
        SELECT 1
        FROM pg_catalog.pg_indexes
        WHERE schemaname = 'public'
          AND tablename = 'evaluation_runs'
          AND indexname = 'idx_evaluation_runs_model_id'
    ) THEN
        RAISE EXCEPTION
            'Index already exists. Use a fresh isolated database.';
    END IF;
END
$$;


-- STEP 2: Measure the query BEFORE creating the index.

EXPLAIN (ANALYZE, BUFFERS)
SELECT
    evaluation_run_id,
    test_case_id,
    result,
    notes
FROM public.evaluation_runs
WHERE model_id = (
    SELECT model_id
    FROM public.models
    WHERE name = 'GPT-5.6'
);


-- STEP 3: Create the index.

CREATE INDEX idx_evaluation_runs_model_id
ON public.evaluation_runs (model_id);


-- STEP 4: Measure the SAME query AFTER creating the index.

EXPLAIN (ANALYZE, BUFFERS)
SELECT
    evaluation_run_id,
    test_case_id,
    result,
    notes
FROM public.evaluation_runs
WHERE model_id = (
    SELECT model_id
    FROM public.models
    WHERE name = 'GPT-5.6'
);


COMMIT;
