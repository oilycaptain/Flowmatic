# ESP32 ↔ FlowMatic integration (full control)

This app already uses Firestore as the control plane. To give an ESP32 **full control + feedback**, implement the firmware contract below.

## 1) Firestore contract

Use one device document per board, for example `devices/device1`.

### Device state (written by ESP32)

`devices/{deviceId}`

- `soilMoisture` (0-100)
- `pumpOn` (bool)
- `mode` (`AUTO` / `MANUAL`)
- `thresholdDry` (0-100)
- `lastUpdated` (server timestamp)
- `heartbeatAt` (server timestamp, written every ~15-30s)

### App commands (written by Flutter app)

`devices/{deviceId}/commands/{commandId}`

- `type` (`PUMP`, `MODE`, `THRESHOLD`)
- `payload` (map)
- `createdAt` (server timestamp)
- `createdBy` (uid)
- `status` (`PENDING`, `APPLIED`, `FAILED`)
- `appliedAt` (timestamp, set by ESP32)
- `error` (string, only when failed)

## 2) Command handling logic on ESP32

1. Query commands ordered by `createdAt` ascending, filtered to `status == PENDING`.
2. For each command:
   - Validate payload and apply to hardware/state.
   - Update `devices/{deviceId}` with the resulting truth state.
   - Mark command:
     - success: `status = APPLIED`, `appliedAt = now`
     - failure: `status = FAILED`, `error = "..."`, `appliedAt = now`
3. Keep publishing periodic `heartbeatAt` and sensor readings.

## 3) Minimal firmware pseudo-code

```cpp
loop() {
  ensureWifiAndFirebase();

  // A) publish telemetry
  int moisture = readSoilPercent();
  bool shouldPump = decidePump(mode, moisture, thresholdDry, manualPump);
  setPumpRelay(shouldPump);

  updateDoc("devices/device1", {
    {"soilMoisture", moisture},
    {"pumpOn", shouldPump},
    {"mode", mode},
    {"thresholdDry", thresholdDry},
    {"lastUpdated", serverTimestamp()},
    {"heartbeatAt", serverTimestamp()},
  });

  appendDoc("devices/device1/readings", {
    {"soilMoisture", moisture},
    {"createdAt", serverTimestamp()}
  });

  // B) consume app commands
  auto pending = query(
    "devices/device1/commands",
    where("status", "==", "PENDING"),
    orderBy("createdAt", "asc"),
    limit(10)
  );

  for (auto cmd : pending) {
    bool ok = applyCommand(cmd["type"], cmd["payload"]);
    if (ok) {
      updateDoc(cmd.path, {
        {"status", "APPLIED"},
        {"appliedAt", serverTimestamp()}
      });
    } else {
      updateDoc(cmd.path, {
        {"status", "FAILED"},
        {"error", "invalid payload or hardware error"},
        {"appliedAt", serverTimestamp()}
      });
    }
  }

  delay(1000);
}
```

## 4) Security rules baseline

- Authenticated app users: can read device docs and create command documents.
- ESP32 service identity: can read pending commands and update state/command status.
- Disallow clients from forging `APPLIED/FAILED` status.

## 5) Operational tips

- Keep relay fail-safe default OFF on boot.
- Add watchdog reset for Wi-Fi/Firebase lockups.
- Debounce relay switching to avoid chatter.
- In AUTO mode, enforce local safety in firmware even if app sends conflicting command.
