CREATE TABLE features (
    feature_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT
);

CREATE TABLE test_cases (
    test_case_id SERIAL PRIMARY KEY,
    feature_id INTEGER NOT NULL,
    name VARCHAR(150) NOT NULL,
    description TEXT,
    expected_result TEXT,
    CONSTRAINT fk_test_case_feature
        FOREIGN KEY (feature_id)
        REFERENCES features(feature_id)
);

CREATE TABLE models (
    model_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    provider VARCHAR(100)
);

CREATE TABLE evaluation_runs (
    evaluation_run_id SERIAL PRIMARY KEY,
    test_case_id INTEGER NOT NULL,
    model_id INTEGER NOT NULL,
    result VARCHAR(20) NOT NULL,
    notes TEXT,
    CONSTRAINT fk_evaluation_test_case
        FOREIGN KEY (test_case_id)
        REFERENCES test_cases(test_case_id),
    CONSTRAINT fk_evaluation_model
        FOREIGN KEY (model_id)
        REFERENCES models(model_id),
    CONSTRAINT check_result
        CHECK (result IN ('pass', 'fail'))
);