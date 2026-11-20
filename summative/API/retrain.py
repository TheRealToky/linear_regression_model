import copy
from pathlib import Path

import pandas as pd
from sklearn.base import clone

TRAIN_DATA_PATH = Path(__file__).parent / "train_data.csv.gz"
TARGET = "power"

# Original training rows plus every upload since the server started.
# Loaded on the first refit only; lost on restart (accepted on Render's free plan).
train_data = None


def retrain(model, new_rows):
    """Return a model updated with new_rows. The old model is left untouched."""
    global train_data
    X_new, y_new = new_rows.drop(columns=TARGET), new_rows[TARGET]

    # SGDRegressor: keep training the saved model on the new rows only
    if hasattr(model[-1], "partial_fit"):
        updated = copy.deepcopy(model)
        updated[-1].partial_fit(updated[:-1].transform(X_new), y_new)
        return updated

    # Any other model: refit from scratch on the original data plus the new rows
    if train_data is None:
        train_data = pd.read_csv(TRAIN_DATA_PATH, dtype={"altitude": str})
    data = pd.concat([train_data, new_rows], ignore_index=True)
    updated = clone(model).fit(data.drop(columns=TARGET), data[TARGET])
    train_data = data
    return updated
