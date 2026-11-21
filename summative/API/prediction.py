from pathlib import Path
from typing import Literal

import joblib
import pandas as pd
from fastapi import FastAPI, HTTPException, UploadFile
from fastapi.exceptions import RequestValidationError
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, ConfigDict, Field, TypeAdapter, ValidationError

from retrain import retrain

MODEL_PATH = Path(__file__).parent / "best_model.pkl"

app = FastAPI(title="Drone Power Draw API")
model = joblib.load(MODEL_PATH)

# CORS decides which *websites* (browser origins) may call this API. The Flutter
# Android/iOS app is not a browser, so CORS does not apply to it.
# - Allowed origins: the API's own Render site, where Swagger UI runs and the flutter web debug address. No
#   "*" and no other site, so any other website's JavaScript is blocked.
# - Allowed methods: only POST, the method of /predict and /retrain.
# - Allowed headers: only Content-Type, needed to send JSON or a CSV upload.
# - Credentials: off. The API uses no cookies or auth headers, so browsers
#   must not send any.
ALLOWED_ORIGINS = [
    "https://power-draw-api.onrender.com",
    "http://localhost:8080",  # Flutter web debug (flutter run -d chrome --web-port 8080)
]
app.add_middleware(
    CORSMiddleware,
    allow_origins=ALLOWED_ORIGINS,
    allow_methods=["POST"],
    allow_headers=["Content-Type"],
    allow_credentials=False,
)


class FlightInput(BaseModel):
    # strict: "8" (a string) is rejected for a float field instead of being converted
    model_config = ConfigDict(strict=True)

    # Numeric inputs: ranges from the "Final list of inputs" table in the notebook
    payload: float = Field(ge=0, le=750, description="Parcel mass (g)", examples=[250])
    speed: float = Field(ge=0, le=12, description="Programmed cruise speed (m/s)", examples=[8])
    wind_speed: float = Field(ge=0, le=20, description="Wind speed (m/s)", examples=[4.5])
    ground_speed: float = Field(ge=0, le=13, description="Horizontal speed (m/s)", examples=[7.8])
    velocity_z: float = Field(ge=-5, le=6, description="Vertical speed, + is up (m/s)", examples=[0.1])
    tilt_deg: float = Field(ge=0, le=45, description="Tilt from level (degrees)", examples=[8])
    height: float = Field(ge=-15, le=120, description="Height above take-off (m)", examples=[50])
    time: float = Field(ge=0, le=450, description="Seconds since logging started (s)", examples=[120])

    # Categorical inputs: only the labels the model was trained on
    route: Literal["R1", "H", "other"] = Field(examples=["R1"])
    flight_phase: Literal["ground", "climb", "cruise", "hover", "descent"] = Field(examples=["cruise"])
    altitude: Literal["3", "25", "50", "75", "100", "25-50-100-25"] = Field(examples=["50"])


# One CSV row for /retrain: the same inputs plus the measured target
class TrainingRow(FlightInput):
    power: float = Field(ge=-10, le=1100, description="Measured power (W)")


training_rows = TypeAdapter(list[TrainingRow])


@app.post("/predict")
def predict(data: FlightInput):
    row = pd.DataFrame([data.model_dump()])
    power = model.predict(row)[0]
    return {"predicted_power_w": round(float(power), 2)}


@app.post("/retrain")
def retrain_model(file: UploadFile):
    global model
    try:
        df = pd.read_csv(file.file, dtype={"altitude": str})
    except Exception:
        raise HTTPException(400, "The file could not be read as a CSV.")
    if df.empty:
        raise HTTPException(400, "The CSV has no rows.")
    missing = set(TrainingRow.model_fields) - set(df.columns)
    if missing:
        raise HTTPException(422, f"Missing columns: {sorted(missing)}")

    # Same ranges and labels as /predict, on every row. loc = [row number, column].
    # Empty cells become None so they fail as missing values.
    # strict=False: a CSV is all text, so a cell like "4.0" may be read as a number.
    records = df.astype(object).where(df.notna(), None).to_dict("records")
    try:
        rows = training_rows.validate_python(records, strict=False)
    except ValidationError as e:
        raise RequestValidationError(e.errors(include_url=False)[:10])  # first 10 only

    new_rows = pd.DataFrame([r.model_dump() for r in rows])
    model = retrain(model, new_rows)  # swap: the next /predict uses the new model
    return {"message": "Model retrained", "rows_added": len(new_rows)}
