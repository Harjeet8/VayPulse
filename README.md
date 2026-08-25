# PhytoSense AI — Version 9.0.0

**Know Your Crop. Protect Your Yield.**

**Powered by VayPulse technology.**

PhytoSense AI is a farmer-first Flutter platform that turns environmental and
plant-response sensor readings into clear, explainable field decisions. The
main farmer interface stays simple; engineering evidence and presentation
material are separated into the Competition Center.

## Version 9 experience

- Persistent Farmer Mode for large actions, plain-language daily guidance and
  optional technical detail, plus Judge Mode for architecture, evidence,
  calibration, experiments and competition presentation tools.
- Rebuilt home decision hierarchy: daily briefing, health, one clear next
  action, voice guidance, farmer tools, and collapsible sensor evidence.
- Responsive health cards and rings designed to remain separated under narrow
  browser widths and increased text scaling.
- Animated live values, freshness pulse, preferred ranges and reading deltas,
  with a Reduce Motion setting.
- Guided crop-confirmed leaf scan with crop/photo/evidence/result progress,
  camera framing, image-quality rejection and explainable evidence chips.
- Source-isolated Plant Observation Timeline for readings, alerts, trials,
  calibration and simulation weather.
- Action, Monitor, Resolved and System alert categories; swipe-to-archive with
  Undo; confirmation before clearing a visible alert session.
- Pull-to-refresh, larger-text mode, branded startup state, desktop tooltips,
  Alt+1…5 navigation and Ctrl+K global command search.
- Resettable Presentation Mode 2.0 with a one-screen current-system snapshot.

## Product capabilities

- Farm → Field → Zone → Sensor Node hierarchy
- Runtime switch between clearly labelled Simulation Demo and ESP32 Live data
- ESP32 endpoint configuration, connection test, polling and retry states
- Soil moisture, temperature, humidity, light and plant-signal monitoring
- Historical charts, health scoring and selectable metrics
- Multimodal camera/gallery screening performed on-device: visible green,
  yellow and brown evidence is cross-checked with the selected crop,
  plant-electrode response, environmental sensors and fresh weather
- Farmer-confirmed crop screening for ten major Tamil Nadu crop contexts:
  rice, maize, groundnut, cotton, sugarcane, banana, coconut, tomato, brinjal
  and chilli
- Image quality and leaf-like evidence checks that reject unrelated, dark,
  overexposed, low-detail or undersized photos instead of forcing a diagnosis
- Automatic “take a representative leaf photo” prompt when plant signal,
  health, soil, heat, humidity or disease-weather evidence becomes abnormal
- Live phone-GPS farm weather with manual-location control and cached offline
  fallback; location is requested only when the farmer presses the GPS button
- Weather-aware irrigation recommendations that always require farmer
  confirmation and never control pumps
- Explainable analysis using preferred bands, multi-sensor cross-checks and
  recent trend detection
- Automatic drought, heat, heavy-rain, disease-risk, node-battery, weak-signal
  and abnormal-reading alerts with severity and deduplication
- English and Tamil UI plus bilingual text-to-speech guidance
- Persistent offline reading queue and configurable `/api/sync` upload
- Editable field crops and zone growth stages saved locally
- Light/dark/system themes and responsive phone, tablet and desktop navigation
- Redesigned high-contrast dark mode with coordinated navigation, cards,
  inputs, switches, sliders, dialogs and chart surfaces
- Interactive farm-impact estimator with editable acreage, crop value, loss
  risk, early-detection share, input savings and one-node system cost
- Healthy, dry, overwatered, heat, low-light, critical, offline and sensor-fault
  presentation scenarios
- Sensor range validation, timeouts, invalid-JSON handling and diagnostics
- Detailed About PhytoSense AI and Competition Center pages
- Guided presentation mode with an honest simulation console
- Engineering Evidence Center with a live system pipeline X-ray
- Persistent controlled-trial records with baseline, stress and outcome evidence
- Sensor calibration wizard with repeat-sample baselines and a stability score
- One-tap, copyable judge report generated from the app's current state
- Farmer confirmation loop for useful, recovered and false-alert outcomes
- Responsible-AI model card stating scope, evidence, limits and safe use
- Offline Tamil Nadu place-name resolution for phone GPS, including a readable
  “Tiruchirappalli (Trichy), Tamil Nadu” label near Trichy

