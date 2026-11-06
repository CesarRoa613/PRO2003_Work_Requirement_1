
from pathlib import Path

import psycopg
import pytest
from dotenv import dotenv_values
from psycopg.rows import dict_row


PROJECT_ROOT = Path(__file__).resolve().parents[1]
EXPECTED_DATABASE = "pro2003_wr4_pytest"
EXPECTED_USER = "pro2003_pytest"


def load_test_config():
    config = dotenv_values(PROJECT_ROOT / ".env.test")

    required = (
        "DB_HOST",
        "DB_PORT",
        "DB_NAME",
        "DB_USER",
        "DB_PASSWORD",
    )

    for key in required:
        if not config.get(key):
            raise RuntimeError(f"Missing test configuration: {key}")

    if config["DB_NAME"] != EXPECTED_DATABASE:
        raise RuntimeError("Unsafe test database configuration")

    if config["DB_USER"] != EXPECTED_USER:
        raise RuntimeError("Unsafe test database user")

    return config


def get_safe_test_connection():
    config = load_test_config()

    connection = psycopg.connect(
        host=config["DB_HOST"],
        port=config["DB_PORT"],
        dbname=config["DB_NAME"],
        user=config["DB_USER"],
        password=config["DB_PASSWORD"],
        row_factory=dict_row,
    )

    try:
        with connection.cursor() as cursor:
            cursor.execute(
                """
                SELECT
                    current_database() AS database_name,
                    current_user AS database_user,
                    session_user AS login_user
                """
            )
            identity = cursor.fetchone()

        if (
            identity["database_name"] != EXPECTED_DATABASE
            or identity["database_user"] != EXPECTED_USER
            or identity["login_user"] != EXPECTED_USER
        ):
            raise RuntimeError(
                "Unsafe PostgreSQL connection: "
                "unexpected database or user"
            )

    except Exception:
        connection.close()
        raise

    return connection


class IsolatedRequestConnection:
    """Use a savepoint without committing the outer test transaction."""

    def __init__(self, connection):
        self.connection = connection
        self.transaction_context = None

    def __enter__(self):
        self.transaction_context = self.connection.transaction()
        self.transaction_context.__enter__()
        return self.connection

    def __exit__(self, exc_type, exc_value, traceback):
        return self.transaction_context.__exit__(
            exc_type, exc_value, traceback
        )


@pytest.fixture
def client(monkeypatch):
    import app as app_module

    connection = get_safe_test_connection()
    original_testing = app_module.app.config["TESTING"]

    try:
        # Verify the expected baseline.
        # This also keeps an outer database transaction open.
        with connection.cursor() as cursor:
            cursor.execute(
                "SELECT COUNT(*) AS row_count "
                "FROM public.evaluation_runs"
            )
            row_count = cursor.fetchone()["row_count"]

        if row_count != 16:
            raise RuntimeError(
                f"Unexpected test baseline: {row_count} rows"
            )

        # Flask uses savepoints instead of committing or closing
        # the connection owned by this pytest fixture.
        monkeypatch.setattr(
            app_module,
            "get_connection",
            lambda: IsolatedRequestConnection(connection),
        )

        app_module.app.config["TESTING"] = True

        with app_module.app.test_client() as test_client:
            yield test_client

    finally:
        app_module.app.config["TESTING"] = original_testing

        try:
            # Discard all changes made by this test.
            connection.rollback()
        finally:
            connection.close()
