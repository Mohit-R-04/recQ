# # # import fiftyone as fo
# # # import fiftyone.zoo as foz
# # # import os
# # # import shutil

# # # # Open Images class names (VALID ONES)
# # # CLASSES = [
# # #     "Mobile phone",
# # #     "Backpack",
# # #     "Laptop",
# # #     "Bottle",
# # #     "Watch",
# # #     "Headphones"
# # #     # Wallet is NOT a valid Open Images classification → remove
# # # ]

# # # TARGET_ROOT = "dataset"

# # # splits = {
# # #     "train": 300,
# # #     "validation": 80,
# # #     "test": 50
# # # }

# # # for split, samples_per_class in splits.items():
# # #     print(f"\nDownloading {split}...")

# # #     dataset = foz.load_zoo_dataset(
# # #         "open-images-v7",
# # #         split=split,
# # #         label_types=["classifications"],
# # #         classes=CLASSES,
# # #         max_samples=samples_per_class * len(CLASSES),
# # #         shuffle=True
# # #     )

# # #     for cls in CLASSES:
# # #         cls_dir = os.path.join(
# # #             TARGET_ROOT,
# # #             split,
# # #             cls.lower().replace(" ", "_")
# # #         )
# # #         os.makedirs(cls_dir, exist_ok=True)

# # #     for sample in dataset:
# # #         if not sample.classifications:
# # #             continue

# # #         for cls in sample.classifications.classifications:
# # #             label = cls.label
# # #             label_dir = label.lower().replace(" ", "_")

# # #             if label not in CLASSES:
# # #                 continue

# # #             dst = os.path.join(
# # #                 TARGET_ROOT,
# # #                 split,
# # #                 label_dir,
# # #                 os.path.basename(sample.filepath)
# # #             )

# # #             if not os.path.exists(dst):
# # #                 shutil.copy(sample.filepath, dst)

# # #     fo.delete_dataset(dataset.name)

# # # print("\n Open Images download completed successfully!")


# # import fiftyone as fo
# # import fiftyone.zoo as foz
# # import os
# # import shutil

# # CLASSES = [
# #     "Mobile phone",
# #     "Backpack",
# #     "Laptop",
# #     "Bottle",
# #     "Watch",
# #     "Headphones"
# # ]

# # TARGET_ROOT = "dataset"

# # splits = {
# #     "train": 300,
# #     "validation": 80,
# #     "test": 50
# # }

# # for split, samples_per_class in splits.items():
# #     print(f"\nDownloading {split}...")

# #     dataset = foz.load_zoo_dataset(
# #         "open-images-v7",
# #         split=split,
# #         label_types=["classifications"],
# #         classes=CLASSES,
# #         max_samples=samples_per_class * len(CLASSES),
# #         shuffle=True
# #     )

# #     # Create folders
# #     for cls in CLASSES:
# #         os.makedirs(
# #             os.path.join(TARGET_ROOT, split, cls.lower().replace(" ", "_")),
# #             exist_ok=True
# #         )

# #     for sample in dataset:
# #         # SAFETY CHECK (THIS FIXES YOUR ERROR)
# #         if not sample.has_field("classifications"):
# #             continue

# #         classifications = sample.classifications.classifications

# #         for c in classifications:
# #             label = c.label

# #             if label not in CLASSES:
# #                 continue

# #             label_dir = label.lower().replace(" ", "_")

# #             dst = os.path.join(
# #                 TARGET_ROOT,
# #                 split,
# #                 label_dir,
# #                 os.path.basename(sample.filepath)
# #             )

# #             if not os.path.exists(dst):
# #                 shutil.copy(sample.filepath, dst)

# #     fo.delete_dataset(dataset.name)

# # print("\nOpen Images dataset prepared successfully!")


# import fiftyone as fo
# import fiftyone.zoo as foz
# import os

# # -----------------------
# # CONFIG
# # -----------------------
# CLASSES = [
#     "Mobile phone",
#     "Backpack",
#     "Laptop",
#     "Bottle",
#     "Watch",
#     "Headphones"
# ]

# SPLITS = {
#     "train": 2000,
#     "validation": 600,
#     "test": 400
# }

# OUTPUT_ROOT = "dataset"

# # -----------------------
# # MAIN LOGIC
# # -----------------------
# for split, max_samples in SPLITS.items():
#     print(f"\n Processing {split} split")

#     dataset = foz.load_zoo_dataset(
#         "open-images-v7",
#         split=split,
#         label_types=["detections"],
#         classes=CLASSES,
#         max_samples=max_samples,
#         shuffle=True
#     )

#     export_dir = os.path.join(OUTPUT_ROOT, split)
#     os.makedirs(export_dir, exist_ok=True)

#     print(f" Exporting cropped images to: {export_dir}")

#     dataset.export(
#         export_dir=export_dir,
#         dataset_type=fo.types.ImageClassificationDirectoryTree,
#         label_field="detections",
#         classes=CLASSES,
#         overwrite=True
#     )

#     fo.delete_dataset(dataset.name)

# print("\n Open Images → Classification dataset prepared successfully!")


import fiftyone.zoo as foz
import fiftyone as fo
from fiftyone import ViewField as F
import os

TARGET_CLASSES = [
    "Mobile phone",
    "Backpack",
    "Laptop",
    "Bottle",
    "Watch",
    "Headphones",
    "Book"
]

SPLITS = ["train", "validation", "test"]
MAX_SAMPLES = 2000

for split in SPLITS:
    print(f"\n Processing {split} split")

    dataset = foz.load_zoo_dataset(
        "open-images-v7",
        split=split,
        label_types=["detections"],
        classes=TARGET_CLASSES,
        max_samples=MAX_SAMPLES,
        shuffle=True,
    )

    #  FILTER OUT UNWANTED DETECTIONS
    view = dataset.filter_labels(
        "ground_truth",
        F("label").is_in(TARGET_CLASSES)
    )

    export_dir = os.path.join("dataset", split)
    os.makedirs(export_dir, exist_ok=True)

    print(f" Exporting ONLY target classes to: {export_dir}")

    view.export(
        export_dir=export_dir,
        dataset_type=fo.types.ImageClassificationDirectoryTree,
        label_field="ground_truth",
        overwrite=True,
    )

    dataset.delete()  # free RAM

print("\n Clean dataset created (only required classes)")
