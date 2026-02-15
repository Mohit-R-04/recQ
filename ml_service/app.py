"""
Flask API for Lost and Found Image Classification and Matching
"""
from flask import Flask, request, jsonify
from flask_cors import CORS
import numpy as np
import os
import tempfile
import zipfile
from typing import Dict
from typing import List

os.environ.setdefault("TF_USE_LEGACY_KERAS", "1")

tf = None
image = None

try:
    from dotenv import load_dotenv
except Exception:
    load_dotenv = None

dotenv_path = os.path.join(os.path.dirname(__file__), ".env")

if load_dotenv is not None:
    load_dotenv(dotenv_path)
else:
    try:
        if os.path.exists(dotenv_path):
            with open(dotenv_path, "r", encoding="utf-8") as f:
                for line in f:
                    line = line.strip()
                    if not line or line.startswith("#"):
                        continue
                    if "=" not in line:
                        continue
                    key, value = line.split("=", 1)
                    key = key.strip()
                    value = value.strip().strip('"').strip("'")
                    if key and key not in os.environ:
                        os.environ[key] = value
    except Exception:
        pass


def _env_enabled(name: str, default: str = "false") -> bool:
    value = os.getenv(name, default).strip().lower()
    return value not in {"0", "false", "no", "off"}


ENABLE_IMAGE_CLASSIFIER = _env_enabled("ML_ENABLE_IMAGE_CLASSIFIER", "false")
ENABLE_EMBEDDINGS = _env_enabled("ML_ENABLE_EMBEDDINGS", "true")
ENABLE_MATCHING = _env_enabled("ML_ENABLE_MATCHING", "true")

_embedding_service = None
_matching_engine = None


def _get_embedding_service():
    global _embedding_service
    if _embedding_service is None:
        import embedding_service as _es
        _embedding_service = _es
    return _embedding_service


def _get_matching_engine():
    global _matching_engine
    if _matching_engine is None:
        import matching_engine as _me
        _matching_engine = _me
    return _matching_engine

# ======================================================
# CONFIG
# ======================================================
MODEL_PATH = os.path.join(os.path.dirname(__file__), "models", "lost_and_found_classifier12.keras")
CLASS_NAMES_PATH = os.path.join(os.path.dirname(__file__), "class_names2.txt")
IMG_SIZE = (224, 224)
CONF_THRESHOLD = 0.65
MARGIN_THRESHOLD = 0.20

# Category mapping from ML classes to backend enum (keys normalized to lowercase)
ML_TO_BACKEND_CATEGORY = {
    "backpack": "ACCESSORIES",
    "book": "DOCUMENT",
    "bottle": "OTHERS",
    "camera": "ELECTRONIC",
    "earrings": "JEWELLERY",
    "footwear": "FOOTWEAR",
    "glasses": "ACCESSORIES",
    "headphones": "ELECTRONIC",
    "laptop": "ELECTRONIC",
    "mobile phone": "ELECTRONIC",
    "necklace": "JEWELLERY",
    "outerwear": "CLOTHING",
    "wallet": "ACCESSORIES",
    "watch": "ACCESSORIES",
}


def map_predicted_class_to_backend_category(predicted_class: str) -> str:
    normalized = (predicted_class or "").strip().lower()
    return ML_TO_BACKEND_CATEGORY.get(normalized, "OTHERS")

# ======================================================
# LOAD MODEL
# ======================================================
model = None
class_names: List[str] = []


