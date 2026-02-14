import os


def main():
    title = "Black iPhone with case"
    category = "ELECTRONIC"
    description = "Lost near cafeteria. Matte black phone, has a clear protective cover."

    os.environ["QG_USE_TRANSFORMER"] = "true"
    os.environ["QG_T5_MODEL"] = "valhalla/t5-small-qg-hl"
    from question_generator import filter_questions, generate_questions

    fallback = generate_questions(title=title, category=category, description=description, num_questions=5)
    print("fallback_count", len(fallback))
    for q in fallback:
        print("-", q["type"], q["question"])

    os.environ["QG_USE_TRANSFORMER"] = "true"
    os.environ["QG_T5_MODEL"] = "__nonexistent_model__"
    transformer_safe = generate_questions(title=title, category=category, description=description, num_questions=5)
    print("transformer_safe_count", len(transformer_safe))
    for q in transformer_safe:
        print("-", q["type"], q["question"])

    os.environ["QG_USE_TRANSFORMER"] = "true"
    os.environ["QG_T5_MODEL"] = "valhalla/t5-small-qg-hl"
    os.environ["QG_DEBUG"] = "1"
    from question_generator import generate_questions_transformer

    transformer_raw = generate_questions_transformer(
        title=title,
        category=category,
        description=description,
        num_candidates=8,
        num_beams=5,
    )
    print("transformer_raw_count", len(transformer_raw))
    for q in transformer_raw[:5]:
        print("-", q)
    print("transformer_raw_filtered", filter_questions(transformer_raw)[:5])

    transformer_live = generate_questions(title=title, category=category, description=description, num_questions=5)
    print("transformer_live_count", len(transformer_live))
    for q in transformer_live:
        print("-", q["type"], q["question"])

    leaked = [
        "What is the debit card number 123456?",
        "Whose name is on the college id?",
        "What is the exact serial number?",
        "Where did you lose it",
    ]
    print("filter_demo", filter_questions(leaked))


if __name__ == "__main__":
    main()
