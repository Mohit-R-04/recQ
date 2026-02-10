# import tensorflow as tf
# import os
# from collections import Counter
# from tensorflow.keras import layers, models
# from tensorflow.keras.applications import EfficientNetB0
# import matplotlib.pyplot as plt

# # -------------------------
# # CONFIG
# # -------------------------
# IMG_SIZE = (224, 224)
# BATCH_SIZE = 32
# EPOCHS = 20
# DATASET_DIR = "data/dataset1"
# SEED = 42

# # -------------------------
# # LOAD DATASETS
# # -------------------------
# train_ds = tf.keras.utils.image_dataset_from_directory(
#     os.path.join(DATASET_DIR, "train"),
#     image_size=IMG_SIZE,
#     batch_size=BATCH_SIZE,
#     shuffle=True,
#     seed=SEED,
# )

# val_ds = tf.keras.utils.image_dataset_from_directory(
#     os.path.join(DATASET_DIR, "validation"),
#     image_size=IMG_SIZE,
#     batch_size=BATCH_SIZE,
#     shuffle=False,
# )

# test_ds = tf.keras.utils.image_dataset_from_directory(
#     os.path.join(DATASET_DIR, "test"),
#     image_size=IMG_SIZE,
#     batch_size=BATCH_SIZE,
#     shuffle=False,
# )

# class_names = train_ds.class_names
# num_classes = len(class_names)

# print("\nClasses detected (training order):")
# for i, name in enumerate(class_names):
#     print(f"{i} : {name}")

# # SAVE CLASS ORDER (VERY IMPORTANT)
# with open("class_names.txt", "w") as f:
#     for name in class_names:
#         f.write(name + "\n")

# # -------------------------
# # CLASS WEIGHTS (IMBALANCE FIX)
# # -------------------------
# label_counter = Counter()
# for _, labels in train_ds:
#     label_counter.update(labels.numpy())

# total_samples = sum(label_counter.values())

# class_weight = {
#     cls: total_samples / (num_classes * count)
#     for cls, count in label_counter.items()
# }

# print("\nClass weights:")
# for cls, w in class_weight.items():
#     print(f"{class_names[cls]:15s} : {w:.3f}")

# # -------------------------
# # PERFORMANCE OPTIMIZATION
# # -------------------------
# AUTOTUNE = tf.data.AUTOTUNE
# train_ds = train_ds.prefetch(AUTOTUNE)
# val_ds = val_ds.prefetch(AUTOTUNE)
# test_ds = test_ds.prefetch(AUTOTUNE)

# # -------------------------
# # DATA AUGMENTATION
# # -------------------------
# data_augmentation = models.Sequential([
#     layers.RandomFlip("horizontal"),
#     layers.RandomRotation(0.1),
#     layers.RandomZoom(0.1),
# ])

# # -------------------------
# # MODEL (EfficientNetB0)
# # -------------------------
# base_model = EfficientNetB0(
#     input_shape=IMG_SIZE + (3,),
#     include_top=False,
#     weights="imagenet"
# )

# base_model.trainable = False  # transfer learning stage

# inputs = layers.Input(shape=IMG_SIZE + (3,))
# x = data_augmentation(inputs)
# x = tf.keras.applications.efficientnet.preprocess_input(x)
# x = base_model(x, training=False)
# x = layers.GlobalAveragePooling2D()(x)
# x = layers.BatchNormalization()(x)
# x = layers.Dense(256, activation="relu")(x)
# x = layers.Dropout(0.4)(x)
# outputs = layers.Dense(num_classes, activation="softmax")(x)

# model = models.Model(inputs, outputs)

# # -------------------------
# # COMPILE
# # -------------------------
# model.compile(
#     optimizer=tf.keras.optimizers.Adam(learning_rate=1e-3),
#     loss="sparse_categorical_crossentropy",
#     metrics=["accuracy"],
# )

# model.summary()

# # -------------------------
# # TRAIN
# # -------------------------
# history = model.fit(
#     train_ds,
#     validation_data=val_ds,
#     epochs=EPOCHS,
#     class_weight=class_weight,
# )

# # -------------------------
# # TEST
# # -------------------------
# test_loss, test_acc = model.evaluate(test_ds)
# print(f"\nTest accuracy: {test_acc:.4f}")

# # -------------------------
# # SAVE MODEL
# # -------------------------
# model.save("models/lost_and_found_classifier8.keras")
# print("\nModel saved as lost_and_found_classifier.keras")

# # -------------------------
# # PLOT
# # -------------------------
# plt.figure(figsize=(8, 4))
# plt.plot(history.history["accuracy"], label="Train Accuracy")
# plt.plot(history.history["val_accuracy"], label="Validation Accuracy")
# plt.legend()
# plt.title("Training vs Validation Accuracy")
# plt.xlabel("Epoch")
# plt.ylabel("Accuracy")
# plt.grid()
# plt.show()



