
"""
NLP-based Question Generation Module for Lost & Found Item Verification.

Uses keyword extraction + template-based question generation.
Generates item-specific verification questions based on title, category, and description.
"""

import re
import random
import os
from difflib import SequenceMatcher
from typing import List, Dict, Optional, Iterable, Tuple

try:
    import spacy
except Exception:
    spacy = None

try:
    import torch
except Exception:
    torch = None

try:
    from transformers import T5ForConditionalGeneration, T5Tokenizer
except Exception:
    T5ForConditionalGeneration = None
    T5Tokenizer = None


# ======================================================
# CATEGORY-SPECIFIC QUESTION TEMPLATES
# ======================================================

CATEGORY_QUESTIONS = {
    "ELECTRONIC": [
        "What is the brand/manufacturer of this device?",
        "What is the color of the device?",
        "Does the device have any protective case or cover? If yes, describe it.",
        "What is the approximate screen size or dimensions?",
        "Are there any visible scratches, dents, or distinguishing marks?",
        "Was the device powered on or off when you last had it?",
        "Does the device have any stickers or personalization?",
    ],
    "DOCUMENT": [
        "What type of document is it (ID card, passport, certificate, etc.)?",
        "Whose name appears on the document?",
        "What is the issuing authority or organization on the document?",
        "Can you recall any partial ID numbers or reference numbers?",
        "What is the approximate date of issue or expiry visible on the document?",
    ],
    "ACCESSORIES": [
        "What is the color of the item?",
        "What is the brand or maker of this item?",
        "What material is the item made of (leather, fabric, metal, etc.)?",
        "Describe any distinctive patterns, logos, or markings on it.",
        "What are the approximate dimensions or size of the item?",
        "Does the item contain anything specific inside it?",
    ],
    "CLOTHING": [
        "What is the color of the clothing item?",
        "What brand is the clothing item?",
        "What size is the clothing item?",
        "Describe any patterns, prints, or designs on the item.",
        "What material/fabric is it made of?",
        "Does it have any labels, tags, or identifiable markings?",
    ],
    "JEWELLERY": [
        "What type of jewellery is it (ring, necklace, bracelet, earring, etc.)?",
        "What metal is the jewellery made of (gold, silver, platinum, etc.)?",
        "Does it have any gemstones or diamonds? If yes, describe them.",
        "What is the approximate size or length?",
        "Are there any engravings or inscriptions on it?",
        "What is the clasp or closure type?",
    ],
    "FOOTWEAR": [
        "What is the brand of the footwear?",
        "What is the color of the footwear?",
        "What is the shoe size?",
        "What type of footwear is it (sneakers, sandals, boots, formal shoes)?",
        "Are there any distinctive markings, scuffs, or customizations?",
        "What material is the footwear made of?",
    ],
    "OTHERS": [
        "What is the color of the item?",
        "What are the approximate dimensions of the item?",
        "What material is the item made of?",
        "Describe any distinctive markings or features.",
        "What brand or manufacturer is it, if applicable?",
    ],
}

# ======================================================
# KEYWORD-BASED QUESTION TEMPLATES
# ======================================================

