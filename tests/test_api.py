
import pytest


def test_get_evaluations_returns_joined_records(client):
    response = client.get("/api/evaluations")

    assert response.status_code == 200

    data = response.get_json()

    assert data["count"] == 16
    assert len(data["evaluations"]) == 16

    required_fields = {
        "evaluation_run_id",
        "feature_name",
        "test_case_name",
        "model_name",
        "model_provider",
        "result",
        "notes",
    }

    for evaluation in data["evaluations"]:
        assert required_fields <= evaluation.keys()
        assert evaluation["result"] in ("pass", "fail")
        assert evaluation["feature_name"]
        assert evaluation["test_case_name"]
        assert evaluation["model_name"]


@pytest.mark.parametrize(
    "payload",
    [
        None,
        [],
        {},
        {"test_case_id": 0, "model_id": 1, "result": "pass"},
        {"test_case_id": True, "model_id": 1, "result": "pass"},
        {"test_case_id": 1, "model_id": -1, "result": "pass"},
        {"test_case_id": 1, "model_id": 1, "result": "unknown"},
        {
            "test_case_id": 1,
            "model_id": 1,
            "result": "pass",
            "notes": 123,
        },
    ],
)
def test_post_rejects_invalid_payload(client, payload):
    response = client.post(
        "/api/evaluations",
        json=payload,
    )

    assert response.status_code == 400
    assert "error" in response.get_json()

def test_create_update_delete_lifecycle(client):
    # Create a temporary evaluation.
    response = client.post(
        "/api/evaluations",
        json={
            "test_case_id": 1,
            "model_id": 1,
            "result": "pass",
            "notes": "WR4 CRUD integration test",
        },
    )

    assert response.status_code == 201

    created = response.get_json()["evaluation"]
    evaluation_id = created["evaluation_run_id"]

    assert created["result"] == "pass"
    assert created["notes"] == "WR4 CRUD integration test"

    # Update the same evaluation.
    response = client.patch(
        f"/api/evaluations/{evaluation_id}",
        json={
            "result": "fail",
            "notes": "Updated during CRUD test",
        },
    )

    assert response.status_code == 200

    updated = response.get_json()["evaluation"]

    assert updated["evaluation_run_id"] == evaluation_id
    assert updated["result"] == "fail"
    assert updated["notes"] == "Updated during CRUD test"

    # Delete the evaluation.
    response = client.delete(
        f"/api/evaluations/{evaluation_id}"
    )

    assert response.status_code == 200

    deleted = response.get_json()["evaluation"]

    assert deleted["evaluation_run_id"] == evaluation_id
    assert deleted["result"] == "fail"

    # Verify the original evaluation count is restored.
    response = client.get("/api/evaluations")

    assert response.status_code == 200

    data = response.get_json()

    assert data["count"] == 16
    assert all(
        item["evaluation_run_id"] != evaluation_id
        for item in data["evaluations"]
    )

@pytest.mark.parametrize(
    "invalid_field",
    ["test_case_id", "model_id"],
)
def test_foreign_key_violation_and_recovery(client, invalid_field):
    payload = {
        "test_case_id": 1,
        "model_id": 1,
        "result": "pass",
        "notes": "WR4 foreign key test",
    }

    # Use an ID that does not exist.
    payload[invalid_field] = 2147483000

    response = client.post("/api/evaluations", json=payload)

    assert response.status_code == 400
    assert response.get_json()["error"] == (
        "test_case_id or model_id does not exist"
    )

    # The failed INSERT must not change the dataset.
    response = client.get("/api/evaluations")

    assert response.status_code == 200
    assert response.get_json()["count"] == 16

    # A valid INSERT must still work after the database error.
    payload[invalid_field] = 1

    response = client.post("/api/evaluations", json=payload)

    assert response.status_code == 201
    assert response.get_json()["evaluation"]["result"] == "pass"