def _ensure_classifier_loaded() -> bool:
    global tf, image, model, class_names
    if not ENABLE_IMAGE_CLASSIFIER:
        return False
    if model is not None and class_names:
        return True

    import tensorflow as _tf
    from tensorflow.keras.preprocessing import image as _image

    tf = _tf
    image = _image

    print("Loading model...")
    model_load_path = MODEL_PATH
    packed_model_path = None
    try:
        if os.path.isdir(MODEL_PATH):
            tmp = tempfile.NamedTemporaryFile(delete=False, suffix=".keras")
            tmp.close()
            packed_model_path = tmp.name
            with zipfile.ZipFile(packed_model_path, "w", compression=zipfile.ZIP_DEFLATED) as zf:
                for root, _, files in os.walk(MODEL_PATH):
                    for filename in files:
                        file_path = os.path.join(root, filename)
                        arcname = os.path.relpath(file_path, MODEL_PATH)
                        zf.write(file_path, arcname)
            model_load_path = packed_model_path

        model = tf.keras.models.load_model(model_load_path, compile=False)
        model.compile(
            optimizer='adam',
            loss='sparse_categorical_crossentropy',
            metrics=['accuracy']
        )
    except Exception as e:
        print(f"Error loading model with tf.keras: {e}")
        print("Trying alternative loading method...")
        import keras
        model = keras.models.load_model(model_load_path, compile=False)
        model.compile(
            optimizer='adam',
            loss='sparse_categorical_crossentropy',
            metrics=['accuracy']
        )
    finally:
        if packed_model_path is not None:
            try:
                os.unlink(packed_model_path)
            except Exception:
                pass

    with open(CLASS_NAMES_PATH) as f:
        class_names = [line.strip() for line in f]

    print("Model loaded successfully")
    print("Classes:", class_names)
    return True

# ======================================================
# FLASK APP
# ======================================================
app = Flask(__name__)
CORS(app)  # Enable CORS for Flutter app

# ======================================================
# IMAGE PREPROCESSING
# ======================================================
def preprocess(img_path):
    _ensure_classifier_loaded()
    img = image.load_img(img_path, target_size=IMG_SIZE)
    img = image.img_to_array(img)
    img = tf.keras.applications.efficientnet.preprocess_input(img)
    return np.expand_dims(img, axis=0)

# ======================================================
# PREDICTION FUNCTION
# ======================================================
def predict_image(img_path):
    _ensure_classifier_loaded()
    x = preprocess(img_path)
    preds = model.predict(x, verbose=0)[0]

    # Get all class probabilities
    class_probs = {class_names[i]: float(preds[i]) for i in range(len(class_names))}

    # Top-2 predictions
    top2 = np.argsort(preds)[-2:]
    top1_idx = top2[1]
    top2_idx = top2[0]

    top1_score = float(preds[top1_idx])
    top2_score = float(preds[top2_idx])

    # Open-set decision
    if top1_score < CONF_THRESHOLD or (top1_score - top2_score) < MARGIN_THRESHOLD:
        return "Other", top1_score, class_probs

    return class_names[top1_idx], top1_score, class_probs

# ======================================================
# API ENDPOINTS
# ======================================================
@app.route('/health', methods=['GET'])
def health():
    return jsonify({
        'status': 'healthy',
        'imageClassifierEnabled': ENABLE_IMAGE_CLASSIFIER,
        'embeddingsEnabled': ENABLE_EMBEDDINGS,
        'matchingEnabled': ENABLE_MATCHING,
        'model': MODEL_PATH if ENABLE_IMAGE_CLASSIFIER else None,
        'classes': class_names if ENABLE_IMAGE_CLASSIFIER else []
    })

@app.route('/classify', methods=['POST'])
def classify():
    if not ENABLE_IMAGE_CLASSIFIER:
        return jsonify({'success': False, 'message': 'Image classifier disabled'}), 503
    if 'image' not in request.files:
        return jsonify({
            'success': False,
            'message': 'No image file provided'
        }), 400

    file = request.files['image']
    
    if file.filename == '':
        return jsonify({
            'success': False,
            'message': 'No image selected'
        }), 400

    try:
        # Save to temporary file
        with tempfile.NamedTemporaryFile(delete=False, suffix='.jpg') as tmp:
            file.save(tmp.name)
            tmp_path = tmp.name

        # Predict
        predicted_class, confidence, all_probs = predict_image(tmp_path)
        
        # Clean up temp file
        os.unlink(tmp_path)

        # Map to backend category
        backend_category = map_predicted_class_to_backend_category(predicted_class)

        return jsonify({
            'success': True,
            'predictedClass': predicted_class,
            'confidence': confidence,
            'backendCategory': backend_category,
            'allProbabilities': all_probs
        })

    except Exception as e:
        return jsonify({
            'success': False,
            'message': str(e)
        }), 500

