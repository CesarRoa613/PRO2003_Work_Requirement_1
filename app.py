
import psycopg
from flask import Flask, jsonify
from db import get_connection

app = Flask(__name__)


@app.get("/")
def home():
    return jsonify({
        "application": "AI Model Evaluation API",
        "status": "running"
    }), 200


@app.get("/api/evaluations")
def get_evaluations():
    query = """
        SELECT
            er.evaluation_run_id,
            f.name AS feature_name,
            tc.name AS test_case_name,
            m.name AS model_name,
            m.provider AS model_provider,
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
    """

    try:
        with get_connection() as conn:
            with conn.cursor() as cursor:
                cursor.execute(query)
                evaluations = cursor.fetchall()

        return jsonify({
            "count": len(evaluations),
            "evaluations": evaluations
        }), 200

    except psycopg.Error:
        app.logger.exception("Failed to fetch evaluations")
        return jsonify({
            "error": "Database request failed"
        }), 500
