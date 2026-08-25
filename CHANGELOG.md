# Changelog

## 9.0.0 — PhytoSense AI primary identity

- Established PhytoSense AI as the primary farmer-facing product name.
- Adopted the official tagline: “Know Your Crop. Protect Your Yield.”
- Updated Android, iOS, web, Windows, macOS and Linux display metadata.
- Retained VayPulse as the supporting technology identity and VayPulse Node as
  the ESP32 hardware name.
- Preserved package IDs, bundle IDs, wire identifiers, local storage keys and
  the complete SensorDataProvider architecture for backwards compatibility.

## 8.1.0 — Natural voice and responsive correction

- Added automatic high-quality voice selection for English India and Tamil.
- Prioritized installed natural, neural, premium and enhanced system voices.
- Tuned rate, pitch, volume and spoken sensor-unit phrasing for calmer guidance.
- Added a voice preview and selected-voice label in Settings.
- Included the health-ring, source-sheet and sensor-card overflow corrections.

## 8.0.2 — Responsive overflow correction

- Isolated health-ring typography from browser and operating-system text scale.
- Rebuilt the source selector as a height-owned, fully scrollable bottom sheet.
- Replaced fixed-height home sensor-grid cells with content-sized responsive cards.

## 8.0.1 — Flutter 3.47 compatibility correction

- Imported the Cupertino transition builder explicitly for Flutter 3.47.
- Restored the disease-assessment model import required by questionnaire tests.
- Removed two analyzer information messages from the camera and live-node code.

## 8.0.0 — Ultimate UI Edition

- Added persistent Farmer and Judge experiences so daily decisions stay simple
  while technical evidence remains immediately available to evaluators.
- Rebuilt the home hierarchy around a daily briefing, responsive health hero,
  one primary action, voice guidance and collapsible sensor detail.
- Added animated readings, freshness state, preferred ranges, deltas, reduced
  motion and larger-text accessibility controls.
- Added a source-isolated Plant Observation Timeline and expanded alert filters
  with swipe-to-archive, Undo and confirmation before clearing.
- Added guided camera progress, leaf framing and evidence-first scan results.
- Added global command search, keyboard navigation, pull-to-refresh and a
  branded startup/error experience.
- Upgraded Presentation Mode with reset controls and a live system snapshot.
- Preserved complete Demo/ESP32 isolation so simulation cannot overwrite or
  visually contaminate a physical-node session.

## 7.0.0 — Ultimate Evidence Edition

- Added an Engineering Evidence Center with a live system X-ray from provider
  selection through validation, reasoning, farmer action and stored evidence.
- Added persistent experiment trials that record source, node, baseline health,
  peak stress, sample count, outcome and notes.
- Added a repeat-sample sensor calibration wizard with saved baselines and a
  transparent stability-based trust score.
- Added a one-tap judge report generated from the current app state and copied
  without requiring a cloud account.
- Added farmer outcome confirmation to alerts, including false-alert evidence,
  usefulness and recovery tracking.
- Added a responsible-AI model card with intended use, evidence inputs,
  limitations and non-chemical safety boundaries.
- Added offline nearest-city labels for phone GPS across major Tamil Nadu
  locations, including Tiruchirappalli (Trichy).
- Kept trials, calibration profiles, farmer feedback, alert sessions and
  evidence summaries isolated across Demo and ESP32 sources.

## 6.0.0 — Ultimate ESP32 Live Edition

- Added a dedicated, single-node ESP32 workspace with no farm selector or simulated location.
- Isolated demo and live node identities, streams, histories, scenarios and offline records.
- Replaced the Fields navigation destination with Live node while ESP32 mode is active.
- Added live-session status, freshness watchdog, range-validation badge, endpoint visibility, signal, battery and one-tap reconnect.
- Fixed the responsive data-source sheet overflow and compact health-ring overlap.
- Hid farm-only weather, irrigation and crop-management tools while in the physical-node workspace.
- Strengthened dark-mode surfaces, menus, dialogs and high-contrast status cards.
- Added the advanced tomato symptom questionnaire while retaining ten Tamil Nadu crop contexts.

## 5.0.1 — Compact layout correction