import tensorflow as tf
import os
from collections import Counter
from tensorflow.keras import layers, models
from tensorflow.keras.applications import EfficientNetB0
import matplotlib.pyplot as plt

# -------------------------
# CONFIG
# -------------------------
IMG_SIZE = (224, 224)
BATCH_SIZE = 32
EPOCHS = 20
DATASET_DIR = "dataset_new_restructured"
SEED = 42

# -------------------------
# LOAD DATASETS
# -------------------------
train_ds = tf.keras.utils.image_dataset_from_directory(
    os.path.join(DATASET_DIR, "train"),
    image_size=IMG_SIZE,
    batch_size=BATCH_SIZE,
    shuffle=True,
    seed=SEED,
)

val_ds = tf.keras.utils.image_dataset_from_directory(
    os.path.join(DATASET_DIR, "validation"),
    image_size=IMG_SIZE,
    batch_size=BATCH_SIZE,
    shuffle=False,
)

test_ds = tf.keras.utils.image_dataset_from_directory(
    os.path.join(DATASET_DIR, "test"),
    image_size=IMG_SIZE,
    batch_size=BATCH_SIZE,
    shuffle=False,
)

class_names = train_ds.class_names
num_classes = len(class_names)

print("\nClasses detected (training order):")
for i, name in enumerate(class_names):
    print(f"{i} : {name}")

# SAVE CLASS ORDER (VERY IMPORTANT)
with open("class_names1.txt", "w") as f:
    for name in class_names:
        f.write(name + "\n")

# -------------------------
# CLASS WEIGHTS (IMBALANCE FIX)
# -------------------------
label_counter = Counter()
for _, labels in train_ds:
    label_counter.update(labels.numpy())

total_samples = sum(label_counter.values())

class_weight = {
    cls: total_samples / (num_classes * count)
    for cls, count in label_counter.items()
}

print("\nClass weights:")
for cls, w in class_weight.items():
    print(f"{class_names[cls]:15s} : {w:.3f}")

# -------------------------
# PERFORMANCE OPTIMIZATION
# -------------------------
AUTOTUNE = tf.data.AUTOTUNE
train_ds = train_ds.prefetch(AUTOTUNE)
val_ds = val_ds.prefetch(AUTOTUNE)
test_ds = test_ds.prefetch(AUTOTUNE)

# -------------------------
# DATA AUGMENTATION
# -------------------------
data_augmentation = models.Sequential([
    layers.RandomFlip("horizontal"),
    layers.RandomRotation(0.1),
    layers.RandomZoom(0.1),
])

# -------------------------
# MODEL (EfficientNetB0)
# -------------------------
base_model = EfficientNetB0(
    input_shape=IMG_SIZE + (3,),
    include_top=False,
    weights="imagenet"
)

base_model.trainable = False  # transfer learning stage

inputs = layers.Input(shape=IMG_SIZE + (3,))
x = data_augmentation(inputs)
x = tf.keras.applications.efficientnet.preprocess_input(x)
x = base_model(x, training=False)
x = layers.GlobalAveragePooling2D()(x)
x = layers.BatchNormalization()(x)
x = layers.Dense(256, activation="relu")(x)
x = layers.Dropout(0.4)(x)
outputs = layers.Dense(num_classes, activation="softmax")(x)

model = models.Model(inputs, outputs)

# -------------------------
# COMPILE
# -------------------------
model.compile(
    optimizer=tf.keras.optimizers.Adam(learning_rate=1e-3),
    loss="sparse_categorical_crossentropy",
    metrics=["accuracy"],
)

model.summary()

# -------------------------
# TRAIN
# -------------------------
history = model.fit(
    train_ds,
    validation_data=val_ds,
    epochs=EPOCHS,
    class_weight=class_weight,
)

# -------------------------
# TEST
# -------------------------
test_loss, test_acc = model.evaluate(test_ds)
print(f"\nTest accuracy: {test_acc:.4f}")

# -------------------------
# SAVE MODEL
# -------------------------
model.save("lost_and_found_classifier11.keras")
print("\nModel saved as lost_and_found_classifier.keras")

# -------------------------
# PLOT
# -------------------------
plt.figure(figsize=(8, 4))
plt.plot(history.history["accuracy"], label="Train Accuracy")
plt.plot(history.history["val_accuracy"], label="Validation Accuracy")
plt.legend()
plt.title("Training vs Validation Accuracy")
plt.xlabel("Epoch")
plt.ylabel("Accuracy")
plt.grid()
plt.show()
