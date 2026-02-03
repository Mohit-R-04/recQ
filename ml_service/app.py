"""
Flask API for Lost and Found Image Classification
"""
from flask import Flask, request, jsonify
from flask_cors import CORS
import tensorflow as tf
import numpy as np
import os
from tensorflow.keras.preprocessing import image
import tempfile

# ======================================================
# CONFIG
# ======================================================
MODEL_PATH = "lost_and_found_classifier8.keras"
IMG_SIZE = (224, 224)
CONF_THRESHOLD = 0.65
MARGIN_THRESHOLD = 0.20

# Category mapping from ML classes to backend enum
ML_TO_BACKEND_CATEGORY = {
    "Backpack": "ACCESSORIES",
    "Book": "DOCUMENT",
    "Bottle": "OTHERS",
    "Headphones": "ELECTRONIC",
    "Laptop": "ELECTRONIC",
    "Mobile phone": "ELECTRONIC",
    "Watch": "ACCESSORIES",
    "Other": "OTHERS",
}

# ======================================================
# LOAD MODEL
# ======================================================
print("Loading model...")
model = tf.keras.models.load_model(MODEL_PATH)

with open("class_names.txt") as f:
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
    img = tf.keras.applications.mobilenet_v2.preprocess_input(img)
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
# MAIN
# ======================================================
if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
