# FlowMatic (Flutter + Firebase)

FlowMatic is a **secure IoT-based smart irrigation** monitoring app.

## Features (App)
- Firebase Authentication (Email/Password)
- Real-time device dashboard (Firestore)
- Pump control + mode + threshold settings (Firestore + command logs)
- Historical readings list (Firestore)

## Firestore Structure (recommended)

**Device Doc**
- `devices/device1`
  - `soilMoisture` (0–100)
  - `pumpOn` (bool)
  - `mode` (`AUTO` or `MANUAL`)
  - `thresholdDry` (0–100)
  - `lastUpdated` (timestamp)

**Readings**
- `devices/device1/readings/{autoId}`
  - `soilMoisture` (0–100)
  - `createdAt` (timestamp)

**Commands (device listens here)**
- `devices/device1/commands/{autoId}`
  - `type` (PUMP / MODE / THRESHOLD)
  - `payload` (map)
  - `createdAt` (timestamp)
  - `createdBy` (uid)

## Run
1. `flutter pub get`
2. `flutter run`

> Note: `android/app/google-services.json` must match your Firebase project.


## ESP32 full-control integration

If you want an ESP32 to be fully controllable from the app (and report applied/failed command status back), follow the implementation guide in [`docs/esp32_integration.md`](docs/esp32_integration.md).

The app already writes commands under `devices/{deviceId}/commands`; the ESP32 should consume `PENDING` commands, apply hardware changes, and write command status + telemetry back to Firestore.
