
import pytest
import conftest


@pytest.mark.parametrize(
    ("setting", "invalid_value", "expected_error"),
    [
        (
            "DB_NAME",
            "pro2003_ai_evaluation_restored",
            "Unsafe test database configuration",
        ),
        (
            "DB_USER",
            "postgres",
            "Unsafe test database user",
        ),
    ],
)
def test_unsafe_configuration_is_rejected(
    monkeypatch, setting, invalid_value, expected_error
):
    config = {
        "DB_HOST": "localhost",
        "DB_PORT": "5432",
        "DB_NAME": "pro2003_wr4_pytest",
        "DB_USER": "pro2003_pytest",
        "DB_PASSWORD": "dummy-test-value",
    }

    config[setting] = invalid_value

    monkeypatch.setattr(
        conftest,
        "dotenv_values",
        lambda _: config,
    )

    def forbidden_connection(*args, **kwargs):
        raise AssertionError(
            "Database connection attempted before validation"
        )

    monkeypatch.setattr(
        conftest.psycopg,
        "connect",
        forbidden_connection,
    )

    with pytest.raises(RuntimeError, match=expected_error):
        conftest.get_safe_test_connection()

@pytest.mark.parametrize(
    ("actual_database", "actual_user"),
    [
        ("pro2003_ai_evaluation_restored", "pro2003_pytest"),
        ("pro2003_wr4_pytest", "postgres"),
    ],
)
def test_actual_connection_identity_is_verified(
    monkeypatch, actual_database, actual_user
):
    from unittest.mock import MagicMock

    config = {
        "DB_HOST": "localhost",
        "DB_PORT": "5432",
        "DB_NAME": "pro2003_wr4_pytest",
        "DB_USER": "pro2003_pytest",
        "DB_PASSWORD": "dummy-test-value",
    }

    connection = MagicMock()
    cursor = connection.cursor.return_value.__enter__.return_value
    cursor.fetchone.return_value = {
        "database_name": actual_database,
        "database_user": actual_user,
        "login_user": actual_user,
    }

    monkeypatch.setattr(
        conftest,
        "load_test_config",
        lambda: config,
    )
    monkeypatch.setattr(
        conftest.psycopg,
        "connect",
        lambda **kwargs: connection,
    )

    with pytest.raises(
        RuntimeError,
        match="Unsafe PostgreSQL connection",
    ):
        conftest.get_safe_test_connection()

    connection.close.assert_called_once()
