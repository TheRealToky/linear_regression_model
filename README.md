# Drone power draw prediction

## Mission and problem

**Mission:** My mission is to solve complex problems through computation, mathematics, and engineering. I aim to model, simulate, automate, and optimize systems across science, technology, and industry.

**Problem:** Delivery drones run out of battery when people misjudge how much power a flight will need. This project predicts a quadcopter's instantaneous power draw (W) from its payload, speed, wind, height and flight phase, so operators can plan routes and battery swaps before take-off.

## Dataset

[Data Collected with Package Delivery Quadcopter Drone](https://doi.org/10.1184/R1/12683453) (Carnegie Mellon University, KiltHub).
209 real package-delivery flights of a DJI Matrice 100 quadcopter, logged at about 5 Hz: roughly 258,000 rows of onboard sensor readings
(wind, battery voltage and current, GPS position, orientation, velocity, acceleration) plus a per-flight table of payload, programmed speed, altitude and route.
The target is power in watts, is battery voltage × current. The model uses 8 numeric and 3 categorical inputs (route, flight phase, planned altitude).

## API

Swagger UI: https://power-draw-api.onrender.com/docs

The free Render plan sleeps when idle, so the first request can take about a minute.

## Video demo

YouTube: 

## Run the mobile app

A one-page Flutter app in `summative/FlutterApp/`. It has one text field per model
input, sends them to `POST /predict` on the API above, and shows the predicted
power draw or a readable error for missing, wrong-type or out-of-range values.

1. Install [Flutter](https://docs.flutter.dev/get-started/install) and Android Studio.
2. Start an Android emulator (Android Studio → Device Manager), or plug in an Android
   phone with USB debugging on.
3. Check that Flutter sees the device:

   ```bash
   flutter devices
   ```

4. From the repo root, install the packages and run the app:

   ```bash
   cd summative/FlutterApp
   flutter pub get
   flutter run
   ```

5. Fill in all 11 fields (each shows its allowed range or values) and tap **Predict**.

The first Android build downloads Gradle dependencies and can take several minutes.