# Keywords that trigger specific follow-up questions
KEYWORD_QUESTION_MAP = {
    # Color-related
    "black": "You mentioned the item is black — is it matte black or glossy/shiny black?",
    "white": "Is the white color a pure white or more of an off-white/cream shade?",
    "red": "Is it a bright red, dark red, or maroon shade?",
    "blue": "Is it a light blue, navy blue, or royal blue?",

    # Material-related
    "leather": "Is the leather genuine or synthetic? Are there any wear marks on it?",
    "metal": "What type of metal — stainless steel, aluminum, gold-plated, or something else?",
    "plastic": "What color is the plastic? Is it translucent or opaque?",
    "fabric": "What type of fabric — cotton, polyester, nylon, or a blend?",

    # Electronics-related
    "phone": "What is the phone model and brand?",
    "laptop": "What is the laptop brand and approximate screen size?",
    "headphone": "Are the headphones over-ear, on-ear, or in-ear?",
    "earbuds": "What brand and color are the earbuds? Do they have a charging case?",
    "charger": "What type of charger connector is it (USB-C, Lightning, Micro-USB)?",
    "tablet": "What is the tablet brand and screen size?",
    "watch": "Is it a smart watch or analog watch? What brand?",
    "camera": "What is the camera brand and type (DSLR, mirrorless, point-and-shoot)?",

    # Bag-related
    "backpack": "What brand is the backpack? How many compartments does it have?",
    "bag": "What type of bag is it (handbag, tote, messenger, etc.)?",
    "wallet": "What is the wallet's color and material? Does it have a zipper or fold?",
    "purse": "What brand and color is the purse? Describe the strap.",

    # Document-related
    "card": "What type of card is it (ID, credit, student, membership)?",
    "passport": "What country issued the passport?",
    "license": "What type of license (driving, professional, etc.)?",
    "certificate": "What is the certificate for? Who issued it?",

    # Key-related
    "key": "How many keys are on the keyring? Describe any keychain or fob.",
    "keys": "How many keys are there? Is there a keychain attached?",

    # Clothing-related
    "jacket": "What type of jacket (windbreaker, hoodie, denim, leather)?",
    "shirt": "What is the shirt type (t-shirt, button-down, polo)?",
    "shoe": "What brand and size are the shoes?",
    "glasses": "Are they prescription glasses or sunglasses? What brand?",
    "umbrella": "What color is the umbrella? Is it compact/folding or full-size?",

    # Container-related
    "bottle": "What type of bottle (water bottle, thermos)? What brand and color?",
    "container": "What is stored in the container? What material is it?",
    "box": "What size is the box? What is it made of?",

    # Book-related
    "book": "What is the title and author of the book?",
    "notebook": "What brand/type of notebook? Does it have any writing inside?",
}

# ======================================================
# UNIVERSAL VERIFICATION QUESTIONS
# ======================================================

UNIVERSAL_QUESTIONS = [
    "When did you lose this item (approximate date and time)?",
    "Where exactly did you last have the item or where do you think you lost it?",
    "Can you describe any unique or distinguishing feature of this item that would help verify ownership?",
]

# ======================================================
# TITLE-BASED QUESTION GENERATION
# ======================================================

TITLE_TEMPLATES = [
    "You mentioned '{keyword}' — can you provide more specific details about it?",
    "Regarding the {keyword}, can you describe any unique markings or identifiers?",
]


SPACY_MODEL = "en_core_web_sm"
_NLP = None


def _get_nlp():
    global _NLP
    if _NLP is not None:
        return _NLP
    if spacy is None:
        return None
    try:
        _NLP = spacy.load(SPACY_MODEL)
        return _NLP
    except Exception:
        return None


_DEFAULT_T5_MODEL_NAME = "iarfmoose/t5-base-question-generator"
_T5_LOADED_MODEL_NAME = None
_T5_TOKENIZER = None
_T5_MODEL = None
_T5_DEVICE = None


def _get_t5():
    global _T5_LOADED_MODEL_NAME, _T5_TOKENIZER, _T5_MODEL, _T5_DEVICE

    requested_model_name = os.getenv("QG_T5_MODEL", _DEFAULT_T5_MODEL_NAME).strip() or _DEFAULT_T5_MODEL_NAME

    if (
        _T5_MODEL is not None
        and _T5_TOKENIZER is not None
        and _T5_LOADED_MODEL_NAME == requested_model_name
    ):
        return _T5_TOKENIZER, _T5_MODEL, _T5_DEVICE

    if torch is None or T5ForConditionalGeneration is None or T5Tokenizer is None:
        return None, None, None

    try:
        device = "cuda" if torch.cuda.is_available() else "cpu"
        tokenizer = T5Tokenizer.from_pretrained(requested_model_name)
        model = T5ForConditionalGeneration.from_pretrained(requested_model_name)
        model.to(device)
        model.eval()

        _T5_LOADED_MODEL_NAME = requested_model_name
        _T5_TOKENIZER = tokenizer
        _T5_MODEL = model
        _T5_DEVICE = device
        return _T5_TOKENIZER, _T5_MODEL, _T5_DEVICE
    except Exception:
        return None, None, None


_DEFAULT_FORBIDDEN_KEYWORDS = [
    "debit",
    "credit",
    "college id",
    "passport number",
    "driver",
    "license number",
    "id number",
    "account number",
    "pin",
    "cvv",
    "imei",
    "serial number",
    "category",
    "class",
    "label",
]


def _normalize_question_text(q: str) -> str:
    q = (q or "").strip()
    q = re.sub(r"\s+", " ", q)
    q = q.replace("’", "'").replace("“", '"').replace("”", '"')
    return q


