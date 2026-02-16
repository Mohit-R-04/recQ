"""
Embedding Service for Lost and Found Matching System
Generates image and text embeddings for similarity matching
"""
import numpy as np
from sentence_transformers import SentenceTransformer
import tensorflow as tf
from tensorflow.keras.applications import EfficientNetB0
from tensorflow.keras.preprocessing import image as keras_image
from tensorflow.keras.applications.efficientnet import preprocess_input
import os

# ======================================================
# CONFIG
# ======================================================
IMG_SIZE = (224, 224)
IMAGE_EMBEDDING_DIM = 1280  # EfficientNetB0 output dimension
TEXT_EMBEDDING_DIM = 384    # all-MiniLM-L6-v2 output dimension

# ======================================================
# LOAD MODELS
# ======================================================
print("Loading embedding models...")

# Text embedding model (SBERT)
text_model = SentenceTransformer('all-MiniLM-L6-v2')

# Image embedding model (EfficientNetB0 as feature extractor)
base_model = EfficientNetB0(weights='imagenet', include_top=False, pooling='avg', input_shape=(224, 224, 3))
image_model = tf.keras.Model(inputs=base_model.input, outputs=base_model.output)

print("Embedding models loaded successfully")

# ======================================================
# EMBEDDING FUNCTIONS
# ======================================================

def get_text_embedding(text: str) -> np.ndarray:
    """
    Generate text embedding using SBERT (Sentence-BERT)
    Returns a 384-dimensional vector
    """
    if not text or text.strip() == "":
        return np.zeros(TEXT_EMBEDDING_DIM)
    
    embedding = text_model.encode(text, convert_to_numpy=True)
    return embedding

def get_image_embedding(img_path: str) -> np.ndarray:
    """
    Generate image embedding using EfficientNetB0 as feature extractor
    Returns a 1280-dimensional vector
    """
    if not img_path or not os.path.exists(img_path):
        return np.zeros(IMAGE_EMBEDDING_DIM)
    
    try:
        img = keras_image.load_img(img_path, target_size=IMG_SIZE)
        img_array = keras_image.img_to_array(img)
        img_array = preprocess_input(img_array)
        img_array = np.expand_dims(img_array, axis=0)
        
        embedding = image_model.predict(img_array, verbose=0)[0]
        return embedding
    except Exception as e:
        print(f"Error processing image: {e}")
        return np.zeros(IMAGE_EMBEDDING_DIM)

def get_image_embedding_from_bytes(img_bytes: bytes) -> np.ndarray:
    """
    Generate image embedding from raw bytes
    Returns a 1280-dimensional vector
    """
    import tempfile
    
    try:
        with tempfile.NamedTemporaryFile(delete=False, suffix='.jpg') as tmp:
            tmp.write(img_bytes)
            tmp_path = tmp.name
        
        embedding = get_image_embedding(tmp_path)
        os.unlink(tmp_path)
        return embedding
    except Exception as e:
        print(f"Error processing image bytes: {e}")
        return np.zeros(IMAGE_EMBEDDING_DIM)

# ======================================================
# SIMILARITY FUNCTIONS
# ======================================================

def cosine_similarity(vec1: np.ndarray, vec2: np.ndarray) -> float:
    """
    Calculate cosine similarity between two vectors
    Returns value between 0 and 1
    """
    if np.linalg.norm(vec1) == 0 or np.linalg.norm(vec2) == 0:
        return 0.0
    
    similarity = np.dot(vec1, vec2) / (np.linalg.norm(vec1) * np.linalg.norm(vec2))
    # Normalize to 0-1 range (cosine similarity is -1 to 1)
    return float((similarity + 1) / 2)

def calculate_text_similarity(text1: str, text2: str) -> float:
    """
    Calculate text similarity between two text descriptions
    """
    emb1 = get_text_embedding(text1)
    emb2 = get_text_embedding(text2)
    return cosine_similarity(emb1, emb2)

def calculate_image_similarity(img1_path: str, img2_path: str) -> float:
    """
    Calculate image similarity between two images
    """
    emb1 = get_image_embedding(img1_path)
    emb2 = get_image_embedding(img2_path)
    return cosine_similarity(emb1, emb2)

def calculate_category_match(category1: str, category2: str) -> float:
    """
    Calculate category match score
    Returns 1.0 for exact match, 0.0 otherwise
    """
    if not category1 or not category2:
        return 0.0
    return 1.0 if category1.upper() == category2.upper() else 0.0

# ======================================================
# EMBEDDINGS TO/FROM JSON
# ======================================================

def embedding_to_list(embedding: np.ndarray) -> list:
    """Convert numpy array to list for JSON serialization"""
    return embedding.tolist()

def list_to_embedding(embedding_list: list) -> np.ndarray:
    """Convert list back to numpy array"""
    return np.array(embedding_list)