## Run

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

For a local HTTP ESP32 on Android, Internet permission and clear-text local
traffic support are already declared. iOS contains the local-network usage
description. A browser build also requires the ESP32 firmware to return CORS
headers.

Camera capture is best demonstrated on Android/iOS. Flutter Web can select an
image and may expose a device camera depending on browser support. Live weather
uses the key-free Open-Meteo forecast endpoint and falls back to the last saved
forecast if the network is unavailable. Farmers can enter farm/village
coordinates manually or use phone GPS in the Weather Center. A nearest-city
label is resolved on-device for major Tamil Nadu locations; GPS coordinates are
shown when no listed city is nearby. PhytoSense AI does not continuously track the
phone. The Coimbatore fallback exists only inside
the farm simulation workspace; ESP32 Live hides farm location and weather so
unrelated demonstration context cannot be mistaken for physical-node data.

## Architecture

```text
SimulationSensorProvider ─┐
                          ├─ SensorProviderManager
Esp32SensorProvider ──────┘          │
                                     └─ SensorDataProvider
                                          ├─ Dashboard
                                          ├─ Charts
                                          ├─ Analysis
                                          ├─ Alerts
                                          └─ Offline queue

Open-Meteo ── WeatherService ──┬─ Weather alerts
                               └─ IrrigationAdvisor

Camera/Gallery ── LeafScreeningService ─┐
Plant electrode + sensors ──────────────┼─ MultimodalDiseaseService
Crop + fresh weather ──────────────────┘          │
                                                   └─ ranked potential issues
```

Monitoring features only consume `SensorDataProvider`. Source selection and
endpoint configuration are handled by `SensorProviderManager`. Simulation and
ESP32 use different node IDs, histories and workspaces, and late stream events
from an inactive provider are ignored. Trials, calibration profiles, outcome
feedback and visible alert sessions are also isolated by source.

## ESP32 integration

The app expects:

- `GET /api/status` for connection testing
- `GET /api/data` for sensor snapshots
- a poll interval of approximately three seconds

See [`ESP32_API_CONTRACT.md`](ESP32_API_CONTRACT.md) for the exact payload,
validation ranges, CORS notes and integration checklist.

Optional server synchronization uses `POST /api/sync`. See
[`SYNC_API_CONTRACT.md`](SYNC_API_CONTRACT.md) for the batch format and success
requirements.

## Compatibility identifiers

Version 9 changes the visible product identity only. The Dart package name,
Android/iOS bundle identifiers, desktop executable names, persistent storage
keys and existing ESP32 wire IDs intentionally retain their legacy
`phytosense` values. Keeping these non-visible identifiers prevents broken
imports, lost local records and incompatible sensor payloads during the brand
migration.

## Scientific integrity

Simulation values are always marked **DEMO** and live readings are marked
**LIVE**. PhytoSense AI Version 9 presents completed software capabilities and clearly labels
the physical-node connection as deployment-ready. No accuracy figure is shown
until repeated hardware trials produce measured evidence.

The disease feature is an explainable crop-confirmed candidate-ranking tool,
not an automatic crop-species detector, trained pathogen classifier or
laboratory diagnosis. Its percentages are transparent rule-based match scores,
not accuracy figures. PhytoSense AI identifies potential disease, pest or
environmental-stress types so farmers know what to inspect first. It
intentionally does not select pesticides or chemical quantities; farmers
should compare multiple plants and use qualified local agricultural advice
before treatment or irrigation changes.

The About screen's rupee values are calculated projections, not guaranteed
profit claims. The demonstration defaults produce a concrete example, while
every assumption is editable. Replace those assumptions with crop prices,
field records and repeated measured trials before presenting a real savings or
loss-prevention result.
