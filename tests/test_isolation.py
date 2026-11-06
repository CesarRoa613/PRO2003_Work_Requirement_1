
def test_api_insert_is_isolated(client):
    # Confirm the expected starting state.
    before = client.get("/api/evaluations")

    assert before.status_code == 200
    assert before.get_json()["count"] == 16

    # Insert through the real Flask API.
    response = client.post(
        "/api/evaluations",
        json={
            "test_case_id": 1,
            "model_id": 1,
            "result": "pass",
            "notes": "WR4_PYTEST_ROLLBACK_PROBE",
        },
    )

    assert response.status_code == 201

    created = response.get_json()["evaluation"]

    assert created["result"] == "pass"
    assert created["notes"] == "WR4_PYTEST_ROLLBACK_PROBE"

    # The same test should see its uncommitted insert.
    after = client.get("/api/evaluations")

    assert after.status_code == 200

    data = after.get_json()

    assert data["count"] == 17
    assert any(
        item["evaluation_run_id"]
        == created["evaluation_run_id"]
        for item in data["evaluations"]
    )
