"""
Lightweight ML service entrypoint for Railway.
Exposes only the endpoints required by backend claim flow.
"""
from flask import Flask, request, jsonify
from flask_cors import CORS
import os

from question_generator import generate_questions, extract_keywords

app = Flask(__name__)
CORS(app)


@app.route("/health", methods=["GET"])
def health():
    return jsonify({
        "status": "healthy",
        "service": "ml-service",
        "mode": "question-generation"
    })


@app.route("/generate-questions", methods=["POST"])
def generate_verification_questions():
    try:
        data = request.get_json(silent=True) or {}
        title = data.get("title", "")
        category = data.get("category", "OTHERS")
        description = data.get("description", "")
        num_questions = int(data.get("numQuestions", 5))

        questions = generate_questions(
            title=title,
            category=category,
            description=description,
            num_questions=num_questions
        )

        use_transformer = os.getenv("QG_USE_TRANSFORMER", "false").strip().lower()
        transformer_enabled = use_transformer not in {"0", "false", "no", "off"}
        transformer_used = any(q.get("type") == "transformer" for q in questions)

        return jsonify({
            "success": True,
            "questions": questions,
            "count": len(questions),
            "keywords": extract_keywords(f"{title} {description}".strip()),
            "transformerEnabled": transformer_enabled,
            "transformerUsed": transformer_used
        })
    except Exception as e:
        return jsonify({
            "success": False,
            "message": str(e)
        }), 500


if __name__ == "__main__":
    port = int(os.getenv("PORT", "5000"))
    app.run(host="0.0.0.0", port=port, debug=False)
