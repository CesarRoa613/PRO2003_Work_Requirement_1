-- PRO2003 Work Requirement 4
-- Reproducible least-privilege security tests.
--
-- Run as postgres in pro2003_ai_evaluation_restored.
-- No changes are intended to persist.
--
-- An unexpected permission grant raises an ERROR.

DO $$
BEGIN
    IF current_database() <> 'pro2003_ai_evaluation_restored'
       OR session_user <> 'postgres' THEN
        RAISE EXCEPTION
            'Wrong database or administrator login';
    END IF;
END;
$$;

BEGIN;

-- Test object owned by postgres, removed by ROLLBACK.
CREATE TABLE public.wr4_permission_drop_probe (
    id INTEGER
);

SET LOCAL ROLE pro2003_flask;

DO $$
DECLARE
    v_count INTEGER;
    v_test_case_id INTEGER;
    v_model_id INTEGER;
    v_id INTEGER;
    v_result VARCHAR(20);
BEGIN
    IF current_user <> 'pro2003_flask' THEN
        RAISE EXCEPTION 'FAIL: Wrong active role';
    END IF;

    -- Positive test: four-table JOIN.
    SELECT COUNT(*) INTO v_count
    FROM public.evaluation_runs er
    JOIN public.test_cases tc
        ON er.test_case_id = tc.test_case_id
    JOIN public.features f
        ON tc.feature_id = f.feature_id
    JOIN public.models m
        ON er.model_id = m.model_id;

    IF v_count <> 16 THEN
        RAISE EXCEPTION
            'FAIL: Expected 16 evaluations, got %', v_count;
    END IF;

    RAISE NOTICE 'PASS: Four-table JOIN returned 16 rows';

    -- Look up IDs by name.
    SELECT test_case_id INTO STRICT v_test_case_id
    FROM public.test_cases
    WHERE name = 'Summarize short news article';

    SELECT model_id INTO STRICT v_model_id
    FROM public.models
    WHERE name = 'GPT-5.6';

    -- Positive tests: permitted CRUD operations.
    INSERT INTO public.evaluation_runs
        (test_case_id, model_id, result, notes)
    VALUES
        (v_test_case_id, v_model_id, 'pass',
         'Temporary permission test')
    RETURNING evaluation_run_id INTO v_id;

    SELECT result INTO STRICT v_result
    FROM public.evaluation_runs
    WHERE evaluation_run_id = v_id;

    IF v_result <> 'pass' THEN
        RAISE EXCEPTION 'FAIL: INSERT or SELECT';
    END IF;

    UPDATE public.evaluation_runs
    SET result = 'fail'
    WHERE evaluation_run_id = v_id;

    SELECT result INTO STRICT v_result
    FROM public.evaluation_runs
    WHERE evaluation_run_id = v_id;

    IF v_result <> 'fail' THEN
        RAISE EXCEPTION 'FAIL: UPDATE';
    END IF;

    DELETE FROM public.evaluation_runs
    WHERE evaluation_run_id = v_id;

    IF FOUND IS NOT TRUE THEN
        RAISE EXCEPTION 'FAIL: DELETE';
    END IF;

    RAISE NOTICE 'PASS: INSERT, SELECT, UPDATE, DELETE';

    -- Negative test: INSERT on reference table.
    BEGIN
        INSERT INTO public.features (feature_id, name)
VALUES (2147483000, 'WR4_FORBIDDEN_TEST');

        RAISE EXCEPTION
            'FAIL: INSERT on features was allowed';
    EXCEPTION
        WHEN insufficient_privilege THEN
            RAISE NOTICE 'PASS: INSERT on features denied';
    END;

    -- Negative test: UPDATE on reference table.
    BEGIN
        UPDATE public.models
        SET provider = 'WR4_FORBIDDEN_TEST'
        WHERE name = 'GPT-5.6';

        RAISE EXCEPTION
            'FAIL: UPDATE on models was allowed';
    EXCEPTION
        WHEN insufficient_privilege THEN
            RAISE NOTICE 'PASS: UPDATE on models denied';
    END;

    -- Negative test: DELETE on reference table.
    BEGIN
        DELETE FROM public.models
        WHERE name = 'WR4_NONEXISTENT_MODEL';

        RAISE EXCEPTION
            'FAIL: DELETE on models was allowed';
    EXCEPTION
        WHEN insufficient_privilege THEN
            RAISE NOTICE 'PASS: DELETE on models denied';
    END;

    -- Negative test: CREATE TABLE.
    BEGIN
        EXECUTE
            'CREATE TABLE public.wr4_forbidden_create (id INTEGER)';

        RAISE EXCEPTION
            'FAIL: CREATE TABLE was allowed';
    EXCEPTION
        WHEN insufficient_privilege THEN
            RAISE NOTICE 'PASS: CREATE TABLE denied';
    END;

    -- Negative test: DROP TABLE.
    BEGIN
        EXECUTE
            'DROP TABLE public.wr4_permission_drop_probe';

        RAISE EXCEPTION
            'FAIL: DROP TABLE was allowed';
    EXCEPTION
        WHEN insufficient_privilege THEN
            RAISE NOTICE 'PASS: DROP TABLE denied';
    END;

    -- Negative test: CREATE ROLE.
    BEGIN
        EXECUTE
            'CREATE ROLE wr4_forbidden_role NOLOGIN';

        RAISE EXCEPTION
            'FAIL: CREATE ROLE was allowed';
    EXCEPTION
        WHEN insufficient_privilege THEN
            RAISE NOTICE 'PASS: CREATE ROLE denied';
    END;

    RAISE NOTICE 'PASS: All security checks completed';
END;
$$;

-- Roll back test data and test objects.
ROLLBACK;