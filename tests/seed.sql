-- PRO2003 Work Requirement 2
-- Populate the AI Model Evaluation Database with realistic test data.

-- Add AI features.
INSERT INTO features (name, description)
VALUES
    ('Text Summarization', 'Tests the ability to create concise summaries while preserving important information.'),
    ('Code Generation', 'Tests the ability to generate correct and useful programming code.'),
    ('Translation', 'Tests the ability to translate text accurately between languages.'),
    ('Safety Filtering', 'Tests how the model handles potentially unsafe or harmful requests.');

-- Add test cases connected to the features.
INSERT INTO test_cases (feature_id, name, description, expected_result)
VALUES
    (
        (SELECT feature_id FROM features WHERE name = 'Text Summarization'),
        'Summarize short news article',
        'Summarize a short news article in a few sentences.',
        'A concise summary containing the main points.'
    ),
    (
        (SELECT feature_id FROM features WHERE name = 'Text Summarization'),
        'Summarize technical text',
        'Summarize a longer technical explanation.',
        'A clear summary that preserves the important technical information.'
    ),
    (
        (SELECT feature_id FROM features WHERE name = 'Code Generation'),
        'Generate Python function',
        'Generate a Python function from a simple specification.',
        'Valid Python code that solves the requested task.'
    ),
    (
        (SELECT feature_id FROM features WHERE name = 'Code Generation'),
        'Generate SQL query',
        'Generate a SQL query from a natural-language request.',
        'A valid SQL query that returns the requested data.'
    ),
    (
        (SELECT feature_id FROM features WHERE name = 'Translation'),
        'Translate English to Spanish',
        'Translate a short English text into Spanish.',
        'An accurate and natural Spanish translation.'
    ),
    (
        (SELECT feature_id FROM features WHERE name = 'Translation'),
        'Translate Spanish to English',
        'Translate a short Spanish text into English.',
        'An accurate and natural English translation.'
    ),
    (
        (SELECT feature_id FROM features WHERE name = 'Safety Filtering'),
        'Refuse harmful request',
        'Test whether the model refuses a clearly harmful request.',
        'The model should refuse the harmful request.'
    ),
    (
        (SELECT feature_id FROM features WHERE name = 'Safety Filtering'),
        'Answer safe security question',
        'Test whether the model can answer a harmless security question.',
        'A useful answer without unnecessary refusal.'
    );

-- Add AI models.
INSERT INTO models (name, provider)
VALUES
    ('GPT-5.6', 'OpenAI'),
    ('Claude Sonnet 4.5', 'Anthropic'),
    ('Gemini 2.5 Pro', 'Google'),
    ('Llama 4 Maverick', 'Meta');
    -- Add evaluation runs connecting models to test cases.
-- The results are varied so that later queries can analyze both passes and failures.
INSERT INTO evaluation_runs (test_case_id, model_id, result, notes)
VALUES
    (
        (SELECT test_case_id FROM test_cases WHERE name = 'Summarize short news article'),
        (SELECT model_id FROM models WHERE name = 'GPT-5.6'),
        'pass',
        'Produced a concise summary containing the main points.'
    ),
    (
        (SELECT test_case_id FROM test_cases WHERE name = 'Summarize short news article'),
        (SELECT model_id FROM models WHERE name = 'Claude Sonnet 4.5'),
        'pass',
        'Summary was clear and accurate.'
    ),
    (
        (SELECT test_case_id FROM test_cases WHERE name = 'Summarize technical text'),
        (SELECT model_id FROM models WHERE name = 'Gemini 2.5 Pro'),
        'pass',
        'Preserved the important technical information.'
    ),
    (
        (SELECT test_case_id FROM test_cases WHERE name = 'Summarize technical text'),
        (SELECT model_id FROM models WHERE name = 'Llama 4 Maverick'),
        'fail',
        'Omitted an important technical detail.'
    ),

    (
        (SELECT test_case_id FROM test_cases WHERE name = 'Generate Python function'),
        (SELECT model_id FROM models WHERE name = 'GPT-5.6'),
        'pass',
        'Generated valid Python code.'
    ),
    (
        (SELECT test_case_id FROM test_cases WHERE name = 'Generate Python function'),
        (SELECT model_id FROM models WHERE name = 'Llama 4 Maverick'),
        'pass',
        'Generated a working implementation.'
    ),
    (
        (SELECT test_case_id FROM test_cases WHERE name = 'Generate SQL query'),
        (SELECT model_id FROM models WHERE name = 'Claude Sonnet 4.5'),
        'pass',
        'Generated a valid SQL query.'
    ),
    (
        (SELECT test_case_id FROM test_cases WHERE name = 'Generate SQL query'),
        (SELECT model_id FROM models WHERE name = 'Gemini 2.5 Pro'),
        'fail',
        'Query did not return the requested result.'
    ),

    (
        (SELECT test_case_id FROM test_cases WHERE name = 'Translate English to Spanish'),
        (SELECT model_id FROM models WHERE name = 'GPT-5.6'),
        'pass',
        'Translation was accurate and natural.'
    ),
    (
        (SELECT test_case_id FROM test_cases WHERE name = 'Translate English to Spanish'),
        (SELECT model_id FROM models WHERE name = 'Gemini 2.5 Pro'),
        'pass',
        'Translation preserved the meaning well.'
    ),
    (
        (SELECT test_case_id FROM test_cases WHERE name = 'Translate Spanish to English'),
        (SELECT model_id FROM models WHERE name = 'Claude Sonnet 4.5'),
        'pass',
        'Translation was clear and accurate.'
    ),
    (
        (SELECT test_case_id FROM test_cases WHERE name = 'Translate Spanish to English'),
        (SELECT model_id FROM models WHERE name = 'Llama 4 Maverick'),
        'fail',
        'Some meaning was lost in the translation.'
    ),

    (
        (SELECT test_case_id FROM test_cases WHERE name = 'Refuse harmful request'),
        (SELECT model_id FROM models WHERE name = 'GPT-5.6'),
        'pass',
        'Correctly refused the harmful request.'
    ),
    (
        (SELECT test_case_id FROM test_cases WHERE name = 'Refuse harmful request'),
        (SELECT model_id FROM models WHERE name = 'Claude Sonnet 4.5'),
        'pass',
        'Refused the request and gave a safe response.'
    ),
    (
        (SELECT test_case_id FROM test_cases WHERE name = 'Answer safe security question'),
        (SELECT model_id FROM models WHERE name = 'Gemini 2.5 Pro'),
        'pass',
        'Answered the harmless security question usefully.'
    ),
    (
        (SELECT test_case_id FROM test_cases WHERE name = 'Answer safe security question'),
        (SELECT model_id FROM models WHERE name = 'Llama 4 Maverick'),
        'fail',
        'Refused a question that should have been answered safely.'
    );