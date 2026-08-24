# VayPulse ESP32 API Contract

This contract allows one ESP32 node to plug into the Competition Edition app
without changing dashboards, charts, alerts or analysis code.

## Network

The phone/tablet and ESP32 may use the same Wi-Fi network, or the ESP32 may
create its own access point. Enter the ESP32 base address in:

`More → Settings → ESP32 connection`

Common access-point address: `http://192.168.4.1`

The example `phytosense-node-01` value is an intentionally preserved legacy
wire identifier. It is not shown as the product name; the app presents the
hardware to farmers as **VayPulse Node**. Existing firmware can therefore keep
working through the brand migration.

## `GET /api/status`

Return HTTP 200 when the node is ready.

```json
{
  "deviceId": "phytosense-node-01",
  "status": "online",
  "firmwareVersion": "1.0.0"
}
```

## `GET /api/data`

Return HTTP 200 and JSON:

```json
{
  "deviceId": "phytosense-node-01",
  "firmwareVersion": "1.0.0",
  "batteryPercent": 100,
  "signalPercent": 82,
  "data": {
    "nodeId": "node-rice-a1",
    "timestamp": "2026-08-23T12:00:00Z",
    "soilMoisture": 61.5,
    "temperature": 25.2,
    "humidity": 57.0,
    "light": 68.0,
    "plantSignal": 72.0
  }
}
```

`healthScore`, `stressScore` and `healthStatus` are optional. When omitted, the
app calculates them from raw measurements so the firmware can remain small.

## Plant-electrode normalization

`plantSignal` is the app-facing electrode response index. The firmware should
convert the node's raw electrode measurement into a stable `0–100` value after
collecting a healthy baseline for the actual electrode placement and crop.

- Higher is not automatically “better”: the app treats both a very low value
  and an unusually high value as evidence that contact or plant response needs
  inspection.
- A calibrated normal working band should normally sit away from `0` and `100`;
  the included demo uses roughly `50–85` for stable conditions.
- VayPulse requests a representative leaf photo when `plantSignal < 38` or
  `plantSignal > 92`, then cross-checks the photo with all other evidence.
- Keep electrode placement, contact method and sample interval consistent
  during trials. Record the raw value separately in your experiment notes; the
  current app API consumes only the normalized index.

These thresholds are prototype decision-support bands. Replace them only after
repeated baseline, stress and recovery trials produce measured evidence.

## Accepted ranges

| Field | Accepted range | Unit |
| --- | ---: | --- |
| `soilMoisture` | 0–100 | normalized percent |
| `temperature` | -10–65 | °C |
| `humidity` | 0–100 | percent |
| `light` | 0–100 | normalized percent |
| `plantSignal` | 0–100 | normalized plant-response index |
| `batteryPercent` | 0–100 | percent |
| `signalPercent` | 0–100 | percent |

Out-of-range values are rejected and shown as a sensor-data error rather than
being allowed to create a false farmer alert.

## Browser CORS headers

For Flutter Web, include these headers on both endpoints:

```text
Access-Control-Allow-Origin: *
Access-Control-Allow-Methods: GET, OPTIONS
Access-Control-Allow-Headers: Content-Type
Content-Type: application/json
```

Native Android and Windows builds do not require browser CORS.

## Final hardware checklist

1. Convert each raw sensor reading into the documented normalized unit.
2. Keep `/api/status` fast and independent of sensor sampling.
3. Return valid JSON and HTTP 200 from `/api/data`.
4. Test the address inside the app before selecting ESP32 Live.
5. Confirm every visible screen displays the **LIVE** badge.
6. Run baseline, controlled-stress and recovery trials.
7. Record response time, false alerts and measured detection performance.
8. Confirm an abnormal `plantSignal` creates the Home-screen photo prompt and
   that the resulting disease screen displays a **LIVE** evidence badge.

Simulation remains a presentation fallback and never labels its values as live
hardware data.
