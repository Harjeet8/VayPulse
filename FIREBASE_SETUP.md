# PhytoSense AI Firebase Remote Monitoring Setup

Firebase is a **transport layer only**. The ESP32 remains the source of truth for
health, plant condition, root cause, recommendation, confidence, prediction,
recovery, sensor integrity, bio/contact validity, and adaptive plant intelligence.

## Firebase project

Project ID:

`phytosense-ai-1b0d8`

Realtime Database:

`https://phytosense-ai-1b0d8-default-rtdb.asia-southeast1.firebasedatabase.app`

The Flutter remote client is explicitly bound to that database URL and refuses
a mismatched Firebase project configuration.

## Android client configuration

1. Open/select Firebase project `phytosense-ai-1b0d8`.
2. Register Android application ID `com.harjeet.phytosense`.
3. Download that project's Android `google-services.json`.
4. Supply it at build time as:
   `android/app/google-services.json`
5. Do not commit passwords, service-account JSON, Admin SDK credentials,
   database secrets, or long-lived private tokens.

The repository ignores `android/app/google-services.json` so project-specific
configuration can be supplied through the release environment. The Android
build applies the Google Services plugin only when the file is present, which
preserves fully local ESP32 builds.

## Authentication

The Flutter client uses normal Firebase Authentication. If no user is already
signed in, the remote transport attempts Firebase Anonymous Authentication.

Enable **Authentication > Sign-in method > Anonymous** for the competition
deployment, or replace it later with your normal signed-in user flow. The app
does not contain Firebase Admin SDK credentials.

## Realtime Database path

The app reads the authoritative ESP32 snapshot at:

`/phytosense/nodes/phytosense_01/live`

against:

`https://phytosense-ai-1b0d8-default-rtdb.asia-southeast1.firebasedatabase.app`

The ESP32/cloud writer should update `lastSeen` or `timestamp` on every cloud
upload (the current firmware cadence is approximately three seconds).

## Security rules

Do **not** use public rules such as `.read = true` or `.write = true`.

A minimal authenticated-read app rule is:

```json
{
  "rules": {
    "phytosense": {
      "nodes": {
        "$nodeId": {
          "live": {
            ".read": "auth != null",
            ".write": "auth != null && auth.uid == 'REPLACE_WITH_ESP32_WRITER_UID'"
          }
        }
      }
    }
  }
}
```

Replace `REPLACE_WITH_ESP32_WRITER_UID` with the UID of the dedicated ESP32
writer identity configured on the device side. The Flutter app uses Anonymous
Authentication for reads and contains no ESP32 writer email/password.

For a production deployment, scope reads to the user's permitted node(s) and
keep write authorization restricted to the dedicated device identity. Do not
put a privileged server credential inside the Flutter APK.

## Freshness

Remote presence alone does not mean the node is online. The app centrally
classifies the snapshot from `lastSeen` / `timestamp`:

- 0–10 seconds: LIVE
- 10–30 seconds: DELAYED
- over 30 seconds: STALE (or OFFLINE when connectivity is explicitly down)

STALE/OFFLINE snapshots are not accepted as current Hardware Mode readings.

## Hardware transport modes

- **AUTO** (default): direct ESP32 first, then fresh Firebase; returns to local
  after a short recovery debounce.
- **LOCAL**: direct ESP32 only; no Internet/Firebase dependency.
- **REMOTE**: authenticated Firebase only.

Simulation remains an independent provider and never reads from or writes to
the hardware Firebase path.

## ESP32 Wi-Fi provisioning

Router credentials remain owned by the ESP32 and its NVS storage. Flutter does
not scan router networks, request router passwords, save router passwords, or
write router credentials to Firebase.

In Hardware Mode, **Devices → Configure Node Wi-Fi** checks the direct
PhytoSense setup node and opens the ESP32 dashboard at
`http://192.168.4.1` in the system browser. If the local node is not reachable,
the app asks the user to connect the phone to the PhytoSense node Wi-Fi first.

The provisioning page served by the ESP32 is responsible for SSID scanning,
password entry, STA connection, and persistent network switching.
