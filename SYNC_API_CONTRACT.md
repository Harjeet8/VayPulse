# VayPulse Optional Synchronization API

VayPulse works without a cloud server. Every sensor reading is first queued in
local app storage. If a farm, school or future production backend is available,
the farmer can configure its base URL under **More → Offline data and sync**.
Only validated ESP32 readings enter this queue; simulated demonstration values
are never synchronized as field evidence.
The app also keeps a downsampled local history for charts. Successful upload
clears the pending sync queue but does not erase that local chart history.

The `phytosense-mobile` device value below is an intentionally preserved
legacy protocol identifier. It remains non-visible so existing backends and
saved records are not broken by the VayPulse display-name migration.

## Endpoint

`POST /api/sync`

Request header:

```text
Content-Type: application/json
```

Example request:

```json
{
  "device": "phytosense-mobile",
  "records": [
    {
      "nodeId": "node-rice-a1",
      "timestamp": "2026-08-23T12:00:00Z",
      "soilMoisture": 61.5,
      "temperature": 25.2,
      "humidity": 57.0,
      "light": 68.0,
      "plantSignal": 72.0,
      "healthScore": 91.0,
      "stressScore": 9.0,
      "healthStatus": "excellent",
      "source": "esp32",
      "queuedAt": "2026-08-23T12:00:01Z"
    }
  ]
}
```

## Success behaviour

Return any HTTP status from 200 through 299 after the entire batch has been
stored safely. Only then does the app clear those pending records. Any timeout,
network error or other status keeps the records locally for a later retry.

Suggested response:

```json
{
  "accepted": 1,
  "status": "stored"
}
```

## Production hardening

Before real deployment, add HTTPS, farmer authentication, per-record IDs,
server-side deduplication, access controls, retention policy and encrypted
backups. The competition build deliberately does not claim that a public cloud
backend already exists.
