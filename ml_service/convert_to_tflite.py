"""
Convert Keras model to TensorFlow Lite format for mobile deployment
"""
import numpy as np
import os
import tempfile
import zipfile
import traceback

os.environ.setdefault("TF_USE_LEGACY_KERAS", "1")

import tensorflow as tf

# ======================================================
# CONFIG
# ======================================================
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
KERAS_MODEL_PATH = os.path.join(SCRIPT_DIR, "models", "lost_and_found_classifier12.keras")
TFLITE_MODEL_PATH = os.path.abspath(
    os.path.join(
        SCRIPT_DIR,
        "..",
        "flutter_app",
        "assets",
        "ml",
        "lost_and_found_classifier12.tflite",
    )
)
LABELS_SOURCE_PATH = os.path.join(SCRIPT_DIR, "class_names2.txt")
LABELS_TARGET_PATH = os.path.abspath(
    os.path.join(SCRIPT_DIR, "..", "flutter_app", "assets", "ml", "class_names2.txt")
)
IMG_SIZE = (224, 224)

# ======================================================
# LOAD KERAS MODEL
# ======================================================
print("Loading Keras model...")
model_load_path = KERAS_MODEL_PATH
packed_model_path = None

try:
    if os.path.isdir(KERAS_MODEL_PATH):
        tmp = tempfile.NamedTemporaryFile(delete=False, suffix=".keras")
        tmp.close()
        packed_model_path = tmp.name
        with zipfile.ZipFile(packed_model_path, "w", compression=zipfile.ZIP_DEFLATED) as zf:
            for root, _, files in os.walk(KERAS_MODEL_PATH):
                for filename in files:
                    file_path = os.path.join(root, filename)
                    arcname = os.path.relpath(file_path, KERAS_MODEL_PATH)
                    zf.write(file_path, arcname)
        model_load_path = packed_model_path

    model = tf.keras.models.load_model(model_load_path, compile=False)
finally:
    if packed_model_path is not None:
        try:
            os.unlink(packed_model_path)
        except Exception:
            pass
print("Model loaded successfully")

# ======================================================
# CONVERT TO TFLITE
# ======================================================
print("\nConverting to TensorFlow Lite...")

# Create converter
converter = tf.lite.TFLiteConverter.from_keras_model(model)

# Optional: Quantization for smaller model size and faster inference
# Uncomment the following lines for quantization:
# converter.optimizations = [tf.lite.Optimize.DEFAULT]
# converter.target_spec.supported_types = [tf.float16]

# Convert
try:
    tflite_model = converter.convert()
except Exception:
    traceback.print_exc()
    raise

# Save
os.makedirs(os.path.dirname(TFLITE_MODEL_PATH), exist_ok=True)
with open(TFLITE_MODEL_PATH, 'wb') as f:
    f.write(tflite_model)

print(f"TFLite model saved to: {TFLITE_MODEL_PATH}")
try:
    print(f"TFLite model size: {os.path.getsize(TFLITE_MODEL_PATH) / 1024 / 1024:.2f} MB")
except Exception:
    pass
print(f"Model size: {len(tflite_model) / 1024 / 1024:.2f} MB")

try:
    os.makedirs(os.path.dirname(LABELS_TARGET_PATH), exist_ok=True)
    with open(LABELS_SOURCE_PATH, "r", encoding="utf-8") as src:
        labels = src.read()
    with open(LABELS_TARGET_PATH, "w", encoding="utf-8") as dst:
        dst.write(labels)
    print(f"Labels saved to: {LABELS_TARGET_PATH}")
except Exception as e:
    print(f"Warning: failed to write labels file: {e}")

# ======================================================
# VERIFY TFLITE MODEL
# ======================================================
print("\nVerifying TFLite model...")

# Load TFLite model
interpreter = tf.lite.Interpreter(model_path=TFLITE_MODEL_PATH)
interpreter.allocate_tensors()

# Get input/output details
input_details = interpreter.get_input_details()
output_details = interpreter.get_output_details()

print(f"Input shape: {input_details[0]['shape']}")
print(f"Input dtype: {input_details[0]['dtype']}")
print(f"Output shape: {output_details[0]['shape']}")
print(f"Output dtype: {output_details[0]['dtype']}")

# Test with random input
test_input = np.random.rand(1, 224, 224, 3).astype(np.float32)
interpreter.set_tensor(input_details[0]['index'], test_input)
interpreter.invoke()
output = interpreter.get_tensor(output_details[0]['index'])
print(f"Test output shape: {output.shape}")
print("TFLite model verification successful!")

print("\n" + "="*50)
print("Next steps:")
print("1. Copy the generated .tflite to Flutter assets/ml/")
print("2. Update assets/ml/class_names.txt to match class_names2.txt order")
print("="*50)
