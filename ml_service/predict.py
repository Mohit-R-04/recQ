



# import tensorflow as tf
# import numpy as np
# import os
# import glob
# from tensorflow.keras.preprocessing import image

# # ======================================================
# # CONFIG
# # ======================================================
# # Get the directory where this script is located
# SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
# MODEL_PATH = os.path.join(SCRIPT_DIR, "models", "lost_and_found_classifier8.keras")
# CLASS_NAMES_PATH = os.path.join(SCRIPT_DIR, "class_names.txt")
# IMG_SIZE = (224, 224)

# CONF_THRESHOLD = 0.65     # confidence threshold
# MARGIN_THRESHOLD = 0.20   # margin between top-1 and top-2

# # ======================================================
# # LOAD MODEL (INFERENCE MODE)
# # ======================================================
# model = tf.keras.models.load_model(
#     MODEL_PATH  
# )

# with open(CLASS_NAMES_PATH) as f:
#     class_names = [line.strip() for line in f]

# print("Model loaded successfully")
# print("Classes:", class_names)

# # ======================================================
# # IMAGE PREPROCESSING
# # ======================================================
# def preprocess(img_path):
#     img = image.load_img(img_path, target_size=IMG_SIZE)
#     img = image.img_to_array(img)
#     img = tf.keras.applications.mobilenet_v2.preprocess_input(img)
#     return np.expand_dims(img, axis=0)

# # ======================================================
# # PREDICTION FUNCTION
# # ======================================================
# def predict_image(img_path):
#     x = preprocess(img_path)
#     preds = model.predict(x, verbose=0)[0]

#     # Print class probabilities
#     print("\nClass probabilities:")
#     for i, p in enumerate(preds):
#         print(f"{class_names[i]:15s} : {p:.4f}")

#     # Top-2 predictions
#     top2 = np.argsort(preds)[-2:]
#     top1_idx = top2[1]
#     top2_idx = top2[0]

#     top1_score = preds[top1_idx]
#     top2_score = preds[top2_idx]

#     # Open-set decision
#     if top1_score < CONF_THRESHOLD or (top1_score - top2_score) < MARGIN_THRESHOLD:
#         return "Other", top1_score

#     return class_names[top1_idx], top1_score

# # ======================================================
# # MAIN
# # ======================================================
# if __name__ == "__main__":

#     test_images_dir = "test_images"

#     if not os.path.exists(test_images_dir):
#         print(f"Directory '{test_images_dir}' not found!")
#         exit(1)

#     image_extensions = [
#         "*.jpg", "*.jpeg", "*.png", "*.webp",
#         "*.bmp", "*.tiff", "*.tif"
#     ]

#     image_files = []
#     for ext in image_extensions:
#         image_files.extend(glob.glob(os.path.join(test_images_dir, ext)))

#     if not image_files:
#         print("No images found!")
#         exit(1)

#     print(f"\nFound {len(image_files)} images")
#     print("=" * 60)

#     for img_path in sorted(image_files):
#         print(f"\nProcessing: {os.path.basename(img_path)}")
#         print("-" * 40)

#         try:
#             label, conf = predict_image(img_path)

#             print("\nFinal Prediction")
#             print("----------------")
#             print(f"Image     : {os.path.basename(img_path)}")
#             print(f"Predicted : {label}")
#             print(f"Confidence: {conf:.2f}")

#         except Exception as e:
#             print(f"Error: {str(e)}")

#         print("=" * 60)


# import tensorflow as tf
# import numpy as np
# import sys
# import os
# from tensorflow.keras.preprocessing import image

# # -------------------------
# # CONFIG
# # -------------------------
# MODEL_PATH = "lost_and_found_classifier1.keras"
# IMG_SIZE = (224, 224)
# CONFIDENCE_THRESHOLD = 0.45  # important for Other class

# # -------------------------
# # LOAD MODEL
# # -------------------------
# model = tf.keras.models.load_model(MODEL_PATH)

# # IMPORTANT:
# # class_names must match training order exactly
# with open("class_names.txt") as f:
#     class_names = [line.strip() for line in f]


# print("Model loaded")
# print("Classes:", class_names)

