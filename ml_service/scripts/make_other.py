import fiftyone.zoo as foz
import fiftyone as fo
import os

SPLITS = {
    "train": 600,
    "validation": 200,
    "test": 200
}

for split, count in SPLITS.items():
    print(f"Downloading OTHER images for {split}")

    dataset = foz.load_zoo_dataset(
        "imagenet-sample",   # no split here
        max_samples=count,
        shuffle=True
    )

    out_dir = f"dataset/{split}/Other"
    os.makedirs(out_dir, exist_ok=True)

    dataset.export(
        export_dir=out_dir,
        dataset_type=fo.types.ImageDirectory,
        overwrite=True
    )

print("Other class added successfully")