@app.route('/categories', methods=['GET'])
def get_categories():
    if not ENABLE_IMAGE_CLASSIFIER:
        return jsonify({'success': False, 'message': 'Image classifier disabled'}), 503
    return jsonify({
        'mlClasses': class_names,
        'categoryMapping': ML_TO_BACKEND_CATEGORY
    })

# ======================================================
# EMBEDDING ENDPOINTS
# ======================================================

@app.route('/embeddings/text', methods=['POST'])
def generate_text_embedding():
    """Generate text embedding for a given text"""
    try:
        if not ENABLE_EMBEDDINGS:
            return jsonify({'success': False, 'message': 'Embeddings disabled'}), 503
        data = request.get_json()
        text = data.get('text', '')
        
        embedding = _get_embedding_service().get_text_embedding(text)
        
        return jsonify({
            'success': True,
            'embedding': _get_embedding_service().embedding_to_list(embedding),
            'dimension': _get_embedding_service().TEXT_EMBEDDING_DIM
        })
    except Exception as e:
        return jsonify({
            'success': False,
            'message': str(e)
        }), 500

@app.route('/embeddings/image', methods=['POST'])
def generate_image_embedding():
    """Generate image embedding for an uploaded image"""
    try:
        if not ENABLE_EMBEDDINGS:
            return jsonify({'success': False, 'message': 'Embeddings disabled'}), 503
        if 'image' not in request.files:
            return jsonify({
                'success': False,
                'message': 'No image file provided'
            }), 400
        
        file = request.files['image']
        
        if file.filename == '':
            return jsonify({
                'success': False,
                'message': 'No image selected'
            }), 400
        
        # Read image bytes and generate embedding
        img_bytes = file.read()
        embedding = _get_embedding_service().get_image_embedding_from_bytes(img_bytes)
        
        return jsonify({
            'success': True,
            'embedding': _get_embedding_service().embedding_to_list(embedding),
            'dimension': _get_embedding_service().IMAGE_EMBEDDING_DIM
        })
    except Exception as e:
        return jsonify({
            'success': False,
            'message': str(e)
        }), 500

@app.route('/embeddings/item', methods=['POST'])
def generate_item_embeddings():
    """Generate all embeddings for an item (text + optional image)"""
    try:
        if not ENABLE_EMBEDDINGS:
            return jsonify({'success': False, 'message': 'Embeddings disabled'}), 503
        # Handle multipart form data
        item_id = request.form.get('itemId', '')
        item_type = request.form.get('itemType', 'LOST')
        title = request.form.get('title', '')
        description = request.form.get('description', '')
        category = request.form.get('category', 'OTHERS')
        user_id = request.form.get('userId', '')
        
        # Generate text embedding
        combined_text = f"{title}. {description}" if description else title
        text_embedding = _get_embedding_service().get_text_embedding(combined_text)
        
        # Generate image embedding if provided
        has_image = False
        image_embedding = None
        
        if 'image' in request.files:
            file = request.files['image']
            if file.filename != '':
                img_bytes = file.read()
                image_embedding = _get_embedding_service().get_image_embedding_from_bytes(img_bytes)
                has_image = True
        
        return jsonify({
            'success': True,
            'itemId': item_id,
            'itemType': item_type,
            'category': category,
            'userId': user_id,
            'textEmbedding': _get_embedding_service().embedding_to_list(text_embedding),
            'imageEmbedding': _get_embedding_service().embedding_to_list(image_embedding) if has_image else None,
            'hasImage': has_image
        })
    except Exception as e:
        return jsonify({
            'success': False,
            'message': str(e)
        }), 500

# ======================================================
# MATCHING ENDPOINTS
# ======================================================