def filter_questions(
    questions: Iterable[str],
    forbidden_keywords: Optional[List[str]] = None,
    required_keywords: Optional[List[str]] = None,
    min_words: int = 5,
    similarity_threshold: float = 0.88,
) -> List[str]:
    forbidden_keywords = list(forbidden_keywords or _DEFAULT_FORBIDDEN_KEYWORDS)
    env_forbidden = os.getenv("QG_FORBIDDEN_KEYWORDS", "").strip()
    if env_forbidden:
        forbidden_keywords.extend([p.strip() for p in env_forbidden.split(",") if p.strip()])
    required_keywords = [k.strip().lower() for k in (required_keywords or []) if (k or "").strip()]

    normalized_keywords = []
    for kw in forbidden_keywords:
        kw = (kw or "").strip().lower()
        if kw:
            normalized_keywords.append(kw)

    filtered: List[str] = []
    filtered_norm: List[str] = []

    for raw in questions:
        q = _normalize_question_text(raw)
        if not q:
            continue

        q_lower = q.lower()

        if "category" in q_lower or "label" in q_lower or "class" in q_lower:
            continue

        if re.search(r"\bwhat\s+is\s+the\s+name\s+of\b", q_lower) and re.search(r"\bcategory\b|\bclass\b|\blabel\b", q_lower):
            continue

        if required_keywords and not any(rk in q_lower for rk in required_keywords):
            continue

        if any(kw in q_lower for kw in normalized_keywords):
            continue

        if re.search(r"\b\d{2,}\b", q_lower):
            continue

        if re.search(r"[\w\.-]+@[\w\.-]+\.\w+", q_lower):
            continue

        if re.search(r"\b\+?\d[\d\s\-\(\)]{7,}\b", q_lower):
            continue

        if not q.endswith("?"):
            if q.endswith("."):
                q = q[:-1] + "?"
            else:
                q = q + "?"

        if len([w for w in q.split(" ") if w]) < min_words:
            continue

        norm = re.sub(r"[^a-z0-9]+", " ", q_lower).strip()
        if not norm:
            continue

        is_too_similar = False
        for prev_norm in filtered_norm:
            if SequenceMatcher(a=norm, b=prev_norm).ratio() >= similarity_threshold:
                is_too_similar = True
                break

        if is_too_similar:
            continue

        filtered.append(q)
        filtered_norm.append(norm)

    return filtered


def _split_generated_text_into_questions(text: str) -> List[str]:
    text = _normalize_question_text(text)
    if not text:
        return []

    text = re.sub(r"\b(question|questions)\s*:\s*", "", text, flags=re.IGNORECASE).strip()
    text = text.replace("<hl>", " ").replace("</hl>", " ")
    text = re.sub(r"\s+", " ", text).strip()

    parts = []
    for piece in re.split(r"\?\s*", text):
        piece = piece.strip()
        if not piece:
            continue
        parts.append(piece + "?")
    if not parts and text.endswith("?"):
        parts = [text]
    return parts


_TRANSFORMER_HINTS_BY_CATEGORY = {
    "ELECTRONIC": [
        "brand",
        "manufacturer",
        "model",
        "color",
        "case",
        "cover",
        "screen",
        "scratch",
        "dent",
        "sticker",
        "personal",
        "mark",
        "powered",
        "charger",
        "connector",
    ],
    "DOCUMENT": [
        "type of document",
        "name",
        "issuing",
        "authority",
        "expiry",
        "expiration",
        "issue date",
    ],
    "ACCESSORIES": [
        "brand",
        "color",
        "material",
        "pattern",
        "logo",
        "mark",
        "size",
        "zipper",
        "compartment",
    ],
    "CLOTHING": [
        "brand",
        "color",
        "size",
        "pattern",
        "material",
        "label",
        "tag",
    ],
    "JEWELLERY": [
        "type",
        "metal",
        "gem",
        "stone",
        "engraving",
        "inscription",
        "clasp",
        "size",
    ],
    "FOOTWEAR": [
        "brand",
        "color",
        "size",
        "material",
        "mark",
        "scuff",
    ],
    "OTHERS": [
        "color",
        "material",
        "mark",
        "feature",
        "brand",
        "size",
        "dimension",
    ],
}


