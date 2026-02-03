"""
Convert Keras model to TensorFlow Lite format for mobile deployment
"""
import tensorflow as tf
import numpy as np

# ======================================================
# CONFIG
# ======================================================
KERAS_MODEL_PATH = "models/lost_and_found_classifier8.keras"
TFLITE_MODEL_PATH = "lost_and_found_classifier.tflite"
IMG_SIZE = (224, 224)

# ======================================================
# LOAD KERAS MODEL
# ======================================================
print("Loading Keras model...")
model = tf.keras.models.load_model(KERAS_MODEL_PATH)
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
tflite_model = converter.convert()

# Save
with open(TFLITE_MODEL_PATH, 'wb') as f:
    f.write(tflite_model)

print(f"TFLite model saved to: {TFLITE_MODEL_PATH}")
print(f"Model size: {len(tflite_model) / 1024 / 1024:.2f} MB")

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
print("1. Copy 'lost_and_found_classifier.tflite' to Flutter assets")
print("2. Copy 'class_names.txt' to Flutter assets")
print("="*50)
