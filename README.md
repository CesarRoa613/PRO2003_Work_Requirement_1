# PRO2003 Work Requirement 1
## AI Model Evaluation Database

### Domain

This project contains a small PostgreSQL database for evaluating AI models.

The database is designed to keep track of AI features, test cases, AI models, and evaluation runs. A feature can have several test cases, and each test case can be evaluated using different AI models.

### Database Design

The database contains four related tables:

- `features` – stores the AI features that are being tested.
- `test_cases` – stores individual test cases connected to a feature.
- `models` – stores the AI models used during evaluation.
- `evaluation_runs` – stores the result of running a model against a test case.

### Relationships

There is a one-to-many relationship between `features` and `test_cases`.

One feature can have many test cases, while each test case belongs to one feature.

There is also a many-to-many relationship between `test_cases` and `models`.

This relationship is resolved through the intermediate table `evaluation_runs`. Each evaluation run connects one test case with one model and stores the result of that evaluation.

### Keys and Constraints

Each table has a primary key.

Foreign keys are used to connect the tables:

- `test_cases.feature_id` references `features.feature_id`
- `evaluation_runs.test_case_id` references `test_cases.test_case_id`
- `evaluation_runs.model_id` references `models.model_id`

Required values use `NOT NULL`.

The `result` column in `evaluation_runs` uses a `CHECK` constraint so that only `pass` or `fail` can be stored.

### Files

- `schema.sql` contains the PostgreSQL DDL statements used to create the database.
- `er_model.png` contains the ER model using Crow's Foot relationships.