def _filter_transformer_questions(questions: List[str], category: str, title_keywords: List[str]) -> List[str]:
    cat_upper = (category or "OTHERS").strip().upper() or "OTHERS"
    hints = _TRANSFORMER_HINTS_BY_CATEGORY.get(cat_upper, _TRANSFORMER_HINTS_BY_CATEGORY["OTHERS"])
    title_keywords = [(k or "").strip().lower() for k in (title_keywords or []) if (k or "").strip()]

    out: List[str] = []
    for q in questions:
        q_norm = _normalize_question_text(q)
        if not q_norm:
            continue
        q_lower = q_norm.lower()

        if any(tok in q_lower for tok in [" lost ", " found ", " near ", " around "]):
            continue

        has_hint = bool(hints and any(h in q_lower for h in hints))
        has_title_kw = bool(title_keywords and any(tk in q_lower for tk in title_keywords[:6]))
        if not (has_hint or has_title_kw):
            continue

        out.append(q_norm)
    return out


def _rewrite_transformer_question(q: str, category: str) -> Optional[str]:
    q_norm = _normalize_question_text(q)
    if not q_norm:
        return None

    q_lower = q_norm.lower()
    cat_upper = (category or "OTHERS").strip().upper() or "OTHERS"

    if cat_upper == "ELECTRONIC":
        if "case" in q_lower or "cover" in q_lower:
            return "Does the device have any protective case or cover? If yes, describe it."
        if "brand" in q_lower or "manufacturer" in q_lower:
            return "What is the brand/manufacturer of this device?"
        if "color" in q_lower:
            return "What is the color of the device?"
        if "screen" in q_lower or "dimension" in q_lower or "size" in q_lower:
            return "What is the approximate screen size or dimensions?"
        if "scratch" in q_lower or "dent" in q_lower or "mark" in q_lower:
            return "Are there any visible scratches, dents, or distinguishing marks?"
        if "sticker" in q_lower or "personal" in q_lower:
            return "Does the device have any stickers or personalization?"

    if cat_upper == "DOCUMENT":
        if "type" in q_lower and "document" in q_lower:
            return "What type of document is it (ID card, passport, certificate, etc.)?"
        if "name" in q_lower:
            return "Whose name appears on the document?"
        if "issuing" in q_lower or "authority" in q_lower or "organization" in q_lower:
            return "What is the issuing authority or organization on the document?"
        if "expiry" in q_lower or "expiration" in q_lower:
            return "What is the approximate date of issue or expiry visible on the document?"

    if cat_upper in {"ACCESSORIES", "CLOTHING", "FOOTWEAR", "JEWELLERY", "OTHERS"}:
        if "color" in q_lower:
            return "What is the color of the item?"
        if "brand" in q_lower or "maker" in q_lower or "manufacturer" in q_lower:
            return "What is the brand or maker of this item?"
        if "material" in q_lower or "leather" in q_lower or "fabric" in q_lower or "metal" in q_lower:
            return "What material is the item made of (leather, fabric, metal, etc.)?"
        if "pattern" in q_lower or "logo" in q_lower or "mark" in q_lower:
            return "Describe any distinctive patterns, logos, or markings on it."
        if "dimension" in q_lower or "size" in q_lower:
            return "What are the approximate dimensions or size of the item?"

    return None


def generate_questions_transformer(
    title: str,
    category: str,
    description: str = "",
    num_candidates: int = 10,
    num_beams: int = 5,
) -> List[str]:
    tokenizer, model, device = _get_t5()
    if tokenizer is None or model is None or device is None:
        return []

    title = (title or "").strip()
    category = (category or "").strip()
    description = (description or "").strip()

    context_parts = []
    if title:
        context_parts.append(title)
    if description:
        context_parts.append(description)

    if not any(p.strip() for p in context_parts):
        return []

    context = " ".join([p.strip() for p in context_parts if p.strip()])
    answers = extract_keywords(f"{title} {description}".strip())[: max(1, min(int(num_candidates), 8))]
    model_name = (os.getenv("QG_T5_MODEL", _DEFAULT_T5_MODEL_NAME) or "").strip().lower()
    uses_highlight_format = "valhalla/" in model_name and ("qg-hl" in model_name or "highlight" in model_name)

    try:
        questions: List[str] = []
        prompts = []
        if answers:
            for ans in answers:
                if uses_highlight_format:
                    prompts.append(f"generate question: <hl> {ans} <hl> {context}")
                else:
                    prompts.append(f"context: {context} answer: {ans}")
        else:
            if uses_highlight_format:
                prompts.append(f"generate question: {context}")
            else:
                prompts.append(f"generate questions: {context}")

        for prompt in prompts:
            inputs = tokenizer(
                prompt,
                return_tensors="pt",
                truncation=True,
                max_length=512,
            )
            inputs = {k: v.to(device) for k, v in inputs.items()}

            with torch.no_grad():
                outputs = model.generate(
                    **inputs,
                    max_length=72,
                    min_length=10,
                    num_beams=num_beams,
                    num_return_sequences=1,
                    early_stopping=True,
                    no_repeat_ngram_size=3,
                    length_penalty=1.1,
                )

            decoded = [tokenizer.decode(o, skip_special_tokens=True) for o in outputs]
            for text in decoded:
                questions.extend(_split_generated_text_into_questions(text))

        return questions
    except Exception:
        debug = os.getenv("QG_DEBUG", "").strip().lower()
        if debug in {"1", "true", "yes", "on"}:
            raise
        return []


