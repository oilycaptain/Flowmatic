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

## Security + Reliability Notes
- **Encrypted data transmission:** Firebase Auth + Firestore SDK traffic is sent over TLS, and the app now explicitly enables Firestore `sslEnabled: true`.
- **Stable cloud storage:** Firestore is used as the primary cloud database and the app now explicitly enables offline persistence plus unlimited local cache for better sync resilience.
- **Transient-failure handling:** write operations (pump/mode/threshold/seed data) now retry automatically on temporary Firestore errors.

## Run
1. `flutter pub get`
2. `flutter run`

> Note: `android/app/google-services.json` must match your Firebase project.
