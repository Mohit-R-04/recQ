# import os

# ROOT = "dataset"

# for split in ["train", "validation", "test"]:
#     print(f"\n{split.upper()}")
#     for cls in os.listdir(os.path.join(ROOT, split)):
#         count = len(os.listdir(os.path.join(ROOT, split, cls)))
#         print(f"{cls}: {count}")


# import os

# ROOT = "dataset"

# for split in ["train", "validation", "test"]:
#     print(f"\n{split.upper()}")
#     split_dir = os.path.join(ROOT, split)

#     for cls in sorted(os.listdir(split_dir)):
#         cls_dir = os.path.join(split_dir, cls)
#         if os.path.isdir(cls_dir):
#             print(f"{cls}: {len(os.listdir(cls_dir))}")

# rebalance_dataset.py
'''
import os, random

MAX_PER_CLASS = 600
SPLITS = ["train", "validation", "test"]

for split in SPLITS:
    base = f"dataset/{split}"
    print(f"\nRebalancing {split}")

    for cls in os.listdir(base):
        cls_path = os.path.join(base, cls)
        if not os.path.isdir(cls_path):
            continue

        images = os.listdir(cls_path)
        if len(images) > MAX_PER_CLASS:
            remove = random.sample(images, len(images) - MAX_PER_CLASS)
            for img in remove:
                os.remove(os.path.join(cls_path, img))

        print(f"{cls:15s} -> {min(len(images), MAX_PER_CLASS)}")

print("\nDataset balanced successfully")
'''

import os

base_dir = "dataset"

for split in ["train", "validation", "test"]:
    print(f"\n {split.upper()}")
    split_dir = os.path.join(base_dir, split)

    if not os.path.exists(split_dir):
        print("   Missing")
        continue

    for cls in sorted(os.listdir(split_dir)):
        cls_path = os.path.join(split_dir, cls)
        if os.path.isdir(cls_path):
            count = len(os.listdir(cls_path))
            print(f"  {cls:15s} : {count}")