def _extract_keywords_spacy(text: str) -> List[str]:
    if not text:
        return []

    nlp = _get_nlp()
    if nlp is None:
        return []

    doc = nlp(text)
    keywords = []
    seen = set()

    for ent in doc.ents:
        if ent.label_ in {"ORG", "PRODUCT"}:
            value = ent.text.strip()
            if value and value not in seen:
                keywords.append(value)
                seen.add(value)

    for token in doc:
        if token.is_stop or token.is_punct or token.is_space:
            continue
        if token.pos_ not in {"NOUN", "PROPN", "ADJ"}:
            continue
        value = token.lemma_.lower().strip()
        if len(value) <= 2:
            continue
        if value not in seen:
            keywords.append(value)
            seen.add(value)

    return keywords


def extract_keywords(text: str) -> List[str]:
    """Extract relevant keywords from text for question generation."""
    if not text:
        return []

    spacy_keywords = _extract_keywords_spacy(text)
    if spacy_keywords:
        return spacy_keywords

    # Normalize
    text_lower = text.lower()

    # Remove common stop words
    stop_words = {
        'a', 'an', 'the', 'is', 'are', 'was', 'were', 'been', 'be',
        'have', 'has', 'had', 'do', 'does', 'did', 'will', 'would',
        'could', 'should', 'may', 'might', 'shall', 'can', 'need',
        'dare', 'ought', 'used', 'to', 'of', 'in', 'for', 'on',
        'with', 'at', 'by', 'from', 'up', 'about', 'into', 'through',
        'during', 'before', 'after', 'above', 'below', 'between',
        'out', 'off', 'over', 'under', 'again', 'further', 'then',
        'once', 'here', 'there', 'when', 'where', 'why', 'how',
        'all', 'each', 'every', 'both', 'few', 'more', 'most',
        'other', 'some', 'such', 'no', 'nor', 'not', 'only',
        'own', 'same', 'so', 'than', 'too', 'very', 'just',
        'i', 'me', 'my', 'myself', 'we', 'our', 'it', 'its',
        'lost', 'found', 'item', 'near', 'around', 'and', 'or',
        'but', 'if', 'while', 'as', 'this', 'that', 'these', 'those',
    }

    # Tokenize
    words = re.findall(r'\b[a-z]+\b', text_lower)

    # Filter and return unique keywords
    keywords = []
    seen = set()
    for word in words:
        if word not in stop_words and len(word) > 2 and word not in seen:
            keywords.append(word)
            seen.add(word)

    return keywords