# # -------------------------
# # IMAGE PREPROCESS
# # -------------------------
# def load_and_preprocess(img_path):
#     img = image.load_img(img_path, target_size=IMG_SIZE)
#     img_array = image.img_to_array(img)
#     img_array = tf.keras.applications.mobilenet_v2.preprocess_input(img_array)
#     img_array = np.expand_dims(img_array, axis=0)
#     return img_array

# # -------------------------
# # PREDICT FUNCTION
# # -------------------------
# def predict_image(img_path):
#     img_tensor = load_and_preprocess(img_path)

#     preds = model.predict(img_tensor)[0]
#     top_idx = np.argmax(preds)
#     confidence = preds[top_idx]

#     for i, p in enumerate(preds):
#         print(f"{class_names[i]:15s} : {p:.4f}")

#     if confidence < CONFIDENCE_THRESHOLD:
#         return "Other", confidence, preds

#     return class_names[top_idx], confidence, preds

# # -------------------------
# # MAIN
# # -------------------------
# if __name__ == "__main__":

#     # if len(sys.argv) != 2:
#     #     print("Usage: python predict.py <image_path>")
#     #     sys.exit(1)

#     # img_path = sys.argv[1]

#     # if not os.path.exists(img_path):
#     #     print("Image not found:", img_path)
#     #     sys.exit(1)
#     img_path= "test4.jpg"

#     label, conf, preds = predict_image(img_path)

#     print("\nPrediction Result")
#     print("-------------------")
#     print(f"Image      : {img_path}")
#     print(f"Predicted  : {label}")
#     print(f"Confidence : {conf:.2f}")
#     print(f"Predictions: {preds}")




import tensorflow as tf
import numpy as np
import os
import glob
from tensorflow.keras.preprocessing import image

# ======================================================
# CONFIG
# ======================================================
MODEL_PATH = "lost_and_found_classifier11.keras"
IMG_SIZE = (224, 224)

CONF_THRESHOLD = 0.65     # confidence threshold
MARGIN_THRESHOLD = 0.20   # margin between top-1 and top-2

# ======================================================
# LOAD MODEL (INFERENCE MODE)
# ======================================================
model = tf.keras.models.load_model(
    MODEL_PATH  
)

with open("class_names1.txt") as f:
    class_names = [line.strip() for line in f]

print("Model loaded successfully")
print("Classes:", class_names)

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

    # Print class probabilities
    print("\nClass probabilities:")
    for i, p in enumerate(preds):
        print(f"{class_names[i]:15s} : {p:.4f}")

    # Top-2 predictions
    top2 = np.argsort(preds)[-2:]
    top1_idx = top2[1]
    top2_idx = top2[0]

    top1_score = preds[top1_idx]
    top2_score = preds[top2_idx]

    # Open-set decision
    if top1_score < CONF_THRESHOLD or (top1_score - top2_score) < MARGIN_THRESHOLD:
        return "Other", top1_score

    return class_names[top1_idx], top1_score

# ======================================================
# MAIN
# ======================================================
if __name__ == "__main__":

    test_images_dir = "test_images"

    if not os.path.exists(test_images_dir):
        print(f"Directory '{test_images_dir}' not found!")
        exit(1)

    image_extensions = [
        "*.jpg", "*.jpeg", "*.png", "*.webp",
        "*.bmp", "*.tiff", "*.tif"
    ]

    image_files = []
    for ext in image_extensions:
        image_files.extend(glob.glob(os.path.join(test_images_dir, ext)))

    if not image_files:
        print("No images found!")
        exit(1)

    print(f"\nFound {len(image_files)} images")
    print("=" * 60)

    for img_path in sorted(image_files):
        print(f"\nProcessing: {os.path.basename(img_path)}")
        print("-" * 40)

        try:
            label, conf = predict_image(img_path)

            print("\nFinal Prediction")
            print("----------------")
            print(f"Image     : {os.path.basename(img_path)}")
            print(f"Predicted : {label}")
            print(f"Confidence: {conf:.2f}")

        except Exception as e:
            print(f"Error: {str(e)}")

        print("=" * 60)
