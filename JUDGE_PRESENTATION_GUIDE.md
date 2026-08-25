# PhytoSense AI — Judge Presentation Guide

## Before the event

1. Run `flutter analyze` and `flutter test` on the final extracted folder.
2. Open the app once and complete onboarding.
3. Select English or Tamil based on the audience.
4. Keep **Simulation Demo** selected until the physical node is fully tested.
5. If using hardware, open Settings, enter the ESP32 address and press
   **Save and test connection**.
6. Charge the phone/tablet and ESP32 power source.
7. Keep the simulation demo available as the honest network-failure fallback.
8. For the camera demo, keep one healthy leaf and one visibly stressed leaf in
   good light, or use previously captured photos from the gallery.
9. Open Farm Weather once while online so a cached forecast is available.
10. In the leaf scanner, select and confirm the crop before choosing the photo.
11. Open **More → Engineering Evidence Center** and capture at least three
    calibration samples so the trust card has real session evidence.
12. Select **Judge Mode** in Settings so the competition and engineering tools
    are visible. Use Ctrl+K on desktop to open the global command search.

## Three-minute presentation

### 0:00–0:35 — Problem

“Plant stress can begin before it is clearly visible. Across multiple farm
zones, manual inspection can become late or inconsistent.”

### 0:35–1:05 — Solution

“PhytoSense AI combines an affordable sensor node with a farmer-first bilingual
app. It does not only show numbers: it explains the likely concern, the evidence
behind it and what the farmer should inspect next.”

### 1:05–1:55 — Demonstration

Open **More → Competition Center → Start guided judge demo**. Press **Reset
Presentation** immediately before the judges arrive.

1. Show the system architecture step.
2. Open the demo console.
3. Select Healthy, then Dry soil, then Critical combination.
4. Point to the changing health, moisture, temperature and explained insight.
5. Point out the visible **DEMO** label.
6. Select a stressed scenario and show the automatic **take a photo** prompt.
7. Open **Scan leaf**, confirm one of the ten Tamil Nadu crop contexts, and
   explain that invalid/non-leaf photos are rejected before electrode, sensor
   and fresh-weather evidence are cross-checked.
8. Show the ranked potential issue types, match score, evidence and **Inspect
   next** guidance.
9. Open **Irrigation** and show how soil moisture and rain forecast are
   cross-checked before guidance appears.
10. Open **About PhytoSense AI → Farm impact & savings estimator**. Show the
    rupee result, expand the assumptions and change acreage or crop value so
    judges can see that the number is calculated rather than hard-coded.
11. Open **More → Engineering Evidence Center → System X-Ray** to show the live
    provider-to-evidence pipeline.
12. Start and finish a short trial in **Experiment Evidence Lab**, then open
    **One-tap Judge Report** and copy the current evidence summary.
13. Finish with the **Responsible-AI Model Card** to show judges that the app
    distinguishes match scores, measured evidence and confirmed diagnoses.

If the ESP32 is connected, return to Home and select **ESP32 Live** to show the
real node. Point out that the navigation changes from **Fields** to **Live
node**, all farm/location controls disappear, and the live-session header shows
freshness, range validation, endpoint, signal and battery. Never describe
simulated readings as hardware readings.

### 1:55–2:30 — Engineering

“Simulation and ESP32 implement the same SensorDataProvider contract. The
dashboard, charts, alerts and analysis do not know which provider is active.
Invalid JSON, missing fields, timeouts and out-of-range readings are handled as
clear diagnostic states rather than app crashes. Weather is cached, sensor
records are queued offline, and synchronization only clears records after a
successful server response.”

### 2:30–3:00 — Impact

“PhytoSense AI Version 9.0 is a complete one-node deployment application. The same architecture
can add node IDs to more fields and zones without changing the farmer workflow.
The system is local-first, bilingual and keeps the farmer in control instead of
automating irrigation without confirmation.”

If a judge asks whether the camera feature is a trained AI model, answer:

“PhytoSense AI performs transparent multimodal candidate ranking for ten
major Tamil Nadu crop contexts. The farmer confirms the crop, the app rejects
unusable or unrelated photos, and then visible colour patterns are cross-checked
with plant-electrode response, soil, temperature, humidity and fresh weather.
The percentage is a match score—not measured accuracy or a confirmed diagnosis.
This is responsible decision support; a future trained classifier would still
require a labelled field dataset and controlled validation.”

If a judge asks why pesticide and dose are not generated, answer:

“The app helps the farmer identify what to inspect first, but chemical choice
and quantity depend on the confirmed problem, crop stage, product formulation,
local approval and label. PhytoSense AI therefore sends the farmer to qualified
local advice instead of inventing a chemical instruction.”

## Evidence to collect after hardware integration

- Healthy baseline duration
- Number of repeated trials
- Time from controlled condition change to alert
- Correct detections
- False alerts
- Sensor calibration method
- Recovery after normal care resumes
- Final component cost
- Leaf-image lighting and background conditions
- Expert label for each disease image used in future model validation
- Weather-alert correctness against observed field conditions

Only enter accuracy or savings figures after they are measured.

The built-in impact estimator is suitable for explaining the value model, but
describe its output as a **projection**. For example, the default rice scenario
shows ₹10,080 of potential loss prevented because the visible assumptions are
3.2 acres × ₹60,000 seasonal value × 15% at risk × 35% caught early. Replace
these demonstration assumptions with field evidence before calling the result
an achieved farmer benefit.

## Likely judge questions

The Competition Center contains expandable, presentation-ready answers for:

- What exactly is the AI?
- What is novel compared with a standard IoT dashboard?
- How can one node scale to a farm?
- How are false alerts controlled?
