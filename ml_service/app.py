"""
Flask API for Lost and Found Image Classification and Matching
"""
from flask import Flask, request, jsonify
from flask_cors import CORS
import tensorflow as tf
import numpy as np
import os
from tensorflow.keras.preprocessing import image
import tempfile
from typing import List, Dict

# Import embedding and matching services
from embedding_service import (
    get_text_embedding,
    get_image_embedding,
    get_image_embedding_from_bytes,
    embedding_to_list,
    list_to_embedding,
    IMAGE_EMBEDDING_DIM,
    TEXT_EMBEDDING_DIM
)
from matching_engine import (
    ItemEmbeddings,
    MatchResult,
    create_item_embeddings,
    find_matches_for_item,
    batch_find_all_matches,
    calculate_match_score,
    MATCH_THRESHOLD,
    TOP_K_MATCHES
)

# ======================================================
# CONFIG
# ======================================================
MODEL_PATH = os.path.join(os.path.dirname(__file__), "models", "lost_and_found_classifier11.keras")
CLASS_NAMES_PATH = os.path.join(os.path.dirname(__file__), "class_names1.txt")
IMG_SIZE = (224, 224)
CONF_THRESHOLD = 0.65
MARGIN_THRESHOLD = 0.20

# Category mapping from ML classes to backend enum
ML_TO_BACKEND_CATEGORY = {
    "backpack": "ACCESSORIES",
    "bottle": "OTHERS",
    "headphone": "ELECTRONIC",
    "laptop": "ELECTRONIC",
    "mobile phone": "ELECTRONIC",
    "wallet": "ACCESSORIES",
    "watch": "ACCESSORIES",
    "other": "OTHERS",
}

# ======================================================
# LOAD MODEL
# ======================================================
print("Loading model...")
try:
    # Try loading with compile=False to avoid optimizer compatibility issues
    model = tf.keras.models.load_model(MODEL_PATH, compile=False)
    # Recompile with compatible settings
    model.compile(
        optimizer='adam',
        loss='sparse_categorical_crossentropy',
        metrics=['accuracy']
    )
except Exception as e:
    print(f"Error loading model with tf.keras: {e}")
    print("Trying alternative loading method...")
    # Fallback: try loading without custom objects
    import keras
    model = keras.models.load_model(MODEL_PATH, compile=False)
    model.compile(
        optimizer='adam',
        loss='sparse_categorical_crossentropy',
        metrics=['accuracy']
    )

with open(CLASS_NAMES_PATH) as f:
    class_names = [line.strip() for line in f]

print("Model loaded successfully")
print("Classes:", class_names)

# ======================================================
# FLASK APP
# ======================================================
app = Flask(__name__)
CORS(app)  # Enable CORS for Flutter app

# ======================================================
# IMAGE PREPROCESSING
# ======================================================
def preprocess(img_path):
    img = image.load_img(img_path, target_size=IMG_SIZE)
    img = image.img_to_array(img)
    img = tf.keras.applications.efficientnet.preprocess_input(img)
    return np.expand_dims(img, axis=0)

# ======================================================
# PREDICTION FUNCTION
# ======================================================
def predict_image(img_path):
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
        'model': MODEL_PATH,
        'classes': class_names
    })

@app.route('/classify', methods=['POST'])
def classify():
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
        backend_category = ML_TO_BACKEND_CATEGORY.get(predicted_class, "OTHERS")

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
        data = request.get_json()
        text = data.get('text', '')
        
        embedding = get_text_embedding(text)
        
        return jsonify({
            'success': True,
            'embedding': embedding_to_list(embedding),
            'dimension': TEXT_EMBEDDING_DIM
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
        embedding = get_image_embedding_from_bytes(img_bytes)
        
        return jsonify({
            'success': True,
            'embedding': embedding_to_list(embedding),
            'dimension': IMAGE_EMBEDDING_DIM
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
        # Handle multipart form data
        item_id = request.form.get('itemId', '')
        item_type = request.form.get('itemType', 'LOST')
        title = request.form.get('title', '')
        description = request.form.get('description', '')
        category = request.form.get('category', 'OTHERS')
        user_id = request.form.get('userId', '')
        
        # Generate text embedding
        combined_text = f"{title}. {description}" if description else title
        text_embedding = get_text_embedding(combined_text)
        
        # Generate image embedding if provided
        has_image = False
        image_embedding = None
        
        if 'image' in request.files:
            file = request.files['image']
            if file.filename != '':
                img_bytes = file.read()
                image_embedding = get_image_embedding_from_bytes(img_bytes)
                has_image = True
        
        return jsonify({
            'success': True,
            'itemId': item_id,
            'itemType': item_type,
            'category': category,
            'userId': user_id,
            'textEmbedding': embedding_to_list(text_embedding),
            'imageEmbedding': embedding_to_list(image_embedding) if has_image else None,
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
item_embeddings_store: Dict[str, ItemEmbeddings] = {}

@app.route('/matching/register', methods=['POST'])
def register_item_for_matching():
    """Register an item's embeddings for matching"""
    try:
        data = request.get_json()
        
        item_id = data.get('itemId')
        item_type = data.get('itemType')
        title = data.get('title', '')
        description = data.get('description', '')
        category = data.get('category', 'OTHERS')
        user_id = data.get('userId', '')
        
        # Check if embeddings are pre-computed
        if 'textEmbedding' in data and data['textEmbedding']:
            text_emb = list_to_embedding(data['textEmbedding'])
            has_image = data.get('hasImage', False)
            image_emb = list_to_embedding(data['imageEmbedding']) if has_image and data.get('imageEmbedding') else np.zeros(IMAGE_EMBEDDING_DIM)
            
            item = ItemEmbeddings(
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
            text_emb = get_text_embedding(combined_text)
            
            item = ItemEmbeddings(
                item_id=item_id,
                item_type=item_type,
                category=category,
                text_embedding=text_emb,
                image_embedding=np.zeros(IMAGE_EMBEDDING_DIM),
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
        data = request.get_json()
        item_id = data.get('itemId')
        top_k = data.get('topK', TOP_K_MATCHES)
        
        if item_id not in item_embeddings_store:
            return jsonify({
                'success': False,
                'message': f'Item {item_id} not found in matching store'
            }), 404
        
        target_item = item_embeddings_store[item_id]
        existing_items = list(item_embeddings_store.values())
        
        matches = find_matches_for_item(target_item, existing_items, top_k)
        
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
        
        result = calculate_match_score(lost_item, found_item)
        
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
        top_k = request.args.get('topK', TOP_K_MATCHES, type=int)
        threshold = request.args.get('threshold', MATCH_THRESHOLD, type=float)
        
        items = list(item_embeddings_store.values())
        matches = batch_find_all_matches(items, top_k)
        
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
        items = list(item_embeddings_store.values())
        lost_count = len([i for i in items if i.item_type == 'LOST'])
        found_count = len([i for i in items if i.item_type == 'FOUND'])
        
        return jsonify({
            'success': True,
            'totalItems': len(items),
            'lostCount': lost_count,
            'foundCount': found_count,
            'threshold': MATCH_THRESHOLD,
            'topK': TOP_K_MATCHES
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
