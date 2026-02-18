# FlowMatic (Flutter + Firebase)

FlowMatic is a **secure IoT-based smart irrigation** monitoring app.

## Features (App)
- Firebase Authentication (Email/Password + Google)
- Real-time dashboard and irrigation controls via Firestore
- AUTO mode irrigation decisions based on soil moisture vs dry threshold
- Encrypted/signed command payloads written to Firestore command queue
- Historical readings and controlled in-app testing (synthetic sensor readings)
- Device debug logs for operational troubleshooting
- Responsive shell layout for mobile and web/tablet

## Firestore Structure (recommended)

**Device Doc**
- `devices/device1`
  - `soilMoisture` (0–100)
  - `pumpOn` (bool)
  - `mode` (`AUTO` or `MANUAL`)
  - `thresholdDry` (0–100)
  - `transport` (`TLS_FIRESTORE`)
  - `securityMode` (`ENCRYPTED` or `SIGNED_PLAINTEXT`)
  - `lastUpdated` (timestamp)

**Readings**
- `devices/device1/readings/{autoId}`
  - `soilMoisture` (0–100)
  - `createdAt` (timestamp)

**Commands (device listens here)**
- `devices/device1/commands/{autoId}`
  - `type` (PUMP / MODE / THRESHOLD / AUTO_PUMP)
  - `payload` (encrypted/signed payload object)
  - `transport` (`TLS_FIRESTORE`)
  - `createdAt` (timestamp)
  - `createdBy` (uid)

**Debug logs**
- `devices/device1/logs/{autoId}`
  - `event` (string)
  - `detail` (map)
  - `createdAt` (timestamp)

## Run
1. `flutter pub get`
2. Configure Firebase as usual for Android/iOS.
3. (Optional but recommended) set command key:
   - `--dart-define=FLOWMATIC_COMMAND_KEY=<strong-secret>`
4. For web, pass Firebase config at runtime:
   - `--dart-define=FIREBASE_PROJECT_ID=...`
   - `--dart-define=FIREBASE_APP_ID=...`
   - `--dart-define=FIREBASE_MESSAGING_SENDER_ID=...`
   - `--dart-define=FIREBASE_API_KEY=...`
   - Optional: `FIREBASE_AUTH_DOMAIN`, `FIREBASE_STORAGE_BUCKET`
5. `flutter run`

> Note: `android/app/google-services.json` must match your Firebase project.