- Removed the label from compact 72 px health rings so browser zoom, translated
  fonts and operating-system font scaling cannot overlap the score.
- Declared `intl` as a direct dependency to keep `flutter analyze` clean.

## 5.0.0 — Tamil Nadu Crop Edition

- Added farmer-confirmed disease-risk screening for rice, maize, groundnut,
  cotton, sugarcane, banana, coconut, tomato, brinjal and chilli.
- Added crop-specific disease and pest candidate sets with English/Tamil
  explanations and inspection guidance.
- Added rejection for undersized, dark, overexposed, low-detail and
  non-leaf-like images so random photos do not receive rice results.
- Added phone-GPS weather location with while-in-use permission, privacy text,
  manual coordinates and cached offline fallback.
- Added flooded-rice awareness so expected paddy moisture does not trigger the
  generic overwatering disease prompt.
- Rebuilt the small health ring to prevent score/label overlap on narrow layouts.
- Replaced unfinished roadmap labels with accurate Complete/Ready Version 5
  delivery status without claiming unmeasured hardware results.
- Expanded deterministic tests for all ten crop contexts and paddy flooding.

## 4.1.0 — Field Impact Edition

- Rebuilt dark mode around a high-contrast deep-green surface hierarchy with
  accessible text, clearer borders and coordinated Material components.
- Replaced the appearance dropdown with an immediate visual System / Light /
  Dark theme picker.
- Added an interactive farm-impact estimator to About PhytoSense AI with concrete
  rupee outputs for potential loss prevented, input savings, first-season net
  benefit and benefit-to-cost ratio.
- Added editable acreage, crop value, risk, early-detection, savings and system
  cost assumptions plus a transparent formula and projection disclaimer.
- Added English/Tamil impact and dark-mode guidance and a deterministic impact
  calculation test.
- Fixed the unsupported `Icons.rainy` reference that blocked Chrome builds.

## 4.0.0 — Multimodal Disease Intelligence Edition

- Added crop-specific potential disease, pest and environmental-stress ranking
  for rice, tomato and other configured crops.
- Added automatic leaf-photo prompts when electrode, health, soil, temperature,
  humidity or weather evidence becomes abnormal.
- Combined on-device photo patterns with the selected crop, plant-electrode
  response, environmental sensors and fresh weather in one explainable result.
- Added ranked match scores, evidence labels and nonchemical “inspect next”
  guidance in English and Tamil.
- Added voice narration of the top potential match and its inspection evidence.
- Added deterministic tests for photo triggers and rice/tomato ranking logic.
- Kept all outputs clearly labelled as potential matches rather than confirmed
  diagnoses; no pesticide selection or chemical quantity is generated.

## 3.0.0 — Farmer Intelligence Edition

- Added on-device leaf-photo screening with camera/gallery capture, visible colour evidence, confidence, safe next steps, and no automatic pesticide recommendation.
- Added live five-day Open-Meteo weather, cached fallback, and drought, heavy-rain, and disease-risk alerts.
- Added weather-aware irrigation recommendations that require farmer confirmation and never operate pumps.
- Added English/Tamil text-to-speech guidance for leaf, weather, and irrigation decisions.
- Added persistent offline sensor queue and configurable `/api/sync` server upload with retry-safe retention.
- Added editable field crops and zone growth stages.
- Added low-battery, weak-signal, abnormal-data, and forecast-driven alerts.
- Expanded the About and Competition Center evidence sections while separating completed software from pending hardware trials.

## 2.0.0 — Competition Edition

- Added runtime Simulation Demo / ESP32 Live switching
- Added concrete ESP32 polling provider and endpoint connection test
- Added network timeouts, JSON checks and sensor-range validation
- Added plant-signal monitoring and chart metric
- Added early moisture-trend and plant-signal cross-check analysis
- Added source-labelled farmer dashboard and node diagnostics
- Added detailed About PhytoSense AI screen inside Settings and More
- Added Competition Center, evidence readiness and judge FAQ
- Added guided presentation mode with live simulation console
- Added local-network platform configuration and ESP32 API contract
- Updated English and Tamil content throughout the new workflows
- Expanded automated tests for raw ESP32 data and provider switching
