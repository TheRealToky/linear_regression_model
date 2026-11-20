# power_draw_regression

## API

Public endpoint (Swagger UI): https://power-draw-api.onrender.com/docs

The free Render plan sleeps when idle, so the first request can take about a minute.

## Mobile app

A one-page Flutter app in `summative/FlutterApp/`. It has one text field per model
input, sends them to `POST /predict` on the API above, and shows the predicted
power draw or a readable error for missing, wrong-type or out-of-range values.

### Run it

1. Install [Flutter](https://docs.flutter.dev/get-started/install) and Android Studio.
2. Start an Android emulator (Android Studio → Device Manager), or plug in a phone
   with USB debugging on.
3. From the repo root:

   ```bash
   cd summative/FlutterApp
   flutter pub get
   flutter run
   ```

The first Android build downloads Gradle dependencies and can take several minutes.