def generate_questions(title: str, category: str, description: str = "",
                       num_questions: int = 5) -> List[Dict[str, str]]:
    """
    Generate verification questions based on item details.

    Args:
        title: Item title
        category: Item category (ELECTRONIC, DOCUMENT, etc.)
        description: Item description (admin-only, used for question generation)
        num_questions: Number of questions to generate

    Returns:
        List of question dictionaries with 'question' and 'type' keys
    """
    questions: List[Dict[str, str]] = []
    used_questions = set()
    max_total_candidates = max(num_questions * 4, num_questions + 12)

    def add_question(q: str, q_type: str):
        if q not in used_questions and len(questions) < max_total_candidates:
            questions.append({"question": q, "type": q_type})
            used_questions.add(q)

    # 1. Add universal questions first (always include at least 1)
    universal = random.sample(UNIVERSAL_QUESTIONS, min(2, len(UNIVERSAL_QUESTIONS)))
    for q in universal:
        add_question(q, "universal")

    # 2. Extract keywords from title and description
    title_keywords = extract_keywords(title)
    desc_keywords = extract_keywords(description) if description else []
    all_keywords = title_keywords + desc_keywords

    # 2.5 Transformer-based questions (optional, auto-fallback if unavailable)
    use_transformer = os.getenv("QG_USE_TRANSFORMER", "false").strip().lower()
    if use_transformer not in {"0", "false", "no", "off"}:
        transformer_candidates = generate_questions_transformer(
            title=title,
            category=category,
            description=description,
            num_candidates=max(8, min(16, num_questions * 3)),
            num_beams=5,
        )
        transformer_filtered = filter_questions(
            transformer_candidates,
            required_keywords=None,
        )
        transformer_hint_filtered = _filter_transformer_questions(
            transformer_filtered,
            category=category,
            title_keywords=title_keywords,
        )
        if transformer_hint_filtered:
            transformer_filtered = transformer_hint_filtered
        debug = os.getenv("QG_DEBUG", "").strip().lower()
        if debug in {"1", "true", "yes", "on"} and transformer_candidates and not transformer_filtered:
            print(f"[QG] transformer_candidates={len(transformer_candidates)} filtered=0 category={category} title='{title}'")
        for q in transformer_filtered:
            rewritten = _rewrite_transformer_question(q, category=category)
            add_question(rewritten or q, "transformer")

    # 3. Generate keyword-based questions
    for keyword in all_keywords:
        if keyword in KEYWORD_QUESTION_MAP:
            add_question(KEYWORD_QUESTION_MAP[keyword], "keyword")

    # 4. Add category-specific questions
    cat_upper = category.upper() if category else "OTHERS"
    category_qs = CATEGORY_QUESTIONS.get(cat_upper, CATEGORY_QUESTIONS["OTHERS"])

    # Shuffle to vary which category questions are picked
    shuffled_cat_qs = random.sample(category_qs, len(category_qs))
    for q in shuffled_cat_qs:
        add_question(q, "category")

    # 5. Generate questions from title keywords (if we still need more)
    for keyword in title_keywords[:3]:
        if keyword not in KEYWORD_QUESTION_MAP:
            template = random.choice(TITLE_TEMPLATES)
            q = template.format(keyword=keyword)
            add_question(q, "title_keyword")

    # 6. If description has distinguishing details, ask about them
    if description:
        # Extract potential descriptive attributes
        color_words = re.findall(
            r'\b(red|blue|green|yellow|black|white|grey|gray|brown|pink|purple|orange|silver|gold)\b',
            description.lower()
        )
        if color_words:
            add_question(
                "What is the exact color or color combination of the item?",
                "description_derived"
            )

        brand_pattern = re.findall(r'\b[A-Z][a-z]+(?:\s[A-Z][a-z]+)*\b', description)
        if brand_pattern:
            add_question(
                "Can you name the brand or manufacturer of the item?",
                "description_derived"
            )

    # Select final questions (ensure variety)
    # Prioritize: 1 universal + transformer + keyword-based + category-based
    final_questions = []
    by_type = {}
    for q in questions:
        by_type.setdefault(q["type"], []).append(q)

    # Always include 1 universal
    if "universal" in by_type:
        final_questions.append(by_type["universal"][0])

    # Add transformer-based (up to 3)
    if "transformer" in by_type:
        for q in by_type["transformer"][:3]:
            if len(final_questions) < num_questions:
                final_questions.append(q)

    # Add keyword-based (up to 2)
    if "keyword" in by_type:
        for q in by_type["keyword"][:2]:
            if len(final_questions) < num_questions:
                final_questions.append(q)

    # Add description-derived (up to 1)
    if "description_derived" in by_type:
        for q in by_type["description_derived"][:1]:
            if len(final_questions) < num_questions:
                final_questions.append(q)

    # Fill rest with category questions
    if "category" in by_type:
        for q in by_type["category"]:
            if len(final_questions) < num_questions:
                final_questions.append(q)

    # Fill any remaining with title keyword questions
    if "title_keyword" in by_type:
        for q in by_type["title_keyword"]:
            if len(final_questions) < num_questions:
                final_questions.append(q)

    # Add remaining universals if still short
    if "universal" in by_type:
        for q in by_type["universal"][1:]:
            if len(final_questions) < num_questions:
                final_questions.append(q)

    return final_questions[:num_questions]




