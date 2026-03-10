import json
import os
import re

import question_generator as qg

os.environ["QG_USE_TRANSFORMER"] = "true"

CASES = [
    {
        "title": "Black iPhone with clear case",
        "category": "ELECTRONIC",
        "description": "Matte black iPhone with transparent cover, one corner scratch, lost near cafeteria.",
    },
    {
        "title": "Brown leather wallet",
        "category": "ACCESSORIES",
        "description": "Bi-fold brown leather wallet with zipper pocket and a small embossed logo.",
    },
    {
        "title": "Student ID card",
        "category": "DOCUMENT",
        "description": "University student ID card in blue lanyard, issued by campus administration.",
    },
]

MODELS = [
    ("FLAN_T5", qg.MODEL_FLAN_T5),
    ("VALHALLA_QG_HL", qg.MODEL_VALHALLA_QG_HL),
    ("LEGACY_T5_QG", qg.MODEL_LEGACY_T5),
]

BAD_PATTERNS = [
    r"\\bname\\s+of\\s+the\\s+(item|object|thing)\\b",
    r"\\blost\\s+and\\s+found\\b",
    r"\\bwhere\\s+does\\s+it\\s+come\\s+from\\b",
    r"\\bphysical\\s+attributes\\b",
]


def q_quality_score(question: str) -> int:
    ql = question.lower().strip()
    score = 0
    if question.endswith("?"):
        score += 1
    if len(question.split()) >= 6:
        score += 1
    if any(
        keyword in ql
        for keyword in [
            "brand",
            "color",
            "material",
            "size",
            "mark",
            "logo",
            "model",
            "screen",
            "authority",
            "issue",
            "expiry",
        ]
    ):
        score += 2
    if any(re.search(pattern, ql) for pattern in BAD_PATTERNS):
        score -= 2
    return score


report = []
for model_label, model_name in MODELS:
    qg.MODEL_USED = model_name
    qg._T5_LOADED_MODEL_NAME = None
    qg._T5_TOKENIZER = None
    qg._T5_MODEL = None
    qg._T5_DEVICE = None

    model_row = {
        "model": model_label,
        "model_name": model_name,
        "cases": [],
        "totals": {
            "raw": 0,
            "filtered": 0,
            "selected_transformer": 0,
            "quality_score": 0,
        },
    }

    for case in CASES:
        raw = qg.generate_questions_transformer(
            title=case["title"],
            category=case["category"],
            description=case["description"],
            num_candidates=8,
            num_beams=5,
        )
        filtered = qg.filter_questions(raw)
        final = qg.generate_questions(
            title=case["title"],
            category=case["category"],
            description=case["description"],
            num_questions=5,
        )
        selected_transformer = [q["question"] for q in final if q.get("type") == "transformer"]

        selected_quality = sum(q_quality_score(q) for q in selected_transformer)

        case_row = {
            "title": case["title"],
            "category": case["category"],
            "raw_count": len(raw),
            "filtered_count": len(filtered),
            "selected_transformer_count": len(selected_transformer),
            "raw_sample": raw[:3],
            "filtered_sample": filtered[:3],
            "selected_transformer_sample": selected_transformer[:3],
            "selected_quality": selected_quality,
        }
        model_row["cases"].append(case_row)
        model_row["totals"]["raw"] += len(raw)
        model_row["totals"]["filtered"] += len(filtered)
        model_row["totals"]["selected_transformer"] += len(selected_transformer)
        model_row["totals"]["quality_score"] += selected_quality

    report.append(model_row)

print(json.dumps(report, indent=2, ensure_ascii=True))
