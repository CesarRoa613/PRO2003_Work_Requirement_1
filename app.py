
from flask import Flask, jsonify

app = Flask(__name__)


@app.get("/")
def home():
    return jsonify({
        "application": "AI Model Evaluation API",
        "status": "running"
    }), 200
