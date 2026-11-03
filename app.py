
import psycopg
from flask import Flask, jsonify, request
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


@app.post("/api/evaluations")
def create_evaluation():
    data = request.get_json(silent=True)

    if not isinstance(data, dict):
        return jsonify({
            "error": "A JSON object is required"
        }), 400

    test_case_id = data.get("test_case_id")
    model_id = data.get("model_id")
    result = data.get("result")
    notes = data.get("notes")

    if any(
        type(value) is not int or value <= 0
        for value in (test_case_id, model_id)
    ):
        return jsonify({
            "error": "test_case_id and model_id must be positive integers"
        }), 400

    if result not in ("pass", "fail"):
        return jsonify({
            "error": "result must be 'pass' or 'fail'"
        }), 400

    if notes is not None and not isinstance(notes, str):
        return jsonify({
            "error": "notes must be a string or null"
        }), 400

    query = """
        INSERT INTO evaluation_runs
            (test_case_id, model_id, result, notes)
        VALUES (%s, %s, %s, %s)
        RETURNING
            evaluation_run_id,
            test_case_id,
            model_id,
            result,
            notes;
    """

    try:
        with get_connection() as conn:
            with conn.cursor() as cursor:
                cursor.execute(
                    query,
                    (test_case_id, model_id, result, notes)
                )
                created = cursor.fetchone()

        return jsonify({"evaluation": created}), 201

    except psycopg.errors.ForeignKeyViolation:
        return jsonify({
            "error": "test_case_id or model_id does not exist"
        }), 400

    except psycopg.Error:
        app.logger.exception("Failed to create evaluation")
        return jsonify({
            "error": "Database request failed"
        }), 500


@app.patch("/api/evaluations/<int:evaluation_id>")
def update_evaluation(evaluation_id):
    data = request.get_json(silent=True)

    if not isinstance(data, dict) or not data:
        return jsonify({
            "error": "A non-empty JSON object is required"
        }), 400

    allowed_fields = {"result", "notes"}

    if any(field not in allowed_fields for field in data):
        return jsonify({
            "error": "Only result and notes can be updated"
        }), 400

    if "result" in data and data["result"] not in ("pass", "fail"):
        return jsonify({
            "error": "result must be 'pass' or 'fail'"
        }), 400

    if "notes" in data and data["notes"] is not None:
        if not isinstance(data["notes"], str):
            return jsonify({
                "error": "notes must be a string or null"
            }), 400

    query = """
        UPDATE evaluation_runs
        SET
            result = CASE WHEN %s THEN %s ELSE result END,
            notes = CASE WHEN %s THEN %s ELSE notes END
        WHERE evaluation_run_id = %s
        RETURNING
            evaluation_run_id,
            test_case_id,
            model_id,
            result,
            notes;
    """

    try:
        with get_connection() as conn:
            with conn.cursor() as cursor:
                cursor.execute(
                    query,
                    (
                        "result" in data,
                        data.get("result"),
                        "notes" in data,
                        data.get("notes"),
                        evaluation_id
                    )
                )
                updated = cursor.fetchone()

        if updated is None:
            return jsonify({
                "error": "Evaluation not found"
            }), 404

        return jsonify({"evaluation": updated}), 200

    except psycopg.Error:
        app.logger.exception("Failed to update evaluation")
        return jsonify({
            "error": "Database request failed"
        }), 500


@app.delete("/api/evaluations/<int:evaluation_id>")
def delete_evaluation(evaluation_id):
    query = """
        DELETE FROM evaluation_runs
        WHERE evaluation_run_id = %s
        RETURNING
            evaluation_run_id,
            test_case_id,
            model_id,
            result,
            notes;
    """

    try:
        with get_connection() as conn:
            with conn.cursor() as cursor:
                cursor.execute(query, (evaluation_id,))
                deleted = cursor.fetchone()

        if deleted is None:
            return jsonify({
                "error": "Evaluation not found"
            }), 404

        return jsonify({
            "message": "Evaluation deleted",
            "evaluation": deleted
        }), 200

    except psycopg.Error:
        app.logger.exception("Failed to delete evaluation")
        return jsonify({
            "error": "Database request failed"
        }), 500
