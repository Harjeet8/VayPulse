# PhytoSense AI Firebase Remote Monitoring Setup

Firebase is a **transport layer only**. The ESP32 remains the source of truth for
health, plant condition, root cause, recommendation, confidence, prediction,
recovery, sensor integrity, bio/contact validity, and adaptive plant intelligence.

## Android client configuration

1. Create/select the Firebase project used by the PhytoSense node.
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

The ESP32/cloud writer should update `lastSeen` or `timestamp` on every cloud
upload (the current firmware cadence is approximately three seconds).

## Security rules

Do **not** use public rules such as `.read = true` or `.write = true`.

A minimal authenticated-read development rule is:

```json
{
  "rules": {
    "phytosense": {
      "nodes": {
        "$nodeId": {
          "live": {
            ".read": "auth != null",
            ".write": "false"
          }
        }
      }
    }
  }
}
```

That example deliberately blocks client writes. For a production deployment,
scope reads to the user's permitted node(s), and authorize the ESP32/cloud
writer separately using an appropriate Firebase-supported identity. Do not put
a privileged server credential inside the Flutter APK.

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
