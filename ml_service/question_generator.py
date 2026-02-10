"""
NLP-based Question Generation Module for Lost & Found Item Verification.

Uses keyword extraction + template-based question generation.
Generates item-specific verification questions based on title, category, and description.
"""

import re
import random
from typing import List, Dict, Optional

try:
    import spacy
except Exception:
    spacy = None


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
    questions = []
    used_questions = set()

    def add_question(q: str, q_type: str):
        if q not in used_questions and len(questions) < num_questions + 2:  # Generate extras to allow selection
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
    # Prioritize: 1 universal + keyword-based + category-based
    final_questions = []
    by_type = {}
    for q in questions:
        by_type.setdefault(q["type"], []).append(q)

    # Always include 1 universal
    if "universal" in by_type:
        final_questions.append(by_type["universal"][0])

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