# In-memory storage for item embeddings (for demo - should use database in production)
item_embeddings_store: Dict[str, object] = {}

@app.route('/matching/register', methods=['POST'])
def register_item_for_matching():
    """Register an item's embeddings for matching"""
    try:
        if not ENABLE_MATCHING:
            return jsonify({'success': False, 'message': 'Matching disabled'}), 503
        me = _get_matching_engine()
        es = _get_embedding_service()
        data = request.get_json()
        
        item_id = data.get('itemId')
        item_type = data.get('itemType')
        title = data.get('title', '')
        description = data.get('description', '')
        category = data.get('category', 'OTHERS')
        user_id = data.get('userId', '')
        
        # Check if embeddings are pre-computed
        if 'textEmbedding' in data and data['textEmbedding']:
            text_emb = es.list_to_embedding(data['textEmbedding'])
            has_image = data.get('hasImage', False)
            image_emb = es.list_to_embedding(data['imageEmbedding']) if has_image and data.get('imageEmbedding') else np.zeros(es.IMAGE_EMBEDDING_DIM)
            
            item = me.ItemEmbeddings(
                item_id=item_id,
                item_type=item_type,
                category=category,
                text_embedding=text_emb,
                image_embedding=image_emb,
                has_image=has_image,
                title=title,
                description=description,
                user_id=user_id
            )
        else:
            # Generate embeddings from text
            combined_text = f"{title}. {description}" if description else title
            text_emb = es.get_text_embedding(combined_text)
            
            item = me.ItemEmbeddings(
                item_id=item_id,
                item_type=item_type,
                category=category,
                text_embedding=text_emb,
                image_embedding=np.zeros(es.IMAGE_EMBEDDING_DIM),
                has_image=False,
                title=title,
                description=description,
                user_id=user_id
            )
        
        # Store embeddings
        item_embeddings_store[item_id] = item
        
        return jsonify({
            'success': True,
            'message': f'Item {item_id} registered for matching',
            'itemId': item_id
        })
    except Exception as e:
        return jsonify({
            'success': False,
            'message': str(e)
        }), 500

@app.route('/matching/find', methods=['POST'])
def find_matches():
    """Find matches for a specific item"""
    try:
        if not ENABLE_MATCHING:
            return jsonify({'success': False, 'message': 'Matching disabled'}), 503
        me = _get_matching_engine()
        data = request.get_json()
        item_id = data.get('itemId')
        top_k = data.get('topK', me.TOP_K_MATCHES)
        
        if item_id not in item_embeddings_store:
            return jsonify({
                'success': False,
                'message': f'Item {item_id} not found in matching store'
            }), 404
        
        target_item = item_embeddings_store[item_id]
        existing_items = list(item_embeddings_store.values())
        
        matches = me.find_matches_for_item(target_item, existing_items, top_k)
        
        return jsonify({
            'success': True,
            'itemId': item_id,
            'itemType': target_item.item_type,
            'matchCount': len(matches),
            'matches': [m.to_dict() for m in matches]
        })
    except Exception as e:
        return jsonify({
            'success': False,
            'message': str(e)
        }), 500

@app.route('/matching/compare', methods=['POST'])
def compare_two_items():
    """Compare two specific items and get their match score"""
    try:
        if not ENABLE_MATCHING:
            return jsonify({'success': False, 'message': 'Matching disabled'}), 503
        me = _get_matching_engine()
        data = request.get_json()
        lost_item_id = data.get('lostItemId')
        found_item_id = data.get('foundItemId')
        
        if lost_item_id not in item_embeddings_store:
            return jsonify({
                'success': False,
                'message': f'Lost item {lost_item_id} not found'
            }), 404
        
        if found_item_id not in item_embeddings_store:
            return jsonify({
                'success': False,
                'message': f'Found item {found_item_id} not found'
            }), 404
        
        lost_item = item_embeddings_store[lost_item_id]
        found_item = item_embeddings_store[found_item_id]
        
        result = me.calculate_match_score(lost_item, found_item)
        
        return jsonify({
            'success': True,
            'match': result.to_dict()
        })
    except Exception as e:
        return jsonify({
            'success': False,
            'message': str(e)
        }), 500