@pytest.mark.parametrize("method", ["patch", "delete"])
def test_missing_evaluation_returns_404(client, method):
    evaluation_id = 2147483000

    if method == "patch":
        response = client.patch(
            f"/api/evaluations/{evaluation_id}",
            json={"result": "pass"},
        )
    else:
        response = client.delete(
            f"/api/evaluations/{evaluation_id}"
        )

    assert response.status_code == 404
    assert response.get_json()["error"] == "Evaluation not found"


@pytest.mark.parametrize(
    "payload",
    [
        None,
        [],
        {},
        {"result": "unknown"},
        {"result": True},
        {"notes": 123},
        {"model_id": 1},
    ],
)
def test_patch_rejects_invalid_payload(client, payload):
    # Capture the complete dataset before the invalid request.
    before_response = client.get("/api/evaluations")

    assert before_response.status_code == 200
    before_data = before_response.get_json()
    assert before_data["count"] == 16

    # Attempt an invalid update.
    response = client.patch(
        "/api/evaluations/1",
        json=payload,
    )

    assert response.status_code == 400
    assert "error" in response.get_json()

    # Verify that neither rows nor field values changed.
    after_response = client.get("/api/evaluations")

    assert after_response.status_code == 200
    after_data = after_response.get_json()

    assert after_data == before_data


@pytest.mark.parametrize(
    ("patch_payload", "expected_result", "expected_notes"),
    [
        ({"result": "fail"}, "fail", "Original notes"),
        ({"notes": "Updated notes"}, "pass", "Updated notes"),
        ({"notes": None}, "pass", None),
    ],
)
def test_patch_preserves_fields_not_supplied(
    client, patch_payload, expected_result, expected_notes
):
    # Create a temporary record with known initial values.
    create_response = client.post(
        "/api/evaluations",
        json={
            "test_case_id": 1,
            "model_id": 1,
            "result": "pass",
            "notes": "Original notes",
        },
    )

    assert create_response.status_code == 201

    created = create_response.get_json()["evaluation"]
    evaluation_id = created["evaluation_run_id"]

    # Update only the field supplied in the PATCH request.
    patch_response = client.patch(
        f"/api/evaluations/{evaluation_id}",
        json=patch_payload,
    )

    assert patch_response.status_code == 200

    updated = patch_response.get_json()["evaluation"]

    assert updated["evaluation_run_id"] == evaluation_id
    assert updated["test_case_id"] == created["test_case_id"]
    assert updated["model_id"] == created["model_id"]
    assert updated["result"] == expected_result
    assert updated["notes"] == expected_notes

    # Confirm that a subsequent GET returns the updated values.
    get_response = client.get("/api/evaluations")

    assert get_response.status_code == 200

    matching = [
        item
        for item in get_response.get_json()["evaluations"]
        if item["evaluation_run_id"] == evaluation_id
    ]

    assert len(matching) == 1
    assert matching[0]["result"] == expected_result
    assert matching[0]["notes"] == expected_notes

def test_get_evaluations_returns_correct_relationships(client):
    response = client.get("/api/evaluations")

    assert response.status_code == 200
    evaluations = response.get_json()["evaluations"]

    expected_records = [
        {
            "notes": "Produced a concise summary containing the main points.",
            "feature_name": "Text Summarization",
            "test_case_name": "Summarize short news article",
            "model_name": "GPT-5.6",
            "model_provider": "OpenAI",
            "result": "pass",
        },
        {
            "notes": "Refused a question that should have been answered safely.",
            "feature_name": "Safety Filtering",
            "test_case_name": "Answer safe security question",
            "model_name": "Llama 4 Maverick",
            "model_provider": "Meta",
            "result": "fail",
        },
    ]

    for expected in expected_records:
        matching = [
            evaluation
            for evaluation in evaluations
            if evaluation["notes"] == expected["notes"]
        ]

        assert len(matching) == 1
        actual = matching[0]

        for field, expected_value in expected.items():
            assert actual[field] == expected_value