@app.route('/matching/all', methods=['GET'])
def get_all_matches():
    """Get all potential matches between lost and found items"""
    try:
        if not ENABLE_MATCHING:
            return jsonify({'success': False, 'message': 'Matching disabled'}), 503
        me = _get_matching_engine()
        top_k = request.args.get('topK', me.TOP_K_MATCHES, type=int)
        threshold = request.args.get('threshold', me.MATCH_THRESHOLD, type=float)
        
        items = list(item_embeddings_store.values())
        matches = me.batch_find_all_matches(items, top_k)
        
        # Filter by threshold
        matches = [m for m in matches if m.confidence_score >= threshold]
        
        return jsonify({
            'success': True,
            'totalItems': len(items),
            'lostCount': len([i for i in items if i.item_type == 'LOST']),
            'foundCount': len([i for i in items if i.item_type == 'FOUND']),
            'matchCount': len(matches),
            'matches': [m.to_dict() for m in matches]
        })
    except Exception as e:
        return jsonify({
            'success': False,
            'message': str(e)
        }), 500

@app.route('/matching/unregister/<item_id>', methods=['DELETE'])
def unregister_item(item_id):
    """Remove an item from the matching store"""
    try:
        if not ENABLE_MATCHING:
            return jsonify({'success': False, 'message': 'Matching disabled'}), 503
        if item_id in item_embeddings_store:
            del item_embeddings_store[item_id]
            return jsonify({
                'success': True,
                'message': f'Item {item_id} removed from matching store'
            })
        else:
            return jsonify({
                'success': False,
                'message': f'Item {item_id} not found'
            }), 404
    except Exception as e:
        return jsonify({
            'success': False,
            'message': str(e)
        }), 500

@app.route('/matching/stats', methods=['GET'])
def get_matching_stats():
    """Get statistics about the matching store"""
    try:
        if not ENABLE_MATCHING:
            return jsonify({'success': False, 'message': 'Matching disabled'}), 503
        me = _get_matching_engine()
        items = list(item_embeddings_store.values())
        lost_count = len([i for i in items if i.item_type == 'LOST'])
        found_count = len([i for i in items if i.item_type == 'FOUND'])
        
        return jsonify({
            'success': True,
            'totalItems': len(items),
            'lostCount': lost_count,
            'foundCount': found_count,
            'threshold': me.MATCH_THRESHOLD,
            'topK': me.TOP_K_MATCHES
        })
    except Exception as e:
        return jsonify({
            'success': False,
            'message': str(e)
        }), 500

# ======================================================
# QUESTION GENERATION ENDPOINTS
# ======================================================

from question_generator import generate_questions, extract_keywords

@app.route('/generate-questions', methods=['POST'])
def generate_verification_questions():
    """Generate NLP-based verification questions for an item claim."""
    try:
        data = request.get_json()
        title = data.get('title', '')
        category = data.get('category', 'OTHERS')
        description = data.get('description', '')
        num_questions = data.get('numQuestions', 5)

        questions = generate_questions(
            title=title,
            category=category,
            description=description,
            num_questions=num_questions
        )

        use_transformer = os.getenv("QG_USE_TRANSFORMER", "false").strip().lower()
        transformer_enabled = use_transformer not in {"0", "false", "no", "off"}
        transformer_used = any(q.get("type") == "transformer" for q in questions)
        print(f"[QG] transformer_enabled={transformer_enabled} transformer_used={transformer_used}")

        return jsonify({
            'success': True,
            'questions': questions,
            'count': len(questions),
            'keywords': extract_keywords(title + ' ' + description),
            'transformerEnabled': transformer_enabled,
            'transformerUsed': transformer_used
        })
    except Exception as e:
        return jsonify({
            'success': False,
            'message': str(e)
        }), 500

# ======================================================
# MAIN
# ======================================================
if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)

