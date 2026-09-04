import 'package:flutter/widgets.dart';

import '../services/app_scope.dart';

class AppStrings {
  final String languageCode;

  const AppStrings(this.languageCode);

  String text(String key, [Map<String, Object> values = const {}]) {
    var value = _values[languageCode]?[key] ?? _values['en']?[key] ?? key;
    for (final entry in values.entries) {
      value = value.replaceAll('{${entry.key}}', '${entry.value}');
    }
    return value;
  }

  static const Map<String, Map<String, String>> _values = {
    'en': {
      'tagline': 'Know Your Crop. Protect Your Yield.',
      'powered_by_vaypulse': 'Powered by VayPulse',
      'nav_home': 'Home',
      'nav_fields': 'Fields',
      'nav_insights': 'Insights',
      'nav_alerts': 'Alerts',
      'nav_more': 'More',
      'next': 'Next',
      'get_started': 'Get started',
      'retry': 'Retry',
      'cancel': 'Cancel',
      'close': 'Close',
      'save': 'Save',
      'active': 'Active',
      'online': 'Online',
      'offline': 'Offline',
      'good': 'Good',
      'normal': 'Normal',
      'low': 'Low',
      'high': 'High',
      'critical': 'Critical',
      'excellent': 'Excellent',
      'watch': 'Watch',
      'loading_data': 'Loading farm data…',
      'no_data': 'No readings available yet',
      'last_updated_now': 'Updated just now',
      'onboarding_monitor_title': 'Know every field',
      'onboarding_monitor_body':
          'Monitor soil moisture, temperature, humidity and light across every farm zone.',
      'onboarding_understand_title': 'Understand plant stress',
      'onboarding_understand_body':
          'Turn sensor trends into clear, explainable field insights—without technical clutter.',
      'onboarding_act_title': 'Act at the right time',
      'onboarding_act_body':
          'Receive simple next steps so you can inspect a zone early and make a confident decision.',
      'dashboard': 'Farm overview',
      'good_morning': 'Good morning',
      'good_afternoon': 'Good afternoon',
      'good_evening': 'Good evening',
      'farm_status_subtitle': 'Here is what your farm is telling you today.',
      'selected_zone': 'Selected zone',
      'health_score': 'Health score',
      'plant_health': 'Plant health',
      'zone_health': 'Zone health',
      'live_conditions': 'Live conditions',
      'soil_moisture': 'Soil moisture',
      'temperature': 'Temperature',
      'humidity': 'Humidity',
      'light': 'Light',
      'stress': 'Stress',
      'stable': 'Stable',
      'needs_attention': 'Needs attention',
      'urgent_check': 'Urgent check',
      'ai_field_insight': 'PhytoSense AI insight',
      'recommended_action': 'Recommended action',
      'why_this': 'Why this insight',
      'confidence': '{value}% confidence',
      'edge_learning_plant': 'Learning this plant',
      'edge_recovery_improving': 'Conditions are improving.',
      'edge_recovery_in_progress': 'Recovery is in progress.',
      'edge_recovery_progress': 'Recovery is in progress • {value}%',
      'edge_recovery_verified': 'Recovery verified.',
      'edge_prediction_fallback':
          '{target} may reach the warning range in ~{minutes} min if the current trend continues.',
      'decision_support_note':
          'Decision support only • Inspect the crop before taking action.',
      'zones_to_watch': 'Zones to watch',
      'all_zones_healthy': 'All monitored zones are in a healthy range.',
      'view_fields': 'View all fields',
      'sensor_network_online': 'Sensor network online',
      'sensor_network_offline': 'Sensor network offline',
      'sensor_network_error': 'Sensor data needs attention',
      'offline_message':
          'Live updates are paused. Your latest saved readings are still shown.',
      'error_message':
          'A sensor returned invalid data. Try the demo reset to reconnect.',
      'fields_and_zones': 'Fields & zones',
      'farm_structure': 'Farm → Field → Zone → Sensor node',
      'fields': 'fields',
      'zones': 'zones',
      'sensor_nodes': 'sensor nodes',
      'area_acres': '{value} acres',
      'crop': 'Crop',
      'crop_stage': 'Crop stage',
      'crop_rice': 'Rice',
      'crop_tomato': 'Tomato',
      'crop_maize': 'Maize',
      'crop_groundnut': 'Groundnut',
      'crop_cotton': 'Cotton',
      'crop_sugarcane': 'Sugarcane',
      'crop_banana': 'Banana',
      'crop_coconut': 'Coconut',
      'crop_brinjal': 'Brinjal',
      'crop_chilli': 'Chilli',
      'stage_tillering': 'Tillering',
      'stage_flowering': 'Flowering',
      'stage_fruit_set': 'Fruit set',
      'nodes': 'Nodes',
      'select_zone': 'Select zone',
      'selected': 'Selected',
      'zone_details': 'Zone details',
      'no_farms': 'No farms have been added yet.',
      'not_monitored': 'Not monitored in this mode',
      'insights_title': 'Trends & insights',
      'insights_subtitle': 'See what changed and why it matters.',
      'time_24h': '24H',
      'time_7d': '7D',
      'time_30d': '30D',
      'metric_health': 'Health',
      'metric_soil': 'Soil',
      'metric_temp': 'Temperature',
      'metric_humidity': 'Humidity',
      'average': 'Average',
      'minimum': 'Minimum',
      'maximum': 'Maximum',
      'trend_summary': 'Trend summary',
      'trend_healthy': 'Conditions are staying close to the preferred range.',
      'trend_attention':
          'Recent readings moved outside the preferred range. Inspect this zone.',
      'not_enough_history': 'More readings are needed to build this chart.',
      'alerts_title': 'Alerts',
      'alerts_subtitle':
          'Only conditions that may need a field check appear here.',
      'all': 'All',
      'warnings': 'Warnings',
      'mark_all_read': 'Mark all read',
      'clear_alerts': 'Clear alerts',
      'no_alerts': 'No active alerts',
      'no_alerts_body':
          'Your monitored zones are currently within their expected ranges.',
      'unread_count': '{value} unread',
      'alert_severe_dryness': 'Severe dryness detected',
      'alert_severe_dryness_message':
          'Soil moisture is very low. Inspect this node and verify irrigation.',
      'alert_low_moisture': 'Low soil moisture',
      'alert_low_moisture_message':
          'Moisture dropped below the preferred range. Check the zone before watering.',
      'alert_overwatering': 'Very high soil moisture',
      'alert_overwatering_message':
          'The soil remains unusually wet. Check drainage and pause irrigation if needed.',
      'alert_heat_stress': 'High temperature pattern',
      'alert_heat_stress_message':
          'Air temperature is above the preferred range. Inspect for heat stress.',
      'alert_low_light': 'Low light level',
      'alert_low_light_message':
          'Light has fallen below the expected range for this zone.',
      'ai_combined_stress': 'Dry and hot conditions detected',
      'ai_combined_stress_explanation':
          'Low soil moisture and high temperature together can increase plant stress.',
      'ai_combined_stress_action':
          'Inspect the zone now, confirm soil condition, and check the irrigation line.',
      'ai_water_stress': 'Water-stress pattern detected',
      'ai_water_stress_explanation':
          'Soil moisture is below the preferred range for the selected zone.',
      'ai_water_stress_action':
          'Inspect the soil near this node and irrigate only after confirming dryness.',
      'ai_overwatering': 'Possible excess moisture',
      'ai_overwatering_explanation':
          'Soil moisture is unusually high and may indicate overwatering or poor drainage.',
      'ai_overwatering_action':
          'Check drainage and pause the next irrigation cycle until the soil is inspected.',
      'ai_paddy_water_expected': 'Paddy water level looks expected',
      'ai_paddy_water_expected_explanation':
          'High soil moisture can be normal in a managed flooded rice field and is not treated as overwatering by itself.',
      'ai_paddy_water_expected_action':
          'Check standing-water depth and drainage in the field; this soil probe cannot measure water depth.',
      'ai_heat_stress': 'Heat-stress pattern detected',
      'ai_heat_stress_explanation':
          'Temperature is above the preferred range for the selected crop zone.',
      'ai_heat_stress_action':
          'Inspect the crop, check irrigation timing, and reduce avoidable midday exposure.',
      'ai_low_light': 'Low-light pattern detected',
      'ai_low_light_explanation':
          'Available light is below the recent range for this zone.',
      'ai_low_light_action':
          'Check for shade, covering, or a dirty light sensor before changing field practice.',
      'ai_healthy': 'Conditions look balanced',
      'ai_healthy_explanation':
          'Moisture, temperature, humidity and light are within a balanced range.',
      'ai_healthy_action':
          'Continue the current routine and review the trend again later.',
      'evidence_dry_hot':
          'Both moisture and temperature crossed their attention thresholds.',
      'evidence_low_soil':
          'Soil moisture crossed below the 30% attention threshold.',
      'evidence_high_soil':
          'Soil moisture crossed above the 88% attention threshold.',
      'evidence_paddy_water':
          'The active crop is rice, so the high-moisture reading was interpreted using paddy-field rules.',
      'evidence_high_temp':
          'Temperature crossed above the 33°C attention threshold.',
      'evidence_low_light': 'Light crossed below the 25% attention threshold.',
      'evidence_balanced':
          'All four readings remain inside the rule-based preferred bands.',
      'more_title': 'Farm & app',
      'farmer_profile': 'Farm manager',
      'demo_farm': 'Demo farm workspace',
      'devices': 'Devices',
      'devices_subtitle': 'View sensor nodes and connection health',
      'settings': 'Settings',
      'settings_subtitle': 'Data source, ESP32, language and appearance',
      'about': 'About PhytoSense AI',
      'about_body':
          'A farmer-first plant monitoring platform built for clear, early field decisions.',
      'version': 'PhytoSense AI Version 9.0.0 • Brand Launch Edition',
      'devices_title': 'Sensor nodes',
      'devices_demo_note':
          'Simulation is active. Switch to ESP32 Live at any time when the physical node is ready.',
      'battery': 'Battery',
      'signal': 'Signal',
      'last_seen': 'Last seen just now',
      'hardware_ready': 'Hardware-ready architecture',
      'hardware_ready_body':
          'Every screen reads through SensorDataProvider. Simulation and ESP32 Live can switch without rebuilding the dashboard.',
      'settings_title': 'Settings',
      'language': 'Language',
      'language_subtitle': 'Changes immediately across the farmer interface',
      'english': 'English',
      'tamil': 'தமிழ்',
      'appearance': 'Appearance',
      'theme_picker_title': 'Choose your viewing mode',
      'theme_picker_body':
          'Dark mode now uses high-contrast farm colours designed for low-light field use.',
      'theme_preview_note':
          'The app changes immediately, so you can check readability before leaving Settings.',
      'system_theme': 'System',
      'light_theme': 'Light',
      'dark_theme': 'Dark',
      'units': 'Metric units',
      'units_subtitle': 'Show temperature in Celsius',
      'notifications': 'Farm alerts',
      'notifications_subtitle': 'Show important zone warnings',
      'demo_controls': 'Demo controls',
      'demo_scenario': 'Simulation scenario',
      'replay_onboarding': 'Replay onboarding',
      'scenario_healthy': 'Healthy farm',
      'scenario_dry': 'Dry soil',
      'scenario_overwatered': 'Overwatered',
      'scenario_heat_stress': 'Heat stress',
      'scenario_low_light': 'Low light',
      'scenario_critical': 'Critical combination',
      'scenario_offline': 'Network offline',
      'scenario_sensor_fault': 'Sensor fault',
      'previous': 'Previous',
      'finish': 'Finish',
      'waiting': 'Waiting',
      'plant_signal': 'Plant signal',
      'metric_signal': 'Signal',
      'analysis_method_note':
          'Method: explainable multi-sensor rules + recent trend cross-checking.',
      'ai_early_water_stress': 'Early moisture decline detected',
      'ai_early_water_stress_explanation':
          'Moisture is falling quickly even though it has not yet reached the critical threshold.',
      'ai_early_water_stress_action':
          'Inspect this zone early and confirm the soil condition before the crop shows visible stress.',
      'evidence_falling_soil':
          'The six most recent readings show a moisture drop of at least 10 percentage points.',
      'ai_signal_stress': 'Plant-response change detected',
      'ai_signal_stress_explanation':
          'The plant-signal index and soil moisture are both below their preferred ranges.',
      'ai_signal_stress_action':
          'Check electrode contact and inspect the plant before changing field practice.',
      'evidence_signal_crosscheck':
          'A low plant-signal index was cross-checked against reduced soil moisture.',
      'source_control': 'Data source',
      'source_control_body':
          'Choose exactly where every dashboard, chart, insight and alert receives its values.',
      'choose_data_source': 'Choose data source',
      'simulation_mode': 'Simulation demo',
      'esp32_live': 'ESP32 live',
      'simulation_description':
          'Safe presentation mode with realistic, controllable farm scenarios. Values are clearly labelled as simulated.',
      'esp32_description':
          'Polls the configured ESP32 node over the local network and validates every reading before use.',
      'source_demo_badge': 'DEMO',
      'source_live_badge': 'LIVE',
      'simulation_active_scenario': 'Scenario: {value}',
      'live_data_connected': 'Receiving validated ESP32 readings',
      'live_data_waiting': 'Waiting for the configured ESP32 node',
      'connecting_sensor': 'Connecting to sensor node',
      'connecting_sensor_body':
          'PhytoSense AI is requesting the first validated reading.',
      'configure_esp32': 'ESP32 connection',
      'configure_esp32_body':
          'Enter the address shown by the ESP32. The app expects /api/status and /api/data.',
      'esp32_endpoint': 'ESP32 base address',
      'endpoint_invalid': 'Enter a valid http:// or https:// address.',
      'save_and_test': 'Save and test connection',
      'testing_connection': 'Testing connection…',
      'connection_test_success':
          'ESP32 responded successfully. Live mode is ready.',
      'connection_test_failed':
          'No response. Check power, Wi-Fi, address and the ESP32 API.',
      'hardware_unreachable': 'The ESP32 could not be reached.',
      'hardware_invalid_data':
          'The ESP32 returned invalid or out-of-range data.',
      'devices_live_note':
          'ESP32 live mode is selected. Readings are checked for valid ranges before they reach the farmer interface.',
      'device_diagnostics': 'Node diagnostics',
      'diagnostic_provider': 'Active provider',
      'diagnostic_connection': 'Connection',
      'diagnostic_data_quality': 'Data quality',
      'about_settings_title': 'Learn how PhytoSense AI works',
      'about_settings_body':
          'Mission, engineering architecture, farmer design and interactive farm-impact estimator',
      'about_mission_title': 'Our mission',
      'about_mission_body':
          'PhytoSense AI is an intelligent agricultural monitoring platform that transforms field and crop sensor data into clear, actionable insights for farmers.',
      'impact_title': 'Farm impact & savings estimator',
      'impact_subtitle':
          'See what earlier detection could be worth in rupees for one crop season.',
      'impact_projection_badge': 'Illustrative projection',
      'impact_area_chip': '{value} acres',
      'impact_loss_prevented': 'Potential loss prevented',
      'impact_input_savings': 'Estimated input savings',
      'impact_net_benefit': 'First-season net benefit',
      'impact_benefit_cost': 'Benefit-to-cost ratio',
      'impact_season_value': 'Estimated seasonal crop value',
      'impact_value_at_risk': 'Crop value at risk',
      'impact_gross_benefit': 'Gross projected benefit',
      'impact_system_cost': 'Estimated system cost',
      'impact_adjust_title': 'Adjust the farm assumptions',
      'impact_adjust_body':
          'Use your own acreage, crop value and risk estimates for a more relevant result.',
      'impact_area': 'Monitored farm area',
      'impact_acres_value': '{value} acres',
      'impact_crop_value_per_acre': 'Crop value per acre per season',
      'impact_loss_risk': 'Seasonal crop value at risk',
      'impact_preventable_share': 'Share of at-risk loss caught early',
      'impact_savings_per_acre': 'Input savings per acre',
      'impact_cost_input': 'One-node system cost',
      'impact_reset': 'Reset demonstration example',
      'impact_disclaimer':
          'Projection only—not a guaranteed farmer profit or a measured competition result. It uses the assumptions above. Replace them with field records, crop prices and repeated trial evidence before making a real-world savings claim.',
      'about_how_title': 'How it works',
      'about_how_body':
          'The platform converts raw farm measurements into a structured decision-support workflow.',
      'about_how_1':
          'A sensor node measures soil moisture, temperature, humidity, light and a plant-signal index.',
      'about_how_2':
          'The selected provider supplies either clearly marked simulation data or validated ESP32 readings.',
      'about_how_3':
          'Explainable analysis cross-checks thresholds, sensor combinations and recent trends.',
      'about_how_4':
          'Farmers receive a plain-language reason, confidence level and practical inspection step.',
      'about_engineering_title': 'Engineering architecture',
      'about_engineering_body':
          'PhytoSense AI separates data collection from product logic so hardware can evolve without rebuilding the farmer experience.',
      'about_engineering_1':
          'SensorDataProvider is the single contract used by dashboards, charts, analysis and alerts.',
      'about_engineering_2':
          'Simulation and ESP32 providers can be switched at runtime without restarting the app.',
      'about_engineering_3':
          'Timeouts, invalid JSON and out-of-range measurements become clear connection states instead of crashes.',
      'about_farmer_title': 'Designed for farmers',
      'about_farmer_body':
          'The main workflow keeps technical complexity out of the way while advanced details remain available when needed.',
      'about_farmer_1':
          'English and Tamil language support with large, clear status cards.',
      'about_farmer_2':
          'Actions are written as field checks, not unexplained technical alarms.',
      'about_farmer_3':
          'Local-network operation avoids making cloud access a requirement for the prototype.',
      'about_responsible_title': 'Responsible decision support',
      'about_responsible_body':
          'PhytoSense AI does not claim to replace crop experts or direct field inspection. It shows evidence, identifies uncertainty and asks the farmer to verify conditions before acting.',
      'about_build_status':
          'PhytoSense AI 9.0 • Farmer/Judge experiences • Isolated ESP32 workspace • Natural voice • Presentation ready',
      'competition_center': 'Competition Center',
      'competition_center_subtitle':
          'Project case, evidence readiness and judge presentation',
      'judge_ready_workspace': 'PRESENTATION WORKSPACE',
      'competition_hero_title':
          'One clear story—from field problem to scalable solution',
      'competition_hero_body':
          'Use this area to explain the innovation, demonstrate the system and answer technical questions without crowding the farmer dashboard.',
      'start_judge_demo': 'Start guided judge demo',
      'project_case': 'Problem and solution',
      'problem_title': 'The field problem',
      'problem_body':
          'Plant stress can begin before visible symptoms. Manual checks may be late, inconsistent or difficult across multiple farm zones.',
      'solution_title': 'The PhytoSense AI approach',
      'solution_body':
          'Affordable sensor nodes feed a farmer-first app that detects unusual patterns, explains the evidence and recommends what to inspect next.',
      'innovation_pillars': 'Innovation pillars',
      'pillar_explainable': 'Explainable',
      'pillar_explainable_body':
          'Every insight shows its evidence and confidence instead of hiding behind an AI label.',
      'pillar_accessible': 'Accessible',
      'pillar_accessible_body':
          'Tamil and English workflows turn sensor data into practical farmer language.',
      'pillar_resilient': 'Presentation-safe',
      'pillar_resilient_body':
          'Simulation remains available when hardware or network conditions are unavailable.',
      'pillar_scalable': 'Scalable',
      'pillar_scalable_body':
          'The same provider contract supports one prototype node or a future multi-zone deployment.',
      'system_architecture': 'System architecture',
      'architecture_sense': 'Sense',
      'architecture_sense_body':
          'The node measures the conditions surrounding the crop and the normalized plant-signal channel.',
      'architecture_connect': 'Connect',
      'architecture_connect_body':
          'ESP32 exposes a small local HTTP API; the app polls it with validation and fault handling.',
      'architecture_understand': 'Understand',
      'architecture_understand_body':
          'The analysis engine combines current thresholds, recent direction and multi-sensor agreement.',
      'architecture_act': 'Act',
      'architecture_act_body':
          'The farmer receives an urgency level, evidence and a safe next inspection step.',
      'deployment_impact': 'Deployment and impact',
      'impact_prototype_scope': 'Competition prototype',
      'impact_one_node': 'One-node deployment design',
      'impact_connectivity': 'Connectivity',
      'impact_local_first': 'Local-first; no cloud required',
      'impact_scale_path': 'Scale path',
      'impact_add_nodes': 'Add nodes by field and zone',
      'impact_decision_model': 'Field action',
      'impact_farmer_control': 'Farmer confirmation required',
      'evidence_lab': 'Evidence and validation',
      'validation_status': 'PhytoSense AI 9.0 delivery status',
      'validation_transparency':
          'Every software capability shown in this release is complete. Hardware connection and field evidence tools are ready without being misrepresented as measured results.',
      'validation_app': 'Farmer app and simulation scenarios',
      'validation_api': 'ESP32 API contract and provider switching',
      'validation_hardware': 'ESP32 integration contract and node diagnostics',
      'validation_field_trials': 'Repeatable field-evidence recording workflow',
      'status_complete': 'Complete',
      'status_ready': 'Ready',
      'validation_note':
          'The Ultimate UI application release is complete. Farmer and Judge experiences are responsive, Demo and physical-node workspaces remain isolated, and validation, diagnostics, trials, calibration and evidence workflows are built in.',
      'judge_questions': 'Questions judges may ask',
      'judge_q_ai': 'What exactly is the AI?',
      'judge_a_ai':
          'PhytoSense AI uses transparent multimodal decision support: the camera measures visible colour patterns, then crop, electrode, sensor and fresh-weather evidence rank potential issue types. The shown percentage is a rule-based match score—not accuracy or a confirmed diagnosis. A validated trained model requires labelled field data and controlled accuracy testing.',
      'judge_q_novel': 'What is different from a normal IoT dashboard?',
      'judge_a_novel':
          'PhytoSense AI connects farm hierarchy, source-independent sensing, plant-response monitoring, fault validation and explainable farmer actions instead of only displaying raw numbers.',
      'judge_q_scale': 'How can one node scale to a farm?',
      'judge_a_scale':
          'Every node follows the same API and SensorDataProvider contract. New node IDs can be assigned to fields and zones without rewriting charts, alerts or analysis.',
      'judge_q_false_alert': 'How are false alerts handled?',
      'judge_a_false_alert':
          'Readings are range-validated, sensor conditions are cross-checked, alerts are rate-limited and the farmer is always asked to inspect the crop before acting.',
      'presentation_mode': 'Guided presentation',
      'presentation_problem_title': 'Start with the farmer problem',
      'presentation_problem_body':
          'Explain the pain before showing the technology.',
      'presentation_problem_1':
          'Stress may develop before symptoms are easy to see.',
      'presentation_problem_2':
          'Farmers need clear early guidance, not another screen full of numbers.',
      'presentation_system_title': 'Show the complete system',
      'presentation_system_body':
          'PhytoSense AI is an end-to-end monitoring architecture, not a disconnected app mock-up.',
      'presentation_system_1':
          'One ESP32 node connects through a documented local API.',
      'presentation_system_2':
          'The same app can switch to simulation without changing the farmer workflow.',
      'presentation_system_3':
          'Fields, zones, alerts, charts and analysis all share the provider abstraction.',
      'presentation_intelligence_title': 'Show the farmer intelligence suite',
      'presentation_intelligence_body':
          'One app combines multiple evidence sources without making unsupported claims.',
      'presentation_intelligence_1':
          'Camera screening combines local leaf patterns with crop, electrode, sensor and weather evidence to rank what to inspect first.',
      'presentation_intelligence_2':
          'Weather and soil moisture are cross-checked before irrigation guidance appears.',
      'presentation_intelligence_3':
          'Tamil/English voice, offline storage and growth-stage management support real farm use.',
      'presentation_demo_title': 'Demonstrate a changing condition',
      'presentation_demo_body':
          'Use the console below to show healthy conditions, early stress and an urgent combination.',
      'presentation_demo_1':
          'Point out that the data source is always clearly labelled.',
      'presentation_demo_2':
          'Show how the insight explains why it appeared and what the farmer should inspect.',
      'presentation_ai_title': 'Explain the intelligence honestly',
      'presentation_ai_body':
          'A transparent system is stronger than an unsupported accuracy claim.',
      'presentation_ai_1':
          'Current values, recent direction and sensor agreement affect the result.',
      'presentation_ai_2':
          'The evidence workflow records labelled hardware observations for measured evaluation and responsible model improvement.',
      'presentation_impact_title': 'Finish with practical impact',
      'presentation_impact_body':
          'The goal is earlier inspection, clearer decisions and an affordable path from one node to many zones.',
      'presentation_impact_1': 'Farmer-first English and Tamil interface.',
      'presentation_impact_2':
          'Local operation and low-cost controller architecture.',
      'presentation_impact_3':
          'No automatic irrigation or unsafe action without farmer confirmation.',
      'demo_console': 'Presentation demo console',
      'demo_console_body':
          'Choose a controlled scenario. This never pretends that simulated values came from hardware.',
      'switch_to_demo': 'Switch to simulation demo',
      'scan_leaf': 'Scan leaf',
      'irrigation_short': 'Irrigation',
      'weather_short': 'Weather',
      'leaf_screening_title': 'PhytoSense AI Vision — Leaf screening',
      'leaf_screening_menu_body':
          'Use the camera for explainable on-device disease-risk screening.',
      'leaf_screening_hero': 'Camera-assisted leaf check',
      'leaf_screening_hero_body':
          'Combine the leaf photo with plant-electrode, sensor and weather evidence without uploading the photo.',
      'confirm_crop_title': 'Confirm the crop before screening',
      'confirm_crop_body':
          'PhytoSense AI uses the active field as a suggestion. Select the crop in the photo so an unrelated disease list is never forced onto the result.',
      'select_crop': 'Crop shown in the photo',
      'confirm_crop_checkbox':
          'I confirm this photo belongs to the selected crop',
      'crop_not_auto_detected':
          'The on-device engine validates leaf-like evidence but does not claim to identify crop species automatically.',
      'crop_confirmation_required':
          'Confirm the crop before taking or choosing a photo.',
      'take_leaf_photo': 'Take photo',
      'choose_leaf_photo': 'Gallery',
      'leaf_image_invalid':
          'This image could not be analysed. Retake it in clear daylight with one leaf in focus.',
      'leaf_image_too_small':
          'The image is too small. Take a closer, higher-resolution photo of one leaf.',
      'leaf_image_too_dark':
          'The image is too dark for reliable screening. Retake it in even daylight.',
      'leaf_image_too_bright':
          'The image is overexposed. Move out of harsh glare and retake the leaf photo.',
      'leaf_image_no_detail':
          'The image has too little usable detail. Hold the camera steady and focus on one leaf.',
      'leaf_image_no_leaf':
          'No reliable leaf-like area was found. Use a close photo containing one crop leaf, not an unrelated object or landscape.',
      'leaf_camera_unavailable':
          'The camera or photo picker is unavailable on this device. Try the gallery or use the Android app.',
      'analyzing_leaf':
          'Analysing the photo and cross-checking crop, electrode, sensor and weather evidence…',
      'photo_guide_title': 'For a reliable screening photo',
      'photo_guide_light': 'Use bright, even daylight without harsh shadows.',
      'photo_guide_single_leaf':
          'Fill most of the frame with one representative leaf.',
      'photo_guide_focus':
          'Keep the leaf sharp and use a plain background when possible.',
      'leaf_result_retake': 'Retake recommended',
      'leaf_result_retake_body':
          'Too little leaf-green area was detected for a useful screening result.',
      'leaf_action_retake':
          'Retake the photo closer to one leaf in natural light.',
      'leaf_result_spot_risk': 'Possible lesion or leaf-spot pattern',
      'leaf_result_spot_risk_body':
          'A higher-than-normal brown-area pattern was detected. This may come from disease, damage or natural ageing.',
      'leaf_action_spot':
          'Inspect both leaf surfaces, isolate severely affected leaves and ask a local crop expert before treatment.',
      'leaf_result_yellowing': 'Yellowing pattern needs attention',
      'leaf_result_yellowing_body':
          'Visible yellow-area coverage is elevated. Water stress, nutrition and disease can look similar in a photo.',
      'leaf_action_yellowing':
          'Compare nearby plants, check soil moisture and seek crop-specific advice if yellowing spreads.',
      'leaf_result_low_risk': 'Low visible disease risk',
      'leaf_result_low_risk_body':
          'The image is mostly healthy green with limited yellow or brown area.',
      'leaf_action_monitor':
          'Continue monitoring and compare a new photo if symptoms change.',
      'leaf_green_area': 'Green',
      'leaf_yellow_area': 'Yellow',
      'leaf_brown_area': 'Brown',
      'leaf_safety_note':
          'PhytoSense AI ranks potential issue types for early inspection. It is not a laboratory diagnosis and does not choose pesticides or chemical quantities.',
      'disease_context_title': 'Evidence ready for this screening',
      'disease_prompt_context_title': 'Sensor-triggered field check',
      'disease_context_body':
          'PhytoSense AI will rank crop-specific possibilities using every fresh evidence source available.',
      'disease_prompt_context_body':
          'An unusual field signal opened this workflow. Photograph a representative affected leaf for a stronger cross-check.',
      'disease_context_no_sensor': 'Photo-only mode',
      'disease_context_weather_ready': 'Fresh weather ready',
      'disease_context_weather_unavailable': 'Weather not included',
      'disease_photo_prompt_title': 'Plant stress detected — take a photo',
      'disease_photo_prompt_body':
          'A {crop} reading moved outside the preferred range. Photograph a representative leaf to check potential disease, pest or environmental stress types.',
      'disease_take_photo_action': 'Take disease-check photo',
      'disease_trigger_electrode':
          'The plant-electrode response is outside its preferred band.',
      'disease_trigger_health':
          'The combined plant health score has fallen below the attention threshold.',
      'disease_trigger_dry_soil':
          'Soil moisture is low enough to affect leaf appearance.',
      'disease_trigger_wet_soil':
          'Soil moisture is unusually high and may increase root or disease stress.',
      'disease_trigger_heat':
          'Canopy temperature is above the preferred crop range.',
      'disease_trigger_humidity':
          'Humidity is high enough to support some leaf diseases.',
      'disease_trigger_weather':
          'Recent humidity and rain create a weather-linked disease-risk window.',
      'disease_potential_matches': 'Potential issue matches',
      'disease_crop_context': 'Crop-specific ranking for {crop}',
      'disease_ranking_explanation':
          'These are transparent match scores from leaf colour proportions, farmer observations and available field evidence. A higher score means “inspect this first,” not “confirmed disease.”',
      'disease_inconclusive_title': 'Evidence is inconclusive',
      'disease_inconclusive_body':
          'The leading score is low or too close to another possibility. Inspect several plants, take a clearer photo and ask a qualified agricultural expert before treatment.',
      'disease_top_match': 'Top potential match',
      'disease_match_score': '{value}% match',
      'disease_inspect_next': 'Inspect next',
      'disease_evidence_used': 'Evidence used in this result',
      'disease_evidence_camera': 'Leaf colour proportions from the photo',
      'disease_evidence_farmer_observations':
          'Farmer-confirmed visible symptoms',
      'disease_evidence_sensor': 'Soil, temperature, humidity and light',
      'disease_evidence_electrode': 'Abnormal plant-electrode response',
      'disease_evidence_weather': 'Fresh local forecast',
      'disease_evidence_weather_risk': 'Humidity + rain risk window',
      'disease_evidence_visual_balanced': 'Mostly balanced visible leaf colour',
      'disease_not_confirmed':
          'Potential match only—not a confirmed diagnosis. Compare several plants and ask a qualified local agricultural expert before choosing any treatment.',
      'disease_not_confirmed_short':
          'This is a potential match, not a confirmed diagnosis.',
      'disease_category_fungal': 'Fungal pattern',
      'disease_category_bacterial': 'Bacterial pattern',
      'disease_category_viral': 'Virus-linked pattern',
      'disease_category_phytoplasma': 'Phytoplasma-linked pattern',
      'disease_category_pest': 'Pest-linked pattern',
      'disease_category_stress': 'Environmental stress',
      'disease_category_clear': 'No clear concern',
      'disease_no_clear_match': 'No clear disease pattern',
      'disease_no_clear_match_reason':
          'The photographed leaf is mostly green and the available field signals are within their preferred bands.',
      'disease_no_clear_match_inspect':
          'Keep monitoring and compare the same area with a new photo if symptoms appear or spread.',
      'disease_rice_blast': 'Rice blast pattern',
      'disease_rice_blast_reason':
          'Brown lesion coverage combined with warm, humid or rainy conditions can resemble rice blast.',
      'disease_rice_blast_inspect':
          'Look for spindle-shaped spots with darker edges on several leaves and check whether the pattern is spreading.',
      'disease_rice_brown_spot': 'Rice brown spot pattern',
      'disease_rice_brown_spot_reason':
          'Brown spotting with yellowing or plant stress can resemble rice brown spot.',
      'disease_rice_brown_spot_inspect':
          'Check older leaves for many small round or oval brown spots and compare plants across the zone.',
      'disease_rice_blight': 'Rice bacterial leaf blight pattern',
      'disease_rice_blight_reason':
          'Yellow-brown damage together with wet, humid or rainy conditions can resemble bacterial leaf blight.',
      'disease_rice_blight_inspect':
          'Inspect leaf tips and edges for lengthening yellow-to-straw coloured areas across multiple plants.',
      'disease_rice_stem_borer': 'Rice stem-borer or pest-stress pattern',
      'disease_rice_stem_borer_reason':
          'Yellowing plus an unusual plant-electrode response may indicate pest-related stress, including stem damage.',
      'disease_rice_stem_borer_inspect':
          'Check the central shoot, leaf sheaths and nearby stems for wilting, entry marks or insect activity.',
      'disease_tomato_early_blight': 'Tomato early blight pattern',
      'disease_tomato_early_blight_reason':
          'Brown lesions with farmer-confirmed target-like rings are more consistent with early blight.',
      'disease_tomato_early_blight_inspect':
          'Check older lower leaves for expanding brown spots with ring-like patterns and yellow margins.',
      'disease_tomato_late_blight': 'Tomato late blight pattern',
      'disease_tomato_late_blight_reason':
          'Farmer-confirmed water-soaked dark lesions together with humid or wet conditions are more consistent with late blight.',
      'disease_tomato_late_blight_inspect':
          'Check several leaves and stems for rapidly expanding dark water-soaked areas, especially after wet weather.',
      'disease_tomato_bacterial_spot': 'Tomato bacterial spot pattern',
      'disease_tomato_bacterial_spot_reason':
          'Many small dark spots with farmer-confirmed yellow halos are more consistent with bacterial spot.',
      'disease_tomato_bacterial_spot_inspect':
          'Look closely for many small dark spots on leaves and fruit, then compare nearby plants.',
      'disease_tomato_leaf_curl':
          'Tomato leaf-curl or sap-feeding pest pattern',
      'disease_tomato_leaf_curl_reason':
          'Farmer-confirmed curling plus whiteflies, yellowing or unusual plant response is more consistent with leaf-curl or sap-feeding pest stress.',
      'disease_tomato_leaf_curl_inspect':
          'Check new growth for curling and inspect leaf undersides for tiny insects or clustered activity.',
      'tomato_symptoms_title': 'Advanced tomato symptom check',
      'tomato_symptoms_body':
          'Tomato is the competition reference crop. Confirm all five visible observations so the photo, sensors, electrode response and weather can be ranked together.',
      'tomato_question_rings':
          'Do brown spots contain circular target-like rings?',
      'tomato_question_water_soaked':
          'Are dark lesions wet-looking or water-soaked?',
      'tomato_question_yellow_halos': 'Do small dark spots have yellow halos?',
      'tomato_question_leaf_curl':
          'Are young leaves curling, twisting or becoming unusually small?',
      'tomato_question_whiteflies':
          'Are tiny whiteflies visible under the leaves?',
      'observation_yes': 'Yes',
      'observation_no': 'No',
      'observation_uncertain': 'Not sure',
      'rank_potential_issues': 'Rank potential issues',
      'disease_maize_leaf_blight': 'Maize leaf-blight pattern',
      'disease_maize_leaf_blight_reason':
          'Lengthening brown areas in warm, humid conditions can resemble maize leaf blight.',
      'disease_maize_leaf_blight_inspect':
          'Check several leaves for long grey-green or brown lesions that expand along the blade.',
      'disease_maize_downy_mildew': 'Maize downy-mildew pattern',
      'disease_maize_downy_mildew_reason':
          'Yellow striping with persistent humidity can resemble downy-mildew stress.',
      'disease_maize_downy_mildew_inspect':
          'Inspect young leaves for pale lengthwise stripes and unusual white growth, especially in the morning.',
      'disease_maize_fall_armyworm': 'Maize fall-armyworm damage pattern',
      'disease_maize_fall_armyworm_reason':
          'Irregular brown damage and plant stress can match chewing-pest activity.',
      'disease_maize_fall_armyworm_inspect':
          'Open the whorl and check for fresh holes, scraped tissue and insect activity across nearby plants.',
      'disease_groundnut_leaf_spot': 'Groundnut tikka leaf-spot pattern',
      'disease_groundnut_leaf_spot_reason':
          'Repeated brown spots with yellowing can resemble early or late leaf spot in groundnut.',
      'disease_groundnut_leaf_spot_inspect':
          'Compare older leaves for many circular dark spots, yellow margins and increasing leaf drop.',
      'disease_groundnut_rust': 'Groundnut rust pattern',
      'disease_groundnut_rust_reason':
          'Warm weather and brown-orange spotting can resemble groundnut rust.',
      'disease_groundnut_rust_inspect':
          'Check the lower leaf surface for small raised orange-brown pustules on several plants.',
      'disease_groundnut_leaf_miner': 'Groundnut leaf-miner damage pattern',
      'disease_groundnut_leaf_miner_reason':
          'Yellow-brown patches and unusual plant response can match leaf-miner feeding.',
      'disease_groundnut_leaf_miner_inspect':
          'Look for folded leaflets, pale mines and larvae or webbing inside damaged leaves.',
      'disease_cotton_bacterial_blight': 'Cotton bacterial-blight pattern',
      'disease_cotton_bacterial_blight_reason':
          'Angular brown areas after humid or rainy weather can resemble bacterial blight.',
      'disease_cotton_bacterial_blight_inspect':
          'Check whether spots follow leaf veins and appear angular on several cotton plants.',
      'disease_cotton_alternaria': 'Cotton Alternaria leaf-spot pattern',
      'disease_cotton_alternaria_reason':
          'Brown circular lesions with yellowing in warm conditions can resemble Alternaria leaf spot.',
      'disease_cotton_alternaria_inspect':
          'Inspect older leaves for enlarging round spots with visible rings or brittle centres.',
      'disease_cotton_sucking_pest': 'Cotton sucking-pest stress pattern',
      'disease_cotton_sucking_pest_reason':
          'Yellowing, curling and plant-response changes can match sap-feeding pest stress.',
      'disease_cotton_sucking_pest_inspect':
          'Check tender leaves and undersides for insects, sticky residue, curling or edge yellowing.',
      'disease_sugarcane_red_rot': 'Sugarcane red-rot stress pattern',
      'disease_sugarcane_red_rot_reason':
          'Progressive yellowing and poor plant response can be consistent with serious cane stress including red rot.',
      'disease_sugarcane_red_rot_inspect':
          'Inspect clumps for drying top leaves and consult a crop officer before cutting any suspect cane for confirmation.',
      'disease_sugarcane_smut': 'Sugarcane smut stress pattern',
      'disease_sugarcane_smut_reason':
          'Narrow yellowing leaves and reduced vigour can occur with smut-affected stools.',
      'disease_sugarcane_smut_inspect':
          'Check the growing point for an abnormal dark whip-like structure and compare nearby stools.',
      'disease_sugarcane_shoot_borer': 'Sugarcane early shoot-borer pattern',
      'disease_sugarcane_shoot_borer_reason':
          'Central-leaf yellowing and weak plant response can match shoot-borer damage.',
      'disease_sugarcane_shoot_borer_inspect':
          'Check young shoots for a drying central leaf and small entry holes near the lower stem.',
      'disease_banana_sigatoka': 'Banana Sigatoka leaf-spot pattern',
      'disease_banana_sigatoka_reason':
          'Increasing brown streaks and yellow areas under humid conditions can resemble Sigatoka.',
      'disease_banana_sigatoka_inspect':
          'Compare older leaves for narrow streaks that expand into dark spots with yellow margins.',
      'disease_banana_bunchy_top': 'Banana bunchy-top pattern',
      'disease_banana_bunchy_top_reason':
          'Yellowing and unusual new-leaf development can resemble virus-linked bunchy-top stress.',
      'disease_banana_bunchy_top_inspect':
          'Check new leaves for upright bunching, narrow growth and dark green streaks along veins.',
      'disease_banana_weevil': 'Banana weevil-related stress pattern',
      'disease_banana_weevil_reason':
          'Yellowing and reduced plant response can be associated with internal weevil damage.',
      'disease_banana_weevil_inspect':
          'Inspect the lower pseudostem and corm area for holes, tunnelling material or weakened plants.',
      'disease_coconut_leaf_rot': 'Coconut leaf-rot pattern',
      'disease_coconut_leaf_rot_reason':
          'Brown damaged areas during humid weather can resemble coconut leaf rot.',
      'disease_coconut_leaf_rot_inspect':
          'Inspect the youngest opened leaves for blackened, rotting or easily separating tissue.',
      'disease_coconut_bud_rot': 'Coconut bud-rot risk pattern',
      'disease_coconut_bud_rot_reason':
          'Yellow-brown crown damage with wet weather can indicate a serious bud-rot risk.',
      'disease_coconut_bud_rot_inspect':
          'From a safe ground position, check for a drooping or discoloured central spear and contact a trained worker for crown inspection.',
      'disease_coconut_caterpillar': 'Coconut leaf-eating caterpillar damage',
      'disease_coconut_caterpillar_reason':
          'Browning and reduced green leaf area can match leaf-eating pest damage.',
      'disease_coconut_caterpillar_inspect':
          'Check fallen or reachable leaflets for scraped tissue, webbing, droppings or clustered larvae.',
      'disease_brinjal_leaf_spot': 'Brinjal leaf-spot pattern',
      'disease_brinjal_leaf_spot_reason':
          'Circular brown lesions during humid conditions can resemble fungal leaf spot.',
      'disease_brinjal_leaf_spot_inspect':
          'Compare older leaves for expanding round spots with pale centres or yellow margins.',
      'disease_brinjal_little_leaf': 'Brinjal little-leaf pattern',
      'disease_brinjal_little_leaf_reason':
          'Yellowing and abnormal small new leaves can resemble phytoplasma-linked little-leaf stress.',
      'disease_brinjal_little_leaf_inspect':
          'Look for clusters of unusually small leaves, shortened internodes and reduced flowering.',
      'disease_brinjal_shoot_borer': 'Brinjal shoot-and-fruit-borer stress',
      'disease_brinjal_shoot_borer_reason':
          'Wilting shoots and plant-response changes can match borer activity.',
      'disease_brinjal_shoot_borer_inspect':
          'Check tender shoots and fruit for entry holes, droppings and sudden shoot wilting.',
      'disease_chilli_leaf_curl': 'Chilli leaf-curl pattern',
      'disease_chilli_leaf_curl_reason':
          'Yellowing, curling and heat-linked stress can resemble virus or vector-related leaf curl.',
      'disease_chilli_leaf_curl_inspect':
          'Inspect new growth for upward curling, shortened internodes and tiny insects underneath.',
      'disease_chilli_anthracnose': 'Chilli anthracnose pattern',
      'disease_chilli_anthracnose_reason':
          'Brown lesions under warm, humid conditions can resemble anthracnose.',
      'disease_chilli_anthracnose_inspect':
          'Check leaves and fruit for enlarging sunken dark spots, especially after wet weather.',
      'disease_chilli_thrips': 'Chilli thrips damage pattern',
      'disease_chilli_thrips_reason':
          'Yellowing, curling and dry-weather stress can match thrips feeding.',
      'disease_chilli_thrips_inspect':
          'Check young leaves and flowers for silvery scraping, distortion and tiny moving insects.',
      'disease_generic_leaf_spot': 'Possible fungal leaf-spot pattern',
      'disease_generic_leaf_spot_reason':
          'Brown lesion coverage with humid weather can match a general fungal leaf-spot pattern.',
      'disease_generic_leaf_spot_inspect':
          'Compare spot shape and spread on several upper and lower leaf surfaces.',
      'disease_generic_pest_damage': 'Possible pest-related damage',
      'disease_generic_pest_damage_reason':
          'Visible yellowing or damage plus an unusual plant response can indicate pest-related stress.',
      'disease_generic_pest_damage_inspect':
          'Inspect both sides of leaves, stems and nearby plants for insects, eggs, holes or curling.',
      'disease_generic_water_stress': 'Water or nutrient-stress pattern',
      'disease_generic_water_stress_reason':
          'Yellowing combined with very dry, wet or hot conditions may be environmental rather than infectious.',
      'disease_generic_water_stress_inspect':
          'Check root-zone moisture, compare multiple plants and review whether symptoms follow an irrigation pattern.',
      'listen_guidance': 'Listen to guidance',
      'voice_unavailable':
          'Voice guidance is unavailable on this device. The full guidance remains visible on screen.',
      'voice_quality': 'Natural voice guidance',
      'voice_quality_body':
          'Automatically prefers the highest-quality English India or Tamil voice installed on this device.',
      'voice_preview': 'Preview natural voice',
      'voice_preview_playing': 'Playing preview…',
      'voice_preview_sample':
          'Welcome to Vay Pulse. Your crop conditions look balanced. I will explain what needs attention and what you can inspect next.',
      'voice_selected': 'Selected device voice: {value}',
      'weather_center': 'Farm weather centre',
      'weather_menu_body':
          'Live five-day forecast with heavy-rain, dry-spell and disease-risk alerts.',
      'refresh_weather': 'Refresh weather',
      'change_weather_location': 'Change farm location',
      'weather_location_title': 'Forecast location',
      'weather_location_body':
          'Enter the farm name and coordinates. This keeps weather useful without requiring continuous phone location access.',
      'use_phone_location': 'Use phone GPS now',
      'detecting_location': 'Detecting current location…',
      'phone_location_privacy':
          'Location is requested only when you press this button. PhytoSense AI saves the coordinates as the forecast location and does not continuously track the phone.',
      'or_enter_manually': 'or enter the farm manually',
      'location_service_disabled': 'Turn on Location Services and try again.',
      'location_permission_denied':
          'Location permission was not allowed. You can still enter the farm coordinates manually.',
      'location_permission_denied_forever':
          'Location permission is blocked for PhytoSense AI. Enable it in device settings or enter coordinates manually.',
      'location_unavailable':
          'The phone could not determine its location. Move to an open area or enter the farm coordinates manually.',
      'weather_location_name': 'Farm or village name',
      'latitude': 'Latitude',
      'longitude': 'Longitude',
      'weather_location_invalid':
          'Enter a name and valid latitude (-90 to 90) and longitude (-180 to 180).',
      'save_weather_location': 'Save and refresh forecast',
      'loading_weather': 'Loading the latest farm forecast…',
      'weather_unavailable':
          'Live weather is unavailable. Connect to the internet and try again.',
      'weather_cached':
          'Showing the last saved forecast while the network is unavailable.',
      'weather_stale':
          'The saved forecast is more than 12 hours old, so it is displayed for reference but excluded from alerts and irrigation advice.',
      'five_day_forecast': 'Five-day forecast',
      'weather_alert_note':
          'PhytoSense AI combines rain, humidity and temperature to create early farm alerts. Always confirm local field conditions.',
      'weather_attribution': 'Forecast data: Open-Meteo',
      'weather_risk_heavy_rain': 'Heavy rain risk',
      'weather_risk_heavy_rain_body':
          'High rain probability or accumulation is forecast. Check drainage and protect vulnerable seedlings.',
      'weather_risk_disease': 'Weather-linked disease risk',
      'weather_risk_disease_body':
          'High humidity and rainfall can favour fungal disease. Inspect leaves early and improve airflow where practical.',
      'weather_risk_dry': 'Dry-spell watch',
      'weather_risk_dry_body':
          'Several low-rain days are forecast. Monitor soil moisture and plan irrigation checks.',
      'weather_risk_clear': 'No major weather risk detected',
      'weather_risk_clear_body':
          'The current five-day forecast does not cross PhytoSense AI alert thresholds.',
      'wind': 'Wind',
      'degrees_celsius': 'degrees Celsius',
      'rain_probability': 'Rain probability',
      'weekday_1': 'Mon',
      'weekday_2': 'Tue',
      'weekday_3': 'Wed',
      'weekday_4': 'Thu',
      'weekday_5': 'Fri',
      'weekday_6': 'Sat',
      'weekday_7': 'Sun',
      'irrigation_advisor': 'Smart irrigation advisor',
      'irrigation_menu_body':
          'Combine soil readings and rain forecast into a safe farmer action.',
      'smart_irrigation': 'Weather-aware irrigation',
      'smart_irrigation_body':
          'Sensor evidence and forecast risk are checked together before advice is shown.',
      'irrigation_waiting': 'Waiting for a sensor reading',
      'irrigation_waiting_body':
          'Irrigation advice needs a validated soil-moisture reading.',
      'irrigation_waiting_action':
          'Check the sensor connection or use a clearly labelled simulation scenario.',
      'irrigation_no_sensor_evidence':
          'No validated soil reading is available yet.',
      'irrigation_delay': 'Delay irrigation and recheck',
      'irrigation_delay_body':
          'Rain is likely soon and soil moisture is not critically low.',
      'irrigation_delay_action':
          'Delay watering, inspect drainage and recheck after the forecast window.',
      'irrigation_rain_evidence':
          'Rain forecast and soil moisture were cross-checked.',
      'irrigation_urgent': 'Urgent moisture check',
      'irrigation_urgent_body':
          'Soil moisture is extremely low and the crop may be under water stress.',
      'irrigation_urgent_action':
          'Inspect the root zone now and irrigate according to crop practice if the reading is confirmed.',
      'irrigation_dry_evidence':
          'Validated soil moisture is below the urgent threshold.',
      'irrigation_recommended': 'Irrigation likely needed',
      'irrigation_recommended_body':
          'Soil moisture is below the preferred range and no strong rain signal is cancelling the advice.',
      'irrigation_recommended_action':
          'Inspect the root zone and plan irrigation during a cooler period if dryness is confirmed.',
      'irrigation_low_evidence':
          'Soil moisture is below the preferred operating range.',
      'irrigation_stop': 'Pause irrigation',
      'irrigation_stop_body':
          'Soil moisture is very high and additional water could increase root stress.',
      'irrigation_stop_action':
          'Pause watering, inspect drainage and check again before the next cycle.',
      'irrigation_wet_evidence':
          'Soil moisture is above the high-moisture threshold.',
      'irrigation_paddy_water': 'Maintain the planned paddy water level',
      'irrigation_paddy_water_body':
          'High soil moisture is expected for flooded rice and does not prove overwatering.',
      'irrigation_paddy_water_action':
          'Inspect standing-water depth and field drainage before adding or releasing water.',
      'irrigation_paddy_water_evidence':
          'Rice-field context prevented a false generic overwatering warning; the probe measures soil moisture, not water depth.',
      'irrigation_balanced': 'No irrigation needed now',
      'irrigation_balanced_body':
          'Current soil moisture is within the preferred monitoring range.',
      'irrigation_balanced_action':
          'Continue monitoring and review the next weather update.',
      'irrigation_balanced_evidence':
          'Sensor and forecast evidence do not indicate an urgent water action.',
      'irrigation_confirmation_note':
          'PhytoSense AI provides decision support only. A farmer must confirm the field condition before irrigation; the app never starts pumps automatically.',
      'offline_sync_title': 'Offline data and sync',
      'offline_sync_menu_body':
          'Keep readings on the phone and upload them later when a server is configured.',
      'offline_first': 'Built for unreliable connectivity',
      'offline_first_body':
          'Validated ESP32 readings are queued locally first, so temporary internet loss does not erase field evidence. Demo readings are never uploaded.',
      'pending_records': 'Pending records',
      'local_history_records': 'Chart history',
      'last_sync': 'Last sync',
      'never': 'Never',
      'sync_server': 'Synchronization server',
      'sync_server_body':
          'Optional: enter the base URL of your farm or competition backend. PhytoSense AI sends batches to /api/sync.',
      'sync_endpoint': 'Server base URL',
      'sync_endpoint_saved': 'Synchronization endpoint saved.',
      'save_endpoint': 'Save endpoint',
      'sync_now': 'Synchronize now',
      'syncing_now': 'Synchronizing…',
      'sync_success': 'All available records are synchronized.',
      'sync_failed':
          'Synchronization failed. Records remain safe on this device for a later retry.',
      'sync_endpoint_required':
          'Add a synchronization server first. Until then, records remain safely queued locally.',
      'sync_privacy_note':
          'The queue stores numeric sensor readings and source labels, not leaf photos. Data is removed from the pending queue only after a successful server response.',
      'crop_management': 'PhytoSense Farm — Crop management',
      'crop_management_menu_body':
          'Update field crops and zone growth stages used by farmer guidance.',
      'crop_management_body':
          'Keep each field and zone accurate. Changes are saved locally and remain available offline.',
      'field_crop': 'Field crop',
      'growth_stages': 'Zone growth stages',
      'stage_seedling': 'Seedling',
      'stage_vegetative': 'Vegetative',
      'stage_maturity': 'Maturity',
      'alert_heavy_rain': 'Heavy rain preparation',
      'alert_heavy_rain_message':
          'Heavy rain is forecast. Check drainage and protect vulnerable crop areas.',
      'alert_disease_risk': 'Weather-linked disease watch',
      'alert_disease_risk_message':
          'Humidity and rainfall may favour disease. Inspect representative leaves early.',
      'alert_dry_spell': 'Dry-spell forecast',
      'alert_dry_spell_message':
          'Several low-rain days are forecast. Monitor soil moisture closely.',
      'alert_low_battery': 'Sensor-node battery low',
      'alert_low_battery_message':
          'Charge or replace the node power source before readings stop.',
      'alert_weak_signal': 'Sensor-node signal weak',
      'alert_weak_signal_message':
          'Move the node or gateway, or inspect obstacles affecting the link.',
      'alert_abnormal_sensor': 'Abnormal sensor values',
      'alert_abnormal_sensor_message':
          'A reading failed validation. Inspect the sensor and wiring before acting on it.',
      'about_capabilities_title': 'PhytoSense AI capabilities',
      'about_capabilities_body':
          'PhytoSense AI joins sensing, crop-specific multimodal screening, weather and farmer guidance in one consistent workflow.',
      'about_capabilities_1':
          'Runtime switching between a physical ESP32 node and clearly labelled demonstration data.',
      'about_capabilities_2':
          'Multimodal camera, electrode, sensor and weather screening with crop-specific potential issue ranking.',
      'about_capabilities_3':
          'Weather-aware irrigation advice and automatic drought, heat, heavy-rain and disease-risk alerts.',
      'about_capabilities_4':
          'Offline reading queue, optional server synchronization, editable crops and growth stages, and historical charts.',
      'validation_camera': 'On-device multimodal disease-candidate screening',
      'validation_weather_voice': 'Live weather and bilingual voice guidance',
      'validation_offline_sync': 'Offline queue and configurable server sync',
      'validation_trained_model':
          'Crop-confirmed multi-crop screening and image rejection',
      'weather_source': 'Weather',
      'nav_device': 'Live node',
      'data_source_separation_note':
          'Demo and ESP32 readings use separate workspaces and histories. Switching never mixes their values.',
      'live_workspace_enabled':
          'ESP32 Live workspace enabled. Farm demo data is now hidden.',
      'demo_workspace_enabled':
          'Simulation workspace enabled. Live ESP32 values remain separate.',
      'live_node_dashboard': 'VayPulse Node • ESP32 Live',
      'live_session_badge': 'LIVE SESSION',
      'live_session_body':
          'A clean single-node workspace. Only validated readings from the configured ESP32 are shown here.',
      'live_node_name': 'VayPulse Node 01',
      'live_reference_crop': 'DEMO REFERENCE CROP',
      'tomato_reference_title': 'Tomato health monitoring',
      'live_health_body':
          'Health combines soil, climate and electrode evidence from this physical node. No simulation values are used.',
      'validated_reading': 'Validated sensor reading',
      'data_fresh': 'Fresh data',
      'data_delayed': 'Delayed data',
      'data_stale': 'Stale data',
      'waiting_validation': 'Waiting for validation',
      'range_validated': 'Range checked',
      'endpoint': 'Endpoint',
      'reconnect': 'Reconnect',
      'live_waiting_title': 'Waiting for the ESP32 node',
      'live_waiting_body':
          'Connect the phone and ESP32 to the required network, confirm the endpoint in Settings, then reconnect.',
      'electrode_input': 'Electrode input',
      'tomato_demo_ready': 'Tomato demonstration ready',
      'tomato_demo_ready_body':
          'Tomato has the deepest symptom questionnaire in this build. Confirm the crop, photograph one clear leaf and answer the field checks for a more defensible candidate ranking.',
      'profile_live_workspace': 'Single-node ESP32 workspace',
      'more_title_live': 'VayPulse Node & app',
      'engineering_center': 'Engineering Evidence Center',
      'engineering_center_menu_body':
          'Live pipeline, trials, calibration, farmer outcomes and judge report.',
      'engineering_center_body':
          'Technical proof is separated from the farmer dashboard so judges can inspect how every reading becomes evidence and action.',
      'engineering_evidence': 'Built to be examined',
      'engineering_evidence_subtitle':
          'Transparent architecture • measurable trials • responsible AI',
      'system_xray': 'Live System X-Ray',
      'system_xray_body':
          'Watch data move from ESP32 or demo provider through validation, fusion, reasoning, alerts and evidence.',
      'experiment_lab': 'Experiment Evidence Lab',
      'experiment_lab_body':
          'Record repeatable baseline, response and recovery trials with measured sensor evidence.',
      'calibration_wizard': 'Sensor Calibration Wizard',
      'calibration_wizard_body':
          'Capture stable baselines, detect noisy readings and save a transparent Sensor Trust Score.',
      'judge_report': 'One-tap Judge Report',
      'judge_report_body':
          'Generate a current engineering report containing system, evidence, calibration and limitations.',
      'feedback_evidence': 'Farmer Confirmation Evidence',
      'feedback_evidence_body':
          'Measure confirmed conditions, useful recommendations, recovery and false alerts.',
      'responsible_ai_card': 'Responsible-AI Model Card',
      'responsible_ai_card_body':
          'Document intended use, inputs, reasoning, limitations, privacy and validation.',
      'xray_live_pipeline': 'Live decision pipeline',
      'xray_live_pipeline_body':
          'Each stage reflects the active provider. A stage turns complete only when its required evidence exists.',
      'xray_source': 'Data acquisition',
      'xray_validation': 'Range and freshness validation',
      'xray_validation_complete':
          'Numeric ranges checked and timestamp accepted',
      'xray_fusion': 'Multimodal sensor fusion',
      'xray_fusion_detail':
          'Soil, climate, light and plant-electrode evidence are evaluated together.',
      'xray_reasoning': 'Explainable reasoning',
      'xray_action': 'Farmer alert and action',
      'xray_no_alert': 'No condition currently requires an alert',
      'xray_alert_ready': 'An alert and evidence trail are available',
      'xray_evidence': 'Offline evidence record',
      'xray_evidence_detail':
          '{trials} completed trials • {records} saved readings',
      'experiment_evidence_title': 'Measure instead of claiming',
      'experiment_evidence_body':
          'Record repeated observations under clearly named conditions. Demo trials remain labelled DEMO and live trials remain labelled LIVE.',
      'trial_name': 'Trial name',
      'trial_name_hint': 'Example: Healthy tomato baseline',
      'trial_started': 'Trial recording started.',
      'start_trial': 'Start recording trial',
      'recorded_trials': 'Recorded trials',
      'no_trials':
          'No completed trials yet. Record a baseline and repeated response trials before presenting measured performance.',
      'trial_recording': 'Recording sensor evidence',
      'samples': 'Samples',
      'minimum_health': 'Minimum health',
      'maximum_stress': 'Maximum stress',
      'cancel_trial': 'Cancel trial',
      'finish_trial': 'Finish trial',
      'trial_outcome': 'Observed outcome',
      'outcome_detected': 'Condition detected',
      'outcome_recovered': 'Recovery observed',
      'outcome_no_change': 'No meaningful change',
      'outcome_inconclusive': 'Inconclusive',
      'notes': 'Notes',
      'save_trial': 'Save trial evidence',
      'trial_minutes': '{value} min',
      'trial_samples': '{value} samples',
      'calibration_trust_title': 'Know when the sensor can be trusted',
      'calibration_trust_body':
          'Capture at least three stable readings. PhytoSense AI calculates consistency; this score is not laboratory certification.',
      'trust_score': 'Trust',
      'saved_calibration': 'Saved calibration profile',
      'calibration_samples_count': '{value} baseline samples',
      'calibration_step_connect': 'Connect and validate the node',
      'calibration_step_connect_body':
          'A current range-checked reading must be available.',
      'calibration_step_stabilize': 'Capture stable baseline samples',
      'calibration_step_stabilize_body':
          'Keep the node and plant conditions steady while capturing several readings.',
      'calibration_step_save': 'Calculate and save trust evidence',
      'calibration_step_save_body':
          'Variation across soil, climate, light and electrode inputs becomes a transparent consistency score.',
      'calibration_progress': '{value} of 5 recommended samples captured',
      'capture_sample': 'Capture sample',
      'save_calibration': 'Save calibration',
      'reset_samples': 'Reset samples',
      'calibration_saved': 'Calibration saved with {value}% consistency.',
      'calibration_note_title': 'Calibration integrity',
      'calibration_note_body':
          'The score measures short-term reading stability only. Compare against reference instruments before claiming physical accuracy.',
      'report_snapshot_title': 'Presentation-ready evidence snapshot',
      'report_snapshot_body':
          'The report is generated from current app state, saved trials, farmer outcomes and calibration evidence—not hard-coded performance claims.',
      'copy_report': 'Copy complete report',
      'report_copied': 'Judge report copied to the clipboard.',
      'feedback_loop_title': 'Close the decision loop',
      'feedback_loop_body':
          'Farmers can record what they observed after an alert. These outcomes reveal useful guidance and false alerts without pretending they are model accuracy.',
      'feedback_total': 'Recorded outcomes',
      'feedback_confirmed': 'Conditions confirmed',
      'feedback_useful': 'Recommendations useful',
      'feedback_false_alerts': 'False alerts',
      'record_feedback_how': 'How to record evidence',
      'record_feedback_how_body':
          'Open Alerts and choose Record outcome below an alert after inspecting the plant.',
      'feedback_recorded': 'Outcome recorded',
      'record_outcome': 'Record outcome',
      'farmer_outcome_title': 'Farmer observation',
      'farmer_outcome_body':
          'Record only what was actually inspected. This feedback remains on the device unless an external synchronization system is configured.',
      'condition_confirmed': 'The condition was present',
      'recommendation_useful': 'The recommendation was useful',
      'plant_recovered': 'Recovery was observed later',
      'mark_false_alert': 'This appears to be a false alert',
      'save_outcome': 'Save observation',
      'model_card_title': 'PhytoSense AI decision-support model card',
      'model_card_intro':
          'A transparent description of how the app should and should not be used.',
      'model_intended_use': 'Intended use',
      'model_intended_use_body':
          'Early plant-stress screening and prioritization of possible crop-specific issues for farmer inspection. It supports decisions; it does not confirm disease or prescribe chemicals.',
      'model_inputs': 'Inputs and crop scope',
      'model_inputs_body':
          'Camera colour evidence, crop confirmation, soil moisture, temperature, humidity, light, plant-electrode signal and optional fresh weather. Ten Tamil Nadu crop contexts are available; tomato has the deepest symptom questionnaire.',
      'model_method': 'Reasoning method',
      'model_method_body':
          'Validated thresholds, recent trends, crop context and explainable evidence rules produce ranked potential candidates and recommended inspections.',
      'model_limitations': 'Known limitations',
      'model_limitations_body':
          'Lighting, leaf angle, sensor placement, crop variety and unmeasured causes can change results. Match percentages are rule-based scores, not measured accuracy or a confirmed diagnosis.',
      'model_privacy': 'Privacy and ownership',
      'model_privacy_body':
          'Leaf analysis runs on the device. Offline queues store numeric ESP32 readings, not photos. Demo readings are never uploaded.',
      'model_validation': 'Validation status',
      'model_validation_body':
          'Software flows and range checks are implemented. Physical accuracy must be established through calibration, repeated trials, expert labels and false-alert measurement.',
      'experience_mode': 'App experience',
      'experience_mode_body':
          'Keep daily farming simple or reveal the full engineering and competition workspace.',
      'farmer_mode': 'Farmer Mode',
      'farmer_mode_body':
          'Large actions, plain guidance and technical details only when requested.',
      'judge_mode': 'Judge Mode',
      'judge_mode_body':
          'Architecture, evidence, calibration, experiments and presentation tools.',
      'large_text': 'Larger text',
      'large_text_body':
          'Increase reading size while preserving responsive layouts.',
      'reduced_motion': 'Reduce motion',
      'reduced_motion_body':
          'Disable non-essential pulses and shorten visual transitions.',
      'onboarding_experience_title': 'Choose your experience',
      'onboarding_experience_body':
          'Farmer Mode keeps the app direct. Judge Mode reveals deeper technical evidence. You can change this anytime.',
      'observation_timeline': 'Plant Observation Timeline',
      'observation_timeline_menu_body':
          'Readings, alerts, trials, calibration and weather in one evidence trail.',
      'observation_timeline_body':
          'A source-isolated history of what the system measured, explained and recorded.',
      'timeline_latest_reading': 'Latest validated reading',
      'timeline_latest_reading_body':
          '{node} reported a plant health score of {health}.',
      'timeline_trial_body': '{samples} samples • {outcome}',
      'timeline_calibration': 'Calibration profile saved',
      'timeline_calibration_body':
          '{score}% consistency from {samples} baseline samples.',
      'timeline_weather': 'Weather context refreshed',
      'timeline_system': 'System',
      'timeline_empty': 'No observations in this view',
      'timeline_empty_body':
          'New readings, alerts and measured trials will appear here automatically.',
      'daily_briefing': 'Today’s plant briefing',
      'daily_briefing_waiting':
          'Waiting for a validated reading before preparing guidance.',
      'daily_alert_count': '{value} unread alerts',
      'farmer_next_action': 'What to do now',
      'hear_guidance': 'Hear guidance',
      'history': 'History',
      'preferred_soil_range': 'Preferred: 45–75%',
      'preferred_temperature_range': 'Preferred: 20–32°C',
      'preferred_humidity_range': 'Preferred: 45–80%',
      'preferred_light_range': 'Preferred: 35–90%',
      'preferred_signal_range': 'Compare with calibrated baseline',
      'preferred_stress_range': 'Lower is better',
      'view_sensor_details': 'View sensor details',
      'view_sensor_details_body':
          'Open the technical values, trends and preferred ranges.',
      'clear_alerts_confirm_title': 'Clear this alert session?',
      'clear_alerts_confirm_body':
          'This removes visible alerts. Saved farmer outcomes and experiment evidence are not deleted.',
      'alert_archived': 'Alert archived.',
      'undo': 'Undo',
      'screening_step_crop': 'Crop',
      'screening_step_photo': 'Photo',
      'screening_step_evidence': 'Evidence',
      'screening_step_result': 'Result',
      'reset_presentation': 'Reset presentation',
      'presentation_dashboard_title': 'One-screen decision dashboard',
      'presentation_dashboard_body':
          'Show the active source, plant condition, validated sensors and explainable reasoning together.',
      'presentation_dashboard_1':
          'A live snapshot updates without mixing Demo and ESP32 histories.',
      'presentation_dashboard_2':
          'Every recommendation remains connected to visible evidence.',
      'alert_needs_action': 'Needs action',
      'monitor': 'Monitor',
      'resolved': 'Resolved',
      'system': 'System',
      'command_search': 'Search app',
      'command_search_hint': 'Search PhytoSense AI',
      'command_no_results':
          'No matching tool found. Try “sensor”, “timeline” or “settings”.',
      'clear_search': 'Clear search',
      'presentation_mode_body':
          'A guided, resettable judge story with live evidence snapshots.',
    },
    'ta': {
      'tagline': 'உங்கள் பயிரை அறியுங்கள். உங்கள் மகசூலைக் காப்பாற்றுங்கள்.',
      'powered_by_vaypulse': 'VayPulse தொழில்நுட்ப ஆதரவுடன்',
      'nav_home': 'முகப்பு',
      'nav_fields': 'வயல்கள்',
      'nav_insights': 'பகுப்பாய்வு',
      'nav_alerts': 'எச்சரிக்கை',
      'nav_more': 'மேலும்',
      'next': 'அடுத்து',
      'get_started': 'தொடங்குங்கள்',
      'retry': 'மீண்டும் முயல்க',
      'cancel': 'ரத்து',
      'close': 'மூடு',
      'save': 'சேமி',
      'active': 'செயலில்',
      'online': 'இணைப்பில்',
      'offline': 'இணைப்பு இல்லை',
      'good': 'நன்று',
      'normal': 'இயல்பு',
      'low': 'குறைவு',
      'high': 'அதிகம்',
      'critical': 'அவசரம்',
      'excellent': 'மிகச் சிறப்பு',
      'watch': 'கவனம்',
      'loading_data': 'பண்ணை தரவு ஏற்றப்படுகிறது…',
      'no_data': 'இன்னும் அளவீடுகள் இல்லை',
      'last_updated_now': 'இப்போது புதுப்பிக்கப்பட்டது',
      'onboarding_monitor_title': 'ஒவ்வொரு வயலையும் அறியுங்கள்',
      'onboarding_monitor_body':
          'ஒவ்வொரு மண்டலத்திலும் மண் ஈரம், வெப்பநிலை, காற்று ஈரப்பதம் மற்றும் ஒளியை கண்காணிக்கவும்.',
      'onboarding_understand_title': 'செடியின் அழுத்தத்தை புரிந்துகொள்ளுங்கள்',
      'onboarding_understand_body':
          'சென்சார் மாற்றங்களை எளிய, விளக்கமான வயல் தகவல்களாகப் பெறுங்கள்.',
      'onboarding_act_title': 'சரியான நேரத்தில் செயல்படுங்கள்',
      'onboarding_act_body':
          'ஒரு மண்டலத்தை முன்கூட்டியே பார்த்து நம்பிக்கையுடன் முடிவு செய்ய எளிய அடுத்த படிகளைப் பெறுங்கள்.',
      'dashboard': 'பண்ணை நிலவரம்',
      'good_morning': 'காலை வணக்கம்',
      'good_afternoon': 'மதிய வணக்கம்',
      'good_evening': 'மாலை வணக்கம்',
      'farm_status_subtitle': 'இன்று உங்கள் பண்ணை கூறும் தகவல்கள் இங்கே.',
      'selected_zone': 'தேர்ந்தெடுத்த மண்டலம்',
      'health_score': 'ஆரோக்கிய மதிப்பெண்',
      'plant_health': 'செடி ஆரோக்கியம்',
      'zone_health': 'மண்டல ஆரோக்கியம்',
      'live_conditions': 'நேரடி நிலை',
      'soil_moisture': 'மண் ஈரப்பதம்',
      'temperature': 'வெப்பநிலை',
      'humidity': 'காற்று ஈரப்பதம்',
      'light': 'ஒளி',
      'stress': 'அழுத்தம்',
      'stable': 'நிலையாக உள்ளது',
      'needs_attention': 'கவனம் தேவை',
      'urgent_check': 'உடனே பார்க்கவும்',
      'ai_field_insight': 'PhytoSense AI தகவல்',
      'recommended_action': 'பரிந்துரைக்கப்பட்ட செயல்',
      'why_this': 'இந்த தகவலுக்கான காரணம்',
      'confidence': '{value}% நம்பகத்தன்மை',
      'edge_learning_plant': 'இந்தச் செடியை கற்றுக்கொள்கிறது',
      'edge_recovery_improving': 'நிலைகள் மேம்பட்டு வருகின்றன.',
      'edge_recovery_in_progress': 'மீட்பு நடைபெற்று வருகிறது.',
      'edge_recovery_progress': 'மீட்பு நடைபெற்று வருகிறது • {value}%',
      'edge_recovery_verified': 'மீட்பு உறுதிப்படுத்தப்பட்டது.',
      'edge_prediction_fallback':
          '{target} தற்போதைய போக்கு தொடர்ந்தால் சுமார் {minutes} நிமிடங்களில் எச்சரிக்கை வரம்பை அடையலாம்.',
      'decision_support_note':
          'முடிவு உதவி மட்டும் • செயல்படுவதற்கு முன் பயிரை நேரில் பாருங்கள்.',
      'zones_to_watch': 'கவனிக்க வேண்டிய மண்டலங்கள்',
      'all_zones_healthy': 'அனைத்து மண்டலங்களும் நல்ல வரம்பில் உள்ளன.',
      'view_fields': 'அனைத்து வயல்களையும் காண்க',
      'sensor_network_online': 'சென்சார் வலை இணைப்பில் உள்ளது',
      'sensor_network_offline': 'சென்சார் வலை இணைப்பு இல்லை',
      'sensor_network_error': 'சென்சார் தரவை சரிபார்க்கவும்',
      'offline_message':
          'நேரடி புதுப்பிப்பு நிறுத்தப்பட்டுள்ளது. கடைசியாக சேமித்த அளவீடுகள் காட்டப்படுகின்றன.',
      'error_message':
          'ஒரு சென்சார் தவறான தரவு கொடுத்தது. டெமோவை மீட்டமைத்து முயலுங்கள்.',
      'fields_and_zones': 'வயல்கள் & மண்டலங்கள்',
      'farm_structure': 'பண்ணை → வயல் → மண்டலம் → சென்சார் முனை',
      'fields': 'வயல்கள்',
      'zones': 'மண்டலங்கள்',
      'sensor_nodes': 'சென்சார் முனைகள்',
      'area_acres': '{value} ஏக்கர்',
      'crop': 'பயிர்',
      'crop_stage': 'பயிர் நிலை',
      'crop_rice': 'நெல்',
      'crop_tomato': 'தக்காளி',
      'crop_maize': 'மக்காச்சோளம்',
      'crop_groundnut': 'நிலக்கடலை',
      'crop_cotton': 'பருத்தி',
      'crop_sugarcane': 'கரும்பு',
      'crop_banana': 'வாழை',
      'crop_coconut': 'தென்னை',
      'crop_brinjal': 'கத்திரிக்காய்',
      'crop_chilli': 'மிளகாய்',
      'stage_tillering': 'தூர் கட்டும் நிலை',
      'stage_flowering': 'பூக்கும் நிலை',
      'stage_fruit_set': 'காய் பிடிக்கும் நிலை',
      'nodes': 'முனைகள்',
      'select_zone': 'மண்டலத்தைத் தேர்வு செய்க',
      'selected': 'தேர்ந்தெடுக்கப்பட்டது',
      'zone_details': 'மண்டல விவரம்',
      'no_farms': 'இன்னும் பண்ணைகள் சேர்க்கப்படவில்லை.',
      'not_monitored': 'இந்த முறையில் கண்காணிக்கப்படவில்லை',
      'insights_title': 'மாற்றங்கள் & பகுப்பாய்வு',
      'insights_subtitle':
          'என்ன மாறியது, அது ஏன் முக்கியம் என்பதைப் பாருங்கள்.',
      'time_24h': '24ம',
      'time_7d': '7நா',
      'time_30d': '30நா',
      'metric_health': 'ஆரோக்கியம்',
      'metric_soil': 'மண் ஈரம்',
      'metric_temp': 'வெப்பம்',
      'metric_humidity': 'காற்று ஈரம்',
      'average': 'சராசரி',
      'minimum': 'குறைந்தது',
      'maximum': 'அதிகம்',
      'trend_summary': 'மாற்ற சுருக்கம்',
      'trend_healthy': 'நிலைகள் விரும்பிய வரம்பிற்கு அருகில் உள்ளன.',
      'trend_attention':
          'சமீப அளவீடுகள் விரும்பிய வரம்பை மீறியுள்ளன. மண்டலத்தைப் பாருங்கள்.',
      'not_enough_history': 'வரைபடத்திற்கு மேலும் அளவீடுகள் தேவை.',
      'alerts_title': 'எச்சரிக்கைகள்',
      'alerts_subtitle':
          'வயல் பார்வை தேவைப்படக்கூடிய நிலைகள் மட்டும் இங்கே வரும்.',
      'all': 'அனைத்தும்',
      'warnings': 'கவனம்',
      'mark_all_read': 'அனைத்தையும் படித்ததாக குறி',
      'clear_alerts': 'எச்சரிக்கைகளை நீக்கு',
      'no_alerts': 'செயலில் எச்சரிக்கை இல்லை',
      'no_alerts_body':
          'கண்காணிக்கப்படும் மண்டலங்கள் எதிர்பார்த்த வரம்பில் உள்ளன.',
      'unread_count': '{value} படிக்காதவை',
      'alert_severe_dryness': 'கடுமையான வறட்சி கண்டறியப்பட்டது',
      'alert_severe_dryness_message':
          'மண் ஈரம் மிகக் குறைவு. இந்த முனையையும் பாசனத்தையும் சரிபார்க்கவும்.',
      'alert_low_moisture': 'மண் ஈரம் குறைவு',
      'alert_low_moisture_message':
          'மண் ஈரம் விரும்பிய வரம்பிற்கு கீழே உள்ளது. நீர் விடும் முன் மண்டலத்தைப் பாருங்கள்.',
      'alert_overwatering': 'மண் ஈரம் மிக அதிகம்',
      'alert_overwatering_message':
          'மண் அதிகமாக ஈரமாக உள்ளது. வடிகால் மற்றும் பாசனத்தை சரிபார்க்கவும்.',
      'alert_heat_stress': 'அதிக வெப்ப நிலை',
      'alert_heat_stress_message':
          'காற்று வெப்பம் விரும்பிய வரம்பை மீறியுள்ளது. பயிரை நேரில் பாருங்கள்.',
      'alert_low_light': 'ஒளி குறைவு',
      'alert_low_light_message':
          'இந்த மண்டலத்தில் ஒளி எதிர்பார்த்த அளவை விட குறைந்துள்ளது.',
      'ai_combined_stress': 'வறண்ட மற்றும் சூடான நிலை',
      'ai_combined_stress_explanation':
          'குறைந்த மண் ஈரமும் அதிக வெப்பமும் சேர்ந்து செடி அழுத்தத்தை உயர்த்தலாம்.',
      'ai_combined_stress_action':
          'மண்டலத்தை உடனே பார்த்து மண் மற்றும் பாசனக் குழாயை சரிபார்க்கவும்.',
      'ai_water_stress': 'நீர் அழுத்த அறிகுறி',
      'ai_water_stress_explanation':
          'தேர்ந்தெடுத்த மண்டலத்தில் மண் ஈரம் விரும்பிய வரம்பிற்கு கீழே உள்ளது.',
      'ai_water_stress_action':
          'இந்த முனைக்கு அருகிலுள்ள மண்ணை பார்த்த பிறகே நீர் விடவும்.',
      'ai_overwatering': 'அதிக ஈரம் இருக்கலாம்',
      'ai_overwatering_explanation':
          'மண் ஈரம் அதிகமாக உள்ளது; இது அதிக பாசனம் அல்லது மோசமான வடிகாலை குறிக்கலாம்.',
      'ai_overwatering_action':
          'வடிகாலை சரிபார்த்து, மண்ணைப் பார்க்கும் வரை அடுத்த பாசனத்தை நிறுத்தவும்.',
      'ai_paddy_water_expected': 'நெல் வயலின் நீர் நிலை இயல்பாக உள்ளது',
      'ai_paddy_water_expected_explanation':
          'கட்டுப்படுத்தப்பட்ட நீர் நிறைந்த நெல் வயலில் அதிக மண் ஈரம் இயல்பாக இருக்கலாம்; இதை மட்டும் அதிக பாசனமாக கருதவில்லை.',
      'ai_paddy_water_expected_action':
          'வயலில் நீரின் ஆழத்தையும் வடிகாலையும் பாருங்கள்; இந்த மண் சென்சார் நீரின் ஆழத்தை அளவிடாது.',
      'ai_heat_stress': 'வெப்ப அழுத்த அறிகுறி',
      'ai_heat_stress_explanation':
          'தேர்ந்தெடுத்த பயிர் மண்டலத்திற்கு வெப்பம் விரும்பிய வரம்பை மீறியுள்ளது.',
      'ai_heat_stress_action':
          'பயிரை பார்த்து, பாசன நேரத்தையும் மதிய வெப்பத் தாக்கத்தையும் சரிபார்க்கவும்.',
      'ai_low_light': 'ஒளி குறைவு அறிகுறி',
      'ai_low_light_explanation':
          'இந்த மண்டலத்தின் சமீப வரம்பை விட ஒளி குறைவாக உள்ளது.',
      'ai_low_light_action':
          'வயல் நடைமுறையை மாற்றும் முன் நிழல், மூடி அல்லது சென்சாரை சரிபார்க்கவும்.',
      'ai_healthy': 'நிலைகள் சமநிலையில் உள்ளன',
      'ai_healthy_explanation':
          'மண் ஈரம், வெப்பம், காற்று ஈரம் மற்றும் ஒளி நல்ல வரம்பில் உள்ளன.',
      'ai_healthy_action':
          'தற்போதைய பராமரிப்பைத் தொடர்ந்து பின்னர் மாற்றங்களை மீண்டும் பாருங்கள்.',
      'evidence_dry_hot': 'மண் ஈரமும் வெப்பமும் கவன வரம்பை கடந்துள்ளன.',
      'evidence_low_soil': 'மண் ஈரம் 30% கவன வரம்பிற்கு கீழே சென்றது.',
      'evidence_high_soil': 'மண் ஈரம் 88% கவன வரம்பிற்கு மேல் சென்றது.',
      'evidence_paddy_water':
          'தேர்ந்தெடுத்த பயிர் நெல் என்பதால் அதிக ஈர அளவீடு நெல் வயல் விதிகளுடன் புரிந்துகொள்ளப்பட்டது.',
      'evidence_high_temp': 'வெப்பம் 33°C கவன வரம்பிற்கு மேல் சென்றது.',
      'evidence_low_light': 'ஒளி 25% கவன வரம்பிற்கு கீழே சென்றது.',
      'evidence_balanced':
          'நான்கு அளவீடுகளும் விதி சார்ந்த நல்ல வரம்பில் உள்ளன.',
      'more_title': 'பண்ணை & செயலி',
      'farmer_profile': 'பண்ணை மேலாளர்',
      'demo_farm': 'டெமோ பண்ணை',
      'devices': 'சாதனங்கள்',
      'devices_subtitle': 'சென்சார் முனைகள் மற்றும் இணைப்பை காண்க',
      'settings': 'அமைப்புகள்',
      'settings_subtitle': 'தரவு மூலம், ESP32, மொழி மற்றும் தோற்றம்',
      'about': 'PhytoSense AI பற்றி',
      'about_body':
          'தெளிவான ஆரம்பகட்ட வயல் முடிவுகளுக்கான விவசாயி மைய செடி கண்காணிப்பு தளம்.',
      'version': 'PhytoSense AI Version 9.0.0 • Brand Launch Edition',
      'devices_title': 'சென்சார் முனைகள்',
      'devices_demo_note':
          'இப்போது simulation செயலில் உள்ளது. Physical node தயார் ஆனதும் ESP32 Live-க்கு மாறலாம்.',
      'battery': 'பேட்டரி',
      'signal': 'சிக்னல்',
      'last_seen': 'இப்போது தொடர்பில் இருந்தது',
      'hardware_ready': 'Hardware-ready architecture',
      'hardware_ready_body':
          'அனைத்து திரைகளும் SensorDataProvider வழியாக தரவைப் பெறுகின்றன; dashboard மாற்றாமல் Simulation மற்றும் ESP32 Live இடையே மாறலாம்.',
      'settings_title': 'அமைப்புகள்',
      'language': 'மொழி',
      'language_subtitle': 'விவசாயி இடைமுகம் முழுவதும் உடனே மாறும்',
      'english': 'English',
      'tamil': 'தமிழ்',
      'appearance': 'தோற்றம்',
      'theme_picker_title': 'பார்வை முறையைத் தேர்வு செய்க',
      'theme_picker_body':
          'Dark mode இப்போது குறைந்த வெளிச்ச வயல் பயன்பாட்டிற்கான high-contrast farm colours பயன்படுத்துகிறது.',
      'theme_preview_note':
          'App உடனே மாறும்; Settings-இலிருந்து வெளியேறும் முன் readability-ஐ பார்க்கலாம்.',
      'system_theme': 'சாதன அமைப்பு',
      'light_theme': 'வெளிச்சம்',
      'dark_theme': 'இருள்',
      'units': 'மெட்ரிக் அலகுகள்',
      'units_subtitle': 'வெப்பநிலையை செல்சியஸில் காட்டவும்',
      'notifications': 'பண்ணை எச்சரிக்கைகள்',
      'notifications_subtitle': 'முக்கிய மண்டல எச்சரிக்கைகளை காட்டவும்',
      'demo_controls': 'டெமோ கட்டுப்பாடுகள்',
      'demo_scenario': 'Simulation நிலை',
      'replay_onboarding': 'அறிமுகத்தை மீண்டும் காண்க',
      'scenario_healthy': 'ஆரோக்கியமான பண்ணை',
      'scenario_dry': 'வறண்ட மண்',
      'scenario_overwatered': 'அதிக பாசனம்',
      'scenario_heat_stress': 'வெப்ப அழுத்தம்',
      'scenario_low_light': 'ஒளி குறைவு',
      'scenario_critical': 'அவசர கலவை',
      'scenario_offline': 'வலை இணைப்பு இல்லை',
      'scenario_sensor_fault': 'சென்சார் கோளாறு',
      'previous': 'முந்தையது',
      'finish': 'முடி',
      'waiting': 'காத்திருக்கிறது',
      'plant_signal': 'செடி சிக்னல்',
      'metric_signal': 'சிக்னல்',
      'analysis_method_note':
          'முறை: பல சென்சார் விதிகள் மற்றும் சமீப மாற்றங்களை இணைத்து விளக்கும் பகுப்பாய்வு.',
      'ai_early_water_stress': 'மண் ஈரம் வேகமாக குறைகிறது',
      'ai_early_water_stress_explanation':
          'அவசர வரம்பை அடையும் முன்பே மண் ஈரம் வேகமாக குறைகிறது.',
      'ai_early_water_stress_action':
          'செடியில் வெளிப்படும் அறிகுறிக்கு முன் மண்ணை நேரில் சரிபார்க்கவும்.',
      'evidence_falling_soil':
          'சமீபத்திய ஆறு அளவீடுகளில் மண் ஈரம் குறைந்தது 10 புள்ளிகள் குறைந்துள்ளது.',
      'ai_signal_stress': 'செடி பதில் மாற்றம் கண்டறியப்பட்டது',
      'ai_signal_stress_explanation':
          'செடி சிக்னலும் மண் ஈரமும் நல்ல வரம்பிற்கு கீழே உள்ளன.',
      'ai_signal_stress_action':
          'வயல் முறையை மாற்றும் முன் electrode தொடர்பையும் செடியையும் பார்க்கவும்.',
      'evidence_signal_crosscheck':
          'குறைந்த செடி சிக்னல், குறைந்த மண் ஈரத்துடன் ஒப்பிடப்பட்டது.',
      'source_control': 'தரவு மூலம்',
      'source_control_body':
          'Dashboard, chart, insight மற்றும் alert மதிப்புகள் எங்கிருந்து வர வேண்டும் என்பதைத் தேர்ந்தெடுக்கவும்.',
      'choose_data_source': 'தரவு மூலத்தைத் தேர்வு செய்க',
      'simulation_mode': 'Simulation demo',
      'esp32_live': 'ESP32 நேரடி',
      'simulation_description':
          'விளக்கக்காட்சிக்கான கட்டுப்படுத்தக்கூடிய பண்ணை நிலைகள். இவை simulation மதிப்புகள் என்று தெளிவாக காட்டப்படும்.',
      'esp32_description':
          'உள்ளூர் வலையில் ESP32 தரவைப் பெற்று, பயன்படுத்தும் முன் ஒவ்வொரு அளவையும் சரிபார்க்கும்.',
      'source_demo_badge': 'DEMO',
      'source_live_badge': 'LIVE',
      'simulation_active_scenario': 'நிலை: {value}',
      'live_data_connected': 'ESP32 தரவு பெறப்படுகிறது',
      'live_data_waiting': 'ESP32 node இணைப்புக்காக காத்திருக்கிறது',
      'connecting_sensor': 'Sensor node இணைக்கப்படுகிறது',
      'connecting_sensor_body':
          'PhytoSense AI முதல் சரிபார்க்கப்பட்ட அளவீட்டை பெறுகிறது.',
      'configure_esp32': 'ESP32 இணைப்பு',
      'configure_esp32_body':
          'ESP32 காட்டும் address-ஐ இடுங்கள். /api/status மற்றும் /api/data தேவை.',
      'esp32_endpoint': 'ESP32 முகவரி',
      'endpoint_invalid': 'சரியான http:// அல்லது https:// முகவரியை இடுங்கள்.',
      'save_and_test': 'சேமித்து இணைப்பைச் சோதிக்கவும்',
      'testing_connection': 'இணைப்பு சோதிக்கப்படுகிறது…',
      'connection_test_success': 'ESP32 பதிலளித்தது. நேரடி முறை தயார்.',
      'connection_test_failed':
          'பதில் இல்லை. Power, Wi-Fi, address மற்றும் ESP32 API-ஐ சரிபார்க்கவும்.',
      'hardware_unreachable': 'ESP32-ஐ தொடர்பு கொள்ள முடியவில்லை.',
      'hardware_invalid_data': 'ESP32 தவறான அளவீடு அனுப்பியது.',
      'devices_live_note':
          'ESP32 நேரடி முறை தேர்ந்தெடுக்கப்பட்டுள்ளது. விவசாயி திரைக்கு முன் மதிப்புகள் சரிபார்க்கப்படும்.',
      'device_diagnostics': 'Node பரிசோதனை',
      'diagnostic_provider': 'செயலில் உள்ள provider',
      'diagnostic_connection': 'இணைப்பு',
      'diagnostic_data_quality': 'தரவு தரம்',
      'about_settings_title': 'PhytoSense AI எவ்வாறு செயல்படுகிறது',
      'about_settings_body':
          'நோக்கம், engineering architecture, விவசாயி வடிவமைப்பு மற்றும் interactive farm-impact estimator',
      'about_mission_title': 'எங்கள் நோக்கம்',
      'about_mission_body':
          'PhytoSense AI வயல் மற்றும் பயிர் sensor தரவை விவசாயிகளுக்கான தெளிவான, செயல்படுத்தக்கூடிய தகவலாக மாற்றும் அறிவார்ந்த வேளாண் கண்காணிப்பு தளம்.',
      'impact_title': 'வயல் impact மற்றும் savings estimator',
      'impact_subtitle':
          'ஒரு crop season-ல் early detection எவ்வளவு ரூபாய் பயன் தரலாம் என்று கணக்கிடுங்கள்.',
      'impact_projection_badge': 'விளக்கத்திற்கான projection',
      'impact_area_chip': '{value} ஏக்கர்',
      'impact_loss_prevented': 'தடுக்கக்கூடிய இழப்பு',
      'impact_input_savings': 'மதிப்பிடப்பட்ட input savings',
      'impact_net_benefit': 'முதல்-season net benefit',
      'impact_benefit_cost': 'Benefit-to-cost ratio',
      'impact_season_value': 'Season crop-ன் மதிப்பிடப்பட்ட மதிப்பு',
      'impact_value_at_risk': 'அபாயத்தில் உள்ள crop மதிப்பு',
      'impact_gross_benefit': 'மொத்த projected benefit',
      'impact_system_cost': 'மதிப்பிடப்பட்ட system cost',
      'impact_adjust_title': 'Farm assumptions-ஐ மாற்றுங்கள்',
      'impact_adjust_body':
          'உங்கள் acreage, crop value மற்றும் risk estimate-ஐ கொடுத்து பொருத்தமான முடிவைப் பாருங்கள்.',
      'impact_area': 'கண்காணிக்கப்படும் வயல் பரப்பு',
      'impact_acres_value': '{value} ஏக்கர்',
      'impact_crop_value_per_acre': 'ஒரு ஏக்கரின் ஒரு-season crop value',
      'impact_loss_risk': 'அபாயத்தில் உள்ள seasonal crop value',
      'impact_preventable_share':
          'Early detection மூலம் தடுக்கக்கூடிய risk share',
      'impact_savings_per_acre': 'ஒரு ஏக்கருக்கான input savings',
      'impact_cost_input': 'ஒரு-node system cost',
      'impact_reset': 'Demo example-ஐ reset செய்',
      'impact_disclaimer':
          'இது projection மட்டும்; guaranteed farmer profit அல்லது measured competition result அல்ல. மேலுள்ள assumptions பயன்படுத்தப்படுகின்றன. உண்மையான savings claim முன் field records, crop prices மற்றும் repeated trial evidence கொண்டு மாற்றவும்.',
      'about_how_title': 'எவ்வாறு செயல்படுகிறது',
      'about_how_body':
          'Raw farm அளவீடுகளை தெளிவான முடிவு உதவியாக மாற்றுகிறது.',
      'about_how_1':
          'Sensor node மண் ஈரம், வெப்பம், காற்று ஈரம், ஒளி மற்றும் செடி சிக்னலை அளக்கிறது.',
      'about_how_2':
          'Simulation அல்லது சரிபார்க்கப்பட்ட ESP32 தரவு தேர்ந்தெடுத்த provider வழியாக வருகிறது.',
      'about_how_3':
          'வரம்புகள், பல சென்சார் ஒப்பீடு மற்றும் சமீப மாற்றங்களை பகுப்பாய்வு செய்கிறது.',
      'about_how_4':
          'காரணம், நம்பகத்தன்மை மற்றும் அடுத்த வயல் பரிசோதனை படி காட்டப்படும்.',
      'about_engineering_title': 'Engineering architecture',
      'about_engineering_body':
          'Hardware மாறினாலும் விவசாயி UI-ஐ மீண்டும் கட்ட வேண்டாத வகையில் தரவும் product logic-மும் பிரிக்கப்பட்டுள்ளன.',
      'about_engineering_1':
          'Dashboard, chart, analysis மற்றும் alert அனைத்தும் SensorDataProvider contract-ஐ பயன்படுத்துகின்றன.',
      'about_engineering_2':
          'App restart இல்லாமல் Simulation மற்றும் ESP32 provider இடையே மாறலாம்.',
      'about_engineering_3':
          'Timeout, தவறான JSON மற்றும் தவறான அளவுகள் crash ஆகாமல் தெளிவான நிலையாக காட்டப்படும்.',
      'about_farmer_title': 'விவசாயிகளுக்காக வடிவமைப்பு',
      'about_farmer_body':
          'முக்கிய பயன்பாடு எளிமையாக இருக்கும்; தேவையானபோது advanced விவரங்களும் கிடைக்கும்.',
      'about_farmer_1': 'English மற்றும் தமிழ், பெரிய தெளிவான status cards.',
      'about_farmer_2':
          'Technical alarm அல்ல; நேரில் செய்ய வேண்டிய பரிசோதனையாக action எழுதப்பட்டுள்ளது.',
      'about_farmer_3':
          'Prototype உள்ளூர் வலையில் cloud இல்லாமலும் செயல்பட முடியும்.',
      'about_responsible_title': 'பொறுப்பான முடிவு உதவி',
      'about_responsible_body':
          'PhytoSense AI crop expert அல்லது நேரடி வயல் பரிசோதனைக்கு மாற்றாகாது. ஆதாரம் மற்றும் நிச்சயமின்மையை காட்டி, செயல்படும் முன் விவசாயி உறுதி செய்ய வேண்டும்.',
      'about_build_status':
          'PhytoSense AI 9.0 • Farmer/Judge experience • தனி ESP32 workspace • இயல்பான குரல் • Presentation தயார்',
      'competition_center': 'Competition Center',
      'competition_center_subtitle':
          'Project case, evidence readiness மற்றும் judge presentation',
      'judge_ready_workspace': 'PRESENTATION WORKSPACE',
      'competition_hero_title':
          'வயல் பிரச்சினையிலிருந்து scalable solution வரை ஒரே தெளிவான கதை',
      'competition_hero_body':
          'விவசாயி dashboard-ஐ சிக்கலாக்காமல் innovation, demonstration மற்றும் technical பதில்களை இங்கே காட்டலாம்.',
      'start_judge_demo': 'Judge demo தொடங்கு',
      'project_case': 'பிரச்சினை மற்றும் தீர்வு',
      'problem_title': 'வயல் பிரச்சினை',
      'problem_body':
          'கண்ணுக்கு தெரியும் அறிகுறிக்கு முன் செடி அழுத்தம் தொடங்கலாம். பல மண்டலங்களில் manual check தாமதமாகலாம்.',
      'solution_title': 'PhytoSense AI தீர்வு',
      'solution_body':
          'குறைந்த செலவு sensor node தரவை விளக்கி, காரணம் மற்றும் அடுத்த பரிசோதனை படியை விவசாயி செயலி காட்டுகிறது.',
      'innovation_pillars': 'Innovation அம்சங்கள்',
      'pillar_explainable': 'விளக்கமானது',
      'pillar_explainable_body':
          'ஒவ்வொரு insight-மும் evidence மற்றும் confidence காட்டும்.',
      'pillar_accessible': 'எளிதில் பயன்படுத்தலாம்',
      'pillar_accessible_body':
          'தமிழ் மற்றும் English வழியாக practical farmer guidance.',
      'pillar_resilient': 'Presentation பாதுகாப்பு',
      'pillar_resilient_body':
          'Hardware அல்லது network இல்லாதபோது simulation கிடைக்கும்.',
      'pillar_scalable': 'Scalable',
      'pillar_scalable_body':
          'ஒரு node முதல் பல farm zone வரை ஒரே provider contract.',
      'system_architecture': 'System architecture',
      'architecture_sense': 'அளவிடு',
      'architecture_sense_body':
          'Node பயிரைச் சுற்றிய நிலைகளையும் செடி சிக்னலையும் அளக்கிறது.',
      'architecture_connect': 'இணை',
      'architecture_connect_body':
          'ESP32 local HTTP API தருகிறது; app validation மற்றும் fault handling உடன் தரவைப் பெறுகிறது.',
      'architecture_understand': 'புரிந்துகொள்',
      'architecture_understand_body':
          'தற்போதைய வரம்பு, சமீப மாற்றம் மற்றும் பல சென்சார் ஒப்பீடு இணைக்கப்படுகிறது.',
      'architecture_act': 'செயல்படு',
      'architecture_act_body':
          'அவசரம், ஆதாரம் மற்றும் பாதுகாப்பான அடுத்த பரிசோதனை படி காட்டப்படும்.',
      'deployment_impact': 'Deployment மற்றும் impact',
      'impact_prototype_scope': 'Competition prototype',
      'impact_one_node': 'ஒரு node deployment design',
      'impact_connectivity': 'இணைப்பு',
      'impact_local_first': 'Local-first; cloud தேவையில்லை',
      'impact_scale_path': 'Scale செய்யும் வழி',
      'impact_add_nodes': 'Field மற்றும் zone வாரியாக node சேர்க்கலாம்',
      'impact_decision_model': 'வயல் செயல்',
      'impact_farmer_control': 'விவசாயி உறுதி அவசியம்',
      'evidence_lab': 'ஆதாரம் மற்றும் validation',
      'validation_status': 'PhytoSense AI 9.0 வெளியீட்டு நிலை',
      'validation_transparency':
          'இந்த வெளியீட்டில் காட்டப்படும் அனைத்து software வசதிகளும் முடிக்கப்பட்டுள்ளன. Hardware connection மற்றும் field evidence tools, அளவிடப்பட்ட முடிவுகள் என தவறாக காட்டாமல் தயாராக உள்ளன.',
      'validation_app': 'Farmer app மற்றும் simulation scenarios',
      'validation_api': 'ESP32 API contract மற்றும் provider switching',
      'validation_hardware':
          'ESP32 integration contract மற்றும் node diagnostics',
      'validation_field_trials':
          'மீண்டும் செய்யக்கூடிய field-evidence recording workflow',
      'status_complete': 'முடிந்தது',
      'status_ready': 'தயார்',
      'validation_note':
          'Ultimate UI application release முழுமையாக உள்ளது. Farmer/Judge experience responsive ஆகவும் Demo மற்றும் physical-node workspace தனித்தனியாகவும் இருந்து validation, diagnostics, trials, calibration மற்றும் evidence workflow வழங்கும்.',
      'judge_questions': 'Judges கேட்கக்கூடிய கேள்விகள்',
      'judge_q_ai': 'இதில் AI என்ன?',
      'judge_a_ai':
          'PhytoSense AI transparent multimodal decision support பயன்படுத்துகிறது: camera visible colour pattern-ஐ அளந்து, crop, electrode, sensor மற்றும் புதிய weather evidence potential issue type-களை rank செய்கிறது. காட்டும் percentage rule-based match score; accuracy அல்லது confirmed diagnosis அல்ல. Labelled field data மற்றும் controlled testing பிறகே validated trained model உருவாகும்.',
      'judge_q_novel': 'சாதாரண IoT dashboard-இலிருந்து இது எவ்வாறு வேறு?',
      'judge_a_novel':
          'Raw numbers மட்டும் அல்ல; farm hierarchy, source-independent sensing, plant response, fault validation மற்றும் explainable farmer actions ஒன்றாக இணைகின்றன.',
      'judge_q_scale': 'ஒரு node எப்படி முழு farm-க்கு scale ஆகும்?',
      'judge_a_scale':
          'ஒவ்வொரு node-மும் ஒரே API மற்றும் SensorDataProvider contract பயன்படுத்தும். Charts, alerts, analysis மாற்றாமல் புதிய node-களை zone-களில் சேர்க்கலாம்.',
      'judge_q_false_alert': 'False alert எவ்வாறு குறைக்கப்படுகிறது?',
      'judge_a_false_alert':
          'Range validation, sensor cross-check, alert rate limit மற்றும் செயல்படும் முன் நேரடி crop inspection பயன்படுத்தப்படுகிறது.',
      'presentation_mode': 'Guided presentation',
      'presentation_problem_title': 'விவசாயி பிரச்சினையுடன் தொடங்குங்கள்',
      'presentation_problem_body':
          'Technology-ஐ காட்டும் முன் பிரச்சினையை விளக்குங்கள்.',
      'presentation_problem_1':
          'கண்ணுக்கு தெரியும் அறிகுறிக்கு முன் stress தொடங்கலாம்.',
      'presentation_problem_2':
          'விவசாயிக்கு numbers அல்ல; தெளிவான early guidance தேவை.',
      'presentation_system_title': 'முழு system-ஐ காட்டுங்கள்',
      'presentation_system_body':
          'PhytoSense AI ஒரு disconnected app mock-up அல்ல; end-to-end architecture.',
      'presentation_system_1':
          'ஒரு ESP32 node documented local API வழியாக இணையும்.',
      'presentation_system_2':
          'Farmer workflow மாறாமல் simulation-க்கு மாறலாம்.',
      'presentation_system_3':
          'Fields, zones, alerts, charts மற்றும் analysis provider abstraction பயன்படுத்தும்.',
      'presentation_intelligence_title':
          'Farmer intelligence suite-ஐ காட்டுங்கள்',
      'presentation_intelligence_body':
          'ஆதாரமில்லாத claim இல்லாமல் பல evidence source-களை ஒரே app இணைக்கிறது.',
      'presentation_intelligence_1':
          'Camera screening local leaf pattern-ஐ crop, electrode, sensor மற்றும் weather evidence உடன் இணைத்து முதலில் எதை inspect செய்ய வேண்டும் என்று rank செய்கிறது.',
      'presentation_intelligence_2':
          'Irrigation guidance முன் weather மற்றும் soil moisture cross-check செய்யப்படுகிறது.',
      'presentation_intelligence_3':
          'Tamil/English voice, offline storage மற்றும் growth-stage management practical farm use-ஐ ஆதரிக்கும்.',
      'presentation_demo_title': 'மாறும் நிலையை demo செய்யுங்கள்',
      'presentation_demo_body':
          'Healthy, early stress மற்றும் urgent combination நிலைகளை கீழே தேர்ந்தெடுக்கவும்.',
      'presentation_demo_1':
          'Data source எப்போதும் தெளிவாக label செய்யப்பட்டிருக்கும்.',
      'presentation_demo_2':
          'Insight காரணத்தையும் அடுத்த farmer inspection-ஐயும் காட்டும்.',
      'presentation_ai_title': 'Intelligence-ஐ நேர்மையாக விளக்குங்கள்',
      'presentation_ai_body':
          'ஆதாரமில்லாத accuracy claim-ஐவிட transparent system வலிமையானது.',
      'presentation_ai_1':
          'Current values, recent direction மற்றும் sensor agreement முடிவை மாற்றும்.',
      'presentation_ai_2':
          'Evidence workflow labelled hardware observations-ஐ measured evaluation மற்றும் responsible model improvement-க்கு பதிவு செய்கிறது.',
      'presentation_impact_title': 'Practical impact உடன் முடிக்கவும்',
      'presentation_impact_body':
          'முன்கூட்டிய inspection, தெளிவான முடிவு மற்றும் ஒரு node முதல் பல zone வரை குறைந்த செலவு வளர்ச்சி.',
      'presentation_impact_1': 'Farmer-first English மற்றும் தமிழ் interface.',
      'presentation_impact_2':
          'Local operation மற்றும் low-cost controller architecture.',
      'presentation_impact_3':
          'Farmer confirmation இல்லாமல் automatic irrigation இல்லை.',
      'demo_console': 'Presentation demo console',
      'demo_console_body':
          'கட்டுப்படுத்தப்பட்ட நிலையைத் தேர்வு செய்யவும். Simulation தரவை hardware என்று காட்டாது.',
      'switch_to_demo': 'Simulation demo-க்கு மாறு',
      'scan_leaf': 'இலை scan',
      'irrigation_short': 'நீர்ப்பாசனம்',
      'weather_short': 'வானிலை',
      'leaf_screening_title': 'PhytoSense AI Vision — இலை பரிசோதனை',
      'leaf_screening_menu_body':
          'Camera மூலம் on-device disease-risk screening செய்யுங்கள்.',
      'leaf_screening_hero': 'Camera உதவியுடன் இலை பரிசோதனை',
      'leaf_screening_hero_body':
          'Photo upload செய்யாமல் இலைப் படம், plant-electrode, sensor மற்றும் weather evidence-ஐ இணைக்கிறது.',
      'confirm_crop_title': 'Screening முன் பயிரை உறுதி செய்யவும்',
      'confirm_crop_body':
          'Active field crop ஒரு suggestion ஆக காட்டப்படும். சம்பந்தமில்லாத நோய் பட்டியல் வராமல் photo-வில் உள்ள பயிரை தேர்வு செய்யவும்.',
      'select_crop': 'Photo-வில் உள்ள பயிர்',
      'confirm_crop_checkbox':
          'இந்த photo தேர்ந்தெடுத்த பயிருக்குரியது என்று உறுதி செய்கிறேன்',
      'crop_not_auto_detected':
          'On-device engine leaf-like evidence-ஐ validate செய்கிறது; crop species-ஐ தானாக கண்டறிந்ததாக claim செய்யாது.',
      'crop_confirmation_required':
          'Photo எடுக்கும் அல்லது தேர்வு செய்யும் முன் பயிரை உறுதி செய்யவும்.',
      'take_leaf_photo': 'Photo எடு',
      'choose_leaf_photo': 'Gallery',
      'leaf_image_invalid':
          'இந்த படத்தை analyse செய்ய முடியவில்லை. நல்ல பகல் வெளிச்சத்தில் ஒரு இலையை தெளிவாக மீண்டும் எடுக்கவும்.',
      'leaf_image_too_small':
          'படம் மிகவும் சிறியது. ஒரு இலையை அருகில், அதிக resolution-ல் எடுக்கவும்.',
      'leaf_image_too_dark':
          'நம்பகமான screening-க்கு படம் மிகவும் இருட்டாக உள்ளது. சமமான பகல் வெளிச்சத்தில் மீண்டும் எடுக்கவும்.',
      'leaf_image_too_bright':
          'படத்தில் வெளிச்சம் மிக அதிகம். கடுமையான glare இல்லாத இடத்தில் மீண்டும் எடுக்கவும்.',
      'leaf_image_no_detail':
          'படத்தில் தேவையான detail இல்லை. Camera-வை நிலையாக வைத்து ஒரு இலையில் focus செய்யவும்.',
      'leaf_image_no_leaf':
          'நம்பகமான leaf-like பகுதி கிடைக்கவில்லை. வேறு பொருள் அல்லது landscape அல்லாமல் ஒரு crop leaf-ஐ அருகில் எடுக்கவும்.',
      'leaf_camera_unavailable':
          'இந்த device-ல் camera அல்லது photo picker கிடைக்கவில்லை. Gallery அல்லது Android app-ஐ முயலுங்கள்.',
      'analyzing_leaf':
          'Photo-வை analyse செய்து crop, electrode, sensor மற்றும் weather evidence cross-check செய்யப்படுகிறது…',
      'photo_guide_title': 'நம்பகமான screening photo-க்கு',
      'photo_guide_light': 'நிழல் குறைந்த நல்ல பகல் வெளிச்சம் பயன்படுத்தவும்.',
      'photo_guide_single_leaf':
          'ஒரு இலையை frame முழுவதும் வருமாறு எடுக்கவும்.',
      'photo_guide_focus': 'இலை தெளிவாகவும் பின்னணி எளிமையாகவும் இருக்கட்டும்.',
      'leaf_result_retake': 'மீண்டும் photo எடுக்கவும்',
      'leaf_result_retake_body':
          'நம்பகமான screening-க்கு போதுமான பச்சை இலை பகுதி கண்டறியப்படவில்லை.',
      'leaf_action_retake':
          'ஒரு இலையை இயற்கை வெளிச்சத்தில் அருகில் மீண்டும் எடுக்கவும்.',
      'leaf_result_spot_risk': 'Leaf-spot அல்லது lesion pattern இருக்கலாம்',
      'leaf_result_spot_risk_body':
          'பழுப்பு பகுதி அதிகமாக உள்ளது. இது நோய், சேதம் அல்லது இயற்கை முதிர்வு காரணமாக இருக்கலாம்.',
      'leaf_action_spot':
          'இலையின் இருபக்கமும் பார்த்து, கடுமையாக பாதித்த இலையை தனியே வைத்து, சிகிச்சைக்கு முன் உள்ளூர் crop expert-ஐ கேளுங்கள்.',
      'leaf_result_yellowing': 'மஞ்சள் pattern கவனம் தேவை',
      'leaf_result_yellowing_body':
          'மஞ்சள் பகுதி அதிகமாக உள்ளது. நீர் stress, nutrient குறைவு, நோய் ஆகியவை photo-வில் ஒரேபோல் இருக்கலாம்.',
      'leaf_action_yellowing':
          'அருகிலுள்ள செடிகளை ஒப்பிட்டு soil moisture பார்க்கவும்; மஞ்சள் பரவினால் crop-specific advice பெறவும்.',
      'leaf_result_low_risk': 'காணக்கூடிய நோய் அபாயம் குறைவு',
      'leaf_result_low_risk_body':
          'படத்தில் பச்சை பகுதி அதிகம்; மஞ்சள் மற்றும் பழுப்பு பகுதி குறைவு.',
      'leaf_action_monitor':
          'தொடர்ந்து கண்காணித்து அறிகுறி மாறினால் புதிய photo-வுடன் ஒப்பிடவும்.',
      'leaf_green_area': 'பச்சை',
      'leaf_yellow_area': 'மஞ்சள்',
      'leaf_brown_area': 'பழுப்பு',
      'leaf_safety_note':
          'PhytoSense AI ஆரம்ப inspection-க்கு potential issue type-களை rank செய்கிறது. இது laboratory diagnosis அல்ல; pesticide அல்லது chemical அளவை தேர்வு செய்யாது.',
      'disease_context_title': 'இந்த screening-க்கு evidence தயார்',
      'disease_prompt_context_title': 'Sensor தூண்டிய வயல் பரிசோதனை',
      'disease_context_body':
          'கிடைக்கும் புதிய evidence source அனைத்தையும் பயன்படுத்தி crop-specific possibilities-ஐ PhytoSense AI rank செய்யும்.',
      'disease_prompt_context_body':
          'அசாதாரண field signal இந்த workflow-ஐ தொடங்கியது. சிறந்த cross-check-க்கு பாதித்த ஒரு representative இலையை photo எடுக்கவும்.',
      'disease_context_no_sensor': 'Photo-only mode',
      'disease_context_weather_ready': 'புதிய weather தயார்',
      'disease_context_weather_unavailable': 'Weather சேர்க்கப்படவில்லை',
      'disease_photo_prompt_title':
          'Plant stress கண்டறியப்பட்டது — photo எடுக்கவும்',
      'disease_photo_prompt_body':
          '{crop} reading விரும்பிய வரம்புக்கு வெளியே உள்ளது. Potential disease, pest அல்லது environmental stress type-ஐ பார்க்க ஒரு representative இலையை photo எடுக்கவும்.',
      'disease_take_photo_action': 'Disease-check photo எடு',
      'disease_trigger_electrode':
          'Plant-electrode response விரும்பிய band-க்கு வெளியே உள்ளது.',
      'disease_trigger_health':
          'Combined plant health score attention threshold-க்கு கீழே உள்ளது.',
      'disease_trigger_dry_soil':
          'Soil moisture குறைவாக இருப்பதால் இலை தோற்றம் மாறலாம்.',
      'disease_trigger_wet_soil':
          'Soil moisture மிக அதிகம்; root அல்லது disease stress அதிகரிக்கலாம்.',
      'disease_trigger_heat':
          'Canopy temperature crop preferred range-க்கு மேல் உள்ளது.',
      'disease_trigger_humidity':
          'சில இலை நோய்களுக்கு ஏற்ற அளவில் humidity அதிகமாக உள்ளது.',
      'disease_trigger_weather':
          'சமீபத்திய humidity மற்றும் rain disease-risk காலத்தை உருவாக்குகிறது.',
      'disease_potential_matches': 'Potential issue matches',
      'disease_crop_context': '{crop}-க்கான crop-specific ranking',
      'disease_ranking_explanation':
          'இவை இலை colour proportion, விவசாயி உறுதி செய்த அறிகுறிகள் மற்றும் கிடைக்கும் field evidence அடிப்படையிலான transparent match scores. அதிக score என்றால் “இதை முதலில் பாருங்கள்”; “நோய் உறுதி” என்று பொருள் இல்லை.',
      'disease_inconclusive_title': 'ஆதாரம் தெளிவாக இல்லை',
      'disease_inconclusive_body':
          'முதல் score குறைவாக உள்ளது அல்லது மற்றொரு வாய்ப்பிற்கு மிக அருகில் உள்ளது. பல செடிகளை பார்த்து தெளிவான photo எடுத்து treatment முன் தகுதியான வேளாண் நிபுணரை அணுகவும்.',
      'disease_top_match': 'முதல் potential match',
      'disease_match_score': '{value}% match',
      'disease_inspect_next': 'அடுத்து பார்க்கவும்',
      'disease_evidence_used': 'இந்த முடிவில் பயன்படுத்திய evidence',
      'disease_evidence_camera':
          'Photo-வில் அளவிடப்பட்ட இலை colour proportions',
      'disease_evidence_farmer_observations':
          'விவசாயி உறுதி செய்த visible symptoms',
      'disease_evidence_sensor': 'Soil, temperature, humidity மற்றும் light',
      'disease_evidence_electrode': 'அசாதாரண plant-electrode response',
      'disease_evidence_weather': 'புதிய local forecast',
      'disease_evidence_weather_risk': 'Humidity + rain risk காலம்',
      'disease_evidence_visual_balanced':
          'பெரும்பாலும் balanced visible leaf colour',
      'disease_not_confirmed':
          'இது potential match மட்டும்; உறுதியான diagnosis அல்ல. பல செடிகளை ஒப்பிட்டு, treatment தேர்வு செய்யும் முன் தகுதியான local agricultural expert-ஐ கேளுங்கள்.',
      'disease_not_confirmed_short':
          'இது potential match; உறுதியான diagnosis அல்ல.',
      'disease_category_fungal': 'Fungal pattern',
      'disease_category_bacterial': 'Bacterial pattern',
      'disease_category_viral': 'Virus சார்ந்த pattern',
      'disease_category_phytoplasma': 'Phytoplasma சார்ந்த pattern',
      'disease_category_pest': 'Pest-linked pattern',
      'disease_category_stress': 'Environmental stress',
      'disease_category_clear': 'தெளிவான கவலை இல்லை',
      'disease_no_clear_match': 'தெளிவான disease pattern இல்லை',
      'disease_no_clear_match_reason':
          'Photo எடுத்த இலை பெரும்பாலும் பச்சையாகவும், கிடைக்கும் field signals preferred bands-லும் உள்ளன.',
      'disease_no_clear_match_inspect':
          'தொடர்ந்து கண்காணித்து அறிகுறி தோன்றினால் அல்லது பரவினால் அதே பகுதியை புதிய photo-வுடன் ஒப்பிடவும்.',
      'disease_rice_blast': 'நெல் blast pattern',
      'disease_rice_blast_reason':
          'Brown lesion coverage மற்றும் warm, humid அல்லது rainy condition இணைந்தால் rice blast போல இருக்கலாம்.',
      'disease_rice_blast_inspect':
          'பல இலைகளில் கருமையான ஓரத்துடன் spindle வடிவ spots உள்ளதா, pattern பரவுகிறதா பார்க்கவும்.',
      'disease_rice_brown_spot': 'நெல் brown spot pattern',
      'disease_rice_brown_spot_reason':
          'Brown spots, yellowing அல்லது plant stress இணைந்தால் rice brown spot போல இருக்கலாம்.',
      'disease_rice_brown_spot_inspect':
          'பழைய இலைகளில் சிறிய round அல்லது oval brown spots அதிகமாக உள்ளதா பார்த்து zone முழுவதும் ஒப்பிடவும்.',
      'disease_rice_blight': 'நெல் bacterial leaf blight pattern',
      'disease_rice_blight_reason':
          'Yellow-brown damage மற்றும் wet, humid அல்லது rainy condition இணைந்தால் bacterial leaf blight போல இருக்கலாம்.',
      'disease_rice_blight_inspect':
          'பல செடிகளின் இலை நுனி மற்றும் ஓரத்தில் நீளமாகும் yellow-to-straw colour பகுதிகள் உள்ளதா பார்க்கவும்.',
      'disease_rice_stem_borer': 'நெல் stem-borer அல்லது pest-stress pattern',
      'disease_rice_stem_borer_reason':
          'Yellowing மற்றும் unusual plant-electrode response stem damage உட்பட pest-related stress-ஐ காட்டலாம்.',
      'disease_rice_stem_borer_inspect':
          'மைய shoot, leaf sheath மற்றும் அருகிலுள்ள stem-ல் wilting, entry mark அல்லது insect activity உள்ளதா பார்க்கவும்.',
      'disease_tomato_early_blight': 'தக்காளி early blight pattern',
      'disease_tomato_early_blight_reason':
          'Farmer உறுதி செய்த target-like rings கொண்ட brown lesions early blight-க்கு அதிகம் பொருந்தும்.',
      'disease_tomato_early_blight_inspect':
          'கீழ் பழைய இலைகளில் ring-like pattern மற்றும் yellow margin கொண்ட பெருகும் brown spots உள்ளதா பார்க்கவும்.',
      'disease_tomato_late_blight': 'தக்காளி late blight pattern',
      'disease_tomato_late_blight_reason':
          'Farmer உறுதி செய்த water-soaked dark lesions மற்றும் humid அல்லது wet condition late blight-க்கு அதிகம் பொருந்தும்.',
      'disease_tomato_late_blight_inspect':
          'Wet weather பிறகு பல இலை மற்றும் stem-ல் விரைவாக பெருகும் dark, water-soaked பகுதிகள் உள்ளதா பார்க்கவும்.',
      'disease_tomato_bacterial_spot': 'தக்காளி bacterial spot pattern',
      'disease_tomato_bacterial_spot_reason':
          'Farmer உறுதி செய்த yellow halo கொண்ட பல சிறிய dark spots bacterial spot-க்கு அதிகம் பொருந்தும்.',
      'disease_tomato_bacterial_spot_inspect':
          'இலை மற்றும் fruit-ல் பல சிறிய dark spots உள்ளதா அருகில் பார்த்து அடுத்த செடிகளுடன் ஒப்பிடவும்.',
      'disease_tomato_leaf_curl':
          'தக்காளி leaf-curl அல்லது sap-feeding pest pattern',
      'disease_tomato_leaf_curl_reason':
          'Farmer உறுதி செய்த curling மற்றும் whiteflies, yellowing அல்லது unusual plant response leaf-curl அல்லது sap-feeding pest stress-க்கு அதிகம் பொருந்தும்.',
      'disease_tomato_leaf_curl_inspect':
          'புதிய வளர்ச்சியில் curling உள்ளதா, இலை கீழ்புறத்தில் tiny insects அல்லது clustered activity உள்ளதா பார்க்கவும்.',
      'tomato_symptoms_title': 'Advanced தக்காளி symptom check',
      'tomato_symptoms_body':
          'தக்காளி competition reference crop. Photo, sensors, electrode response மற்றும் weather evidence ஒன்றாக rank செய்ய ஐந்து visible observations-க்கும் பதில் அளிக்கவும்.',
      'tomato_question_rings': 'Brown spots-ல் target போன்ற வட்ட rings உள்ளதா?',
      'tomato_question_water_soaked':
          'Dark lesions ஈரமாக அல்லது water-soaked போல உள்ளதா?',
      'tomato_question_yellow_halos':
          'சிறிய dark spots சுற்றி yellow halo உள்ளதா?',
      'tomato_question_leaf_curl':
          'இளம் இலைகள் curl, twist அல்லது மிகவும் சிறியதாக உள்ளதா?',
      'tomato_question_whiteflies': 'இலை கீழ்புறத்தில் tiny whiteflies உள்ளதா?',
      'observation_yes': 'ஆம்',
      'observation_no': 'இல்லை',
      'observation_uncertain': 'தெரியவில்லை',
      'rank_potential_issues': 'Potential issues-ஐ rank செய்யவும்',
      'disease_maize_leaf_blight': 'மக்காச்சோள leaf-blight pattern',
      'disease_maize_leaf_blight_reason':
          'Warm, humid நிலையில் நீளமாகும் brown பகுதிகள் maize leaf blight போல இருக்கலாம்.',
      'disease_maize_leaf_blight_inspect':
          'பல இலைகளில் blade வழியாக பெருகும் நீண்ட grey-green அல்லது brown lesions உள்ளதா பார்க்கவும்.',
      'disease_maize_downy_mildew': 'மக்காச்சோள downy-mildew pattern',
      'disease_maize_downy_mildew_reason':
          'Yellow stripes மற்றும் தொடர்ந்து அதிக humidity downy-mildew stress போல இருக்கலாம்.',
      'disease_maize_downy_mildew_inspect':
          'இளம் இலைகளில் நீளமான வெளிர் கோடுகள் மற்றும் காலை நேர white growth உள்ளதா பார்க்கவும்.',
      'disease_maize_fall_armyworm': 'மக்காச்சோள fall-armyworm damage pattern',
      'disease_maize_fall_armyworm_reason':
          'ஒழுங்கற்ற brown damage மற்றும் plant stress chewing-pest activity-க்கு பொருந்தலாம்.',
      'disease_maize_fall_armyworm_inspect':
          'Whorl-ஐ திறந்து புதிய holes, scraped tissue மற்றும் அருகிலுள்ள செடிகளில் insect activity பார்க்கவும்.',
      'disease_groundnut_leaf_spot': 'நிலக்கடலை tikka leaf-spot pattern',
      'disease_groundnut_leaf_spot_reason':
          'Yellowing உடன் மீண்டும் வரும் brown spots groundnut leaf spot போல இருக்கலாம்.',
      'disease_groundnut_leaf_spot_inspect':
          'பழைய இலைகளில் பல வட்ட dark spots, yellow margin மற்றும் leaf drop உள்ளதா பார்க்கவும்.',
      'disease_groundnut_rust': 'நிலக்கடலை rust pattern',
      'disease_groundnut_rust_reason':
          'Warm weather மற்றும் brown-orange spotting groundnut rust போல இருக்கலாம்.',
      'disease_groundnut_rust_inspect':
          'பல செடிகளின் இலை கீழ்புறத்தில் சிறிய raised orange-brown pustules உள்ளதா பார்க்கவும்.',
      'disease_groundnut_leaf_miner': 'நிலக்கடலை leaf-miner damage pattern',
      'disease_groundnut_leaf_miner_reason':
          'Yellow-brown patches மற்றும் unusual plant response leaf-miner feeding-க்கு பொருந்தலாம்.',
      'disease_groundnut_leaf_miner_inspect':
          'மடிந்த leaflets, pale mines மற்றும் சேதமான இலைக்குள் larvae அல்லது webbing உள்ளதா பார்க்கவும்.',
      'disease_cotton_bacterial_blight': 'பருத்தி bacterial-blight pattern',
      'disease_cotton_bacterial_blight_reason':
          'Humid அல்லது rainy weather பிறகு angular brown பகுதிகள் bacterial blight போல இருக்கலாம்.',
      'disease_cotton_bacterial_blight_inspect':
          'பல பருத்தி இலைகளில் spots vein வழியாக angular shape-ல் உள்ளதா பார்க்கவும்.',
      'disease_cotton_alternaria': 'பருத்தி Alternaria leaf-spot pattern',
      'disease_cotton_alternaria_reason':
          'Warm நிலையில் yellowing உடன் வட்ட brown lesions Alternaria leaf spot போல இருக்கலாம்.',
      'disease_cotton_alternaria_inspect':
          'பழைய இலைகளில் rings அல்லது brittle centre கொண்ட பெருகும் round spots உள்ளதா பார்க்கவும்.',
      'disease_cotton_sucking_pest': 'பருத்தி sucking-pest stress pattern',
      'disease_cotton_sucking_pest_reason':
          'Yellowing, curling மற்றும் plant-response மாற்றம் sap-feeding pest stress-க்கு பொருந்தலாம்.',
      'disease_cotton_sucking_pest_inspect':
          'Tender leaf கீழ்புறத்தில் insects, sticky residue, curling அல்லது edge yellowing உள்ளதா பார்க்கவும்.',
      'disease_sugarcane_red_rot': 'கரும்பு red-rot stress pattern',
      'disease_sugarcane_red_rot_reason':
          'தொடர்ந்து yellowing மற்றும் குறைந்த plant response red rot உட்பட தீவிர cane stress-க்கு பொருந்தலாம்.',
      'disease_sugarcane_red_rot_inspect':
          'Top leaves உலர்கிறதா பார்க்கவும்; உறுதிப்படுத்த crop officer ஆலோசனை பெறவும்.',
      'disease_sugarcane_smut': 'கரும்பு smut stress pattern',
      'disease_sugarcane_smut_reason':
          'Narrow yellowing leaves மற்றும் குறைந்த vigour smut பாதித்த stools-ல் இருக்கலாம்.',
      'disease_sugarcane_smut_inspect':
          'Growing point-ல் abnormal dark whip-like structure உள்ளதா, அருகிலுள்ள stools-ஐ ஒப்பிட்டு பார்க்கவும்.',
      'disease_sugarcane_shoot_borer': 'கரும்பு early shoot-borer pattern',
      'disease_sugarcane_shoot_borer_reason':
          'Central-leaf yellowing மற்றும் weak plant response shoot-borer damage-க்கு பொருந்தலாம்.',
      'disease_sugarcane_shoot_borer_inspect':
          'இளம் shoot-ல் drying central leaf மற்றும் lower stem அருகில் entry holes உள்ளதா பார்க்கவும்.',
      'disease_banana_sigatoka': 'வாழை Sigatoka leaf-spot pattern',
      'disease_banana_sigatoka_reason':
          'Humid நிலையில் அதிகரிக்கும் brown streaks மற்றும் yellow பகுதிகள் Sigatoka போல இருக்கலாம்.',
      'disease_banana_sigatoka_inspect':
          'பழைய இலைகளில் dark spot மற்றும் yellow margin ஆக பெருகும் narrow streaks உள்ளதா பார்க்கவும்.',
      'disease_banana_bunchy_top': 'வாழை bunchy-top pattern',
      'disease_banana_bunchy_top_reason':
          'Yellowing மற்றும் abnormal new-leaf development virus-linked bunchy-top stress போல இருக்கலாம்.',
      'disease_banana_bunchy_top_inspect':
          'புதிய இலைகளில் upright bunching, narrow growth மற்றும் vein வழியாக dark green streaks பார்க்கவும்.',
      'disease_banana_weevil': 'வாழை weevil-related stress pattern',
      'disease_banana_weevil_reason':
          'Yellowing மற்றும் reduced plant response internal weevil damage உடன் தொடர்புடையதாக இருக்கலாம்.',
      'disease_banana_weevil_inspect':
          'Lower pseudostem மற்றும் corm பகுதியில் holes, tunnelling material அல்லது weak plants உள்ளதா பார்க்கவும்.',
      'disease_coconut_leaf_rot': 'தென்னை leaf-rot pattern',
      'disease_coconut_leaf_rot_reason':
          'Humid weather-ல் brown damaged பகுதிகள் coconut leaf rot போல இருக்கலாம்.',
      'disease_coconut_leaf_rot_inspect':
          'புதிதாக விரிந்த இலைகளில் blackened, rotting அல்லது எளிதில் பிரியும் tissue உள்ளதா பார்க்கவும்.',
      'disease_coconut_bud_rot': 'தென்னை bud-rot risk pattern',
      'disease_coconut_bud_rot_reason':
          'Wet weather உடன் yellow-brown crown damage serious bud-rot risk ஆக இருக்கலாம்.',
      'disease_coconut_bud_rot_inspect':
          'தரையிலிருந்து பாதுகாப்பாக central spear drooping அல்லது discoloured ஆக உள்ளதா பார்க்கவும்; crown inspection-க்கு trained worker உதவி பெறவும்.',
      'disease_coconut_caterpillar': 'தென்னை leaf-eating caterpillar damage',
      'disease_coconut_caterpillar_reason':
          'Browning மற்றும் குறைந்த green leaf area leaf-eating pest damage-க்கு பொருந்தலாம்.',
      'disease_coconut_caterpillar_inspect':
          'விழுந்த அல்லது எட்டக்கூடிய leaflets-ல் scraped tissue, webbing, droppings அல்லது larvae பார்க்கவும்.',
      'disease_brinjal_leaf_spot': 'கத்திரிக்காய் leaf-spot pattern',
      'disease_brinjal_leaf_spot_reason':
          'Humid நிலையில் வட்ட brown lesions fungal leaf spot போல இருக்கலாம்.',
      'disease_brinjal_leaf_spot_inspect':
          'பழைய இலைகளில் pale centre அல்லது yellow margin கொண்ட பெருகும் round spots உள்ளதா பார்க்கவும்.',
      'disease_brinjal_little_leaf': 'கத்திரிக்காய் little-leaf pattern',
      'disease_brinjal_little_leaf_reason':
          'Yellowing மற்றும் abnormal small new leaves phytoplasma-linked little-leaf stress போல இருக்கலாம்.',
      'disease_brinjal_little_leaf_inspect':
          'மிகச் சிறிய இலை clusters, shortened internodes மற்றும் reduced flowering உள்ளதா பார்க்கவும்.',
      'disease_brinjal_shoot_borer':
          'கத்திரிக்காய் shoot-and-fruit-borer stress',
      'disease_brinjal_shoot_borer_reason':
          'Wilting shoots மற்றும் plant-response மாற்றம் borer activity-க்கு பொருந்தலாம்.',
      'disease_brinjal_shoot_borer_inspect':
          'Tender shoots மற்றும் fruit-ல் entry holes, droppings மற்றும் sudden shoot wilting பார்க்கவும்.',
      'disease_chilli_leaf_curl': 'மிளகாய் leaf-curl pattern',
      'disease_chilli_leaf_curl_reason':
          'Yellowing, curling மற்றும் heat-linked stress virus அல்லது vector-related leaf curl போல இருக்கலாம்.',
      'disease_chilli_leaf_curl_inspect':
          'புதிய growth-ல் upward curling, shortened internodes மற்றும் கீழ்புற tiny insects பார்க்கவும்.',
      'disease_chilli_anthracnose': 'மிளகாய் anthracnose pattern',
      'disease_chilli_anthracnose_reason':
          'Warm, humid நிலையில் brown lesions anthracnose போல இருக்கலாம்.',
      'disease_chilli_anthracnose_inspect':
          'Wet weather பிறகு leaf மற்றும் fruit-ல் பெருகும் sunken dark spots உள்ளதா பார்க்கவும்.',
      'disease_chilli_thrips': 'மிளகாய் thrips damage pattern',
      'disease_chilli_thrips_reason':
          'Yellowing, curling மற்றும் dry-weather stress thrips feeding-க்கு பொருந்தலாம்.',
      'disease_chilli_thrips_inspect':
          'Young leaves மற்றும் flowers-ல் silvery scraping, distortion மற்றும் tiny moving insects பார்க்கவும்.',
      'disease_generic_leaf_spot': 'Fungal leaf-spot pattern இருக்கலாம்',
      'disease_generic_leaf_spot_reason':
          'Humid weather உடன் brown lesion coverage பொதுவான fungal leaf-spot pattern-க்கு பொருந்தலாம்.',
      'disease_generic_leaf_spot_inspect':
          'பல இலைகளின் மேல் மற்றும் கீழ் surface-ல் spot shape மற்றும் spread-ஐ ஒப்பிடவும்.',
      'disease_generic_pest_damage': 'Pest-related damage இருக்கலாம்',
      'disease_generic_pest_damage_reason':
          'Visible yellowing அல்லது damage மற்றும் unusual plant response pest-related stress-ஐ காட்டலாம்.',
      'disease_generic_pest_damage_inspect':
          'இலையின் இருபுறம், stem மற்றும் அருகிலுள்ள செடிகளில் insects, eggs, holes அல்லது curling உள்ளதா பார்க்கவும்.',
      'disease_generic_water_stress': 'Water அல்லது nutrient-stress pattern',
      'disease_generic_water_stress_reason':
          'Yellowing மற்றும் மிக dry, wet அல்லது hot condition இருந்தால் infectious disease அல்லாமல் environmental stress ஆக இருக்கலாம்.',
      'disease_generic_water_stress_inspect':
          'Root-zone moisture பார்த்து பல செடிகளை ஒப்பிட்டு, அறிகுறி irrigation pattern-ஐ பின்பற்றுகிறதா பார்க்கவும்.',
      'listen_guidance': 'வழிகாட்டலை கேள்',
      'voice_unavailable':
          'இந்த device-ல் voice guidance கிடைக்கவில்லை. முழு வழிகாட்டல் screen-ல் உள்ளது.',
      'voice_quality': 'இயல்பான குரல் வழிகாட்டல்',
      'voice_quality_body':
          'இந்த device-ல் உள்ள சிறந்த தரமான தமிழ் அல்லது English India குரலை தானாக தேர்வு செய்கிறது.',
      'voice_preview': 'இயல்பான குரலை கேளுங்கள்',
      'voice_preview_playing': 'குரல் ஒலிக்கிறது…',
      'voice_preview_sample':
          'பைட்டோ சென்ஸுக்கு வரவேற்கிறோம். உங்கள் பயிரின் நிலை சமநிலையில் உள்ளது. கவனிக்க வேண்டியதை நான் தெளிவாக விளக்குகிறேன்.',
      'voice_selected': 'தேர்ந்தெடுத்த device குரல்: {value}',
      'weather_center': 'Farm வானிலை மையம்',
      'weather_menu_body':
          '5 நாள் forecast மற்றும் heavy rain, dry spell, disease-risk alerts.',
      'refresh_weather': 'வானிலையை புதுப்பி',
      'change_weather_location': 'Farm location மாற்று',
      'weather_location_title': 'Forecast location',
      'weather_location_body':
          'Farm பெயர் மற்றும் coordinates கொடுக்கவும். தொடர்ச்சியான phone location access தேவையில்லை.',
      'use_phone_location': 'Phone GPS location பயன்படுத்து',
      'detecting_location': 'தற்போதைய location கண்டறியப்படுகிறது…',
      'phone_location_privacy':
          'இந்த button-ஐ அழுத்தும் போது மட்டும் location கேட்கப்படும். Forecast location ஆக coordinates save செய்யப்படும்; phone தொடர்ந்து track செய்யப்படாது.',
      'or_enter_manually': 'அல்லது farm location-ஐ manually கொடுக்கவும்',
      'location_service_disabled':
          'Location Services-ஐ on செய்து மீண்டும் முயலுங்கள்.',
      'location_permission_denied':
          'Location permission அனுமதிக்கப்படவில்லை. Farm coordinates-ஐ manually கொடுக்கலாம்.',
      'location_permission_denied_forever':
          'PhytoSense AI location permission block செய்யப்பட்டுள்ளது. Device settings-ல் enable செய்யவும் அல்லது coordinates manually கொடுக்கவும்.',
      'location_unavailable':
          'Phone location கண்டறிய முடியவில்லை. திறந்த இடத்தில் முயலுங்கள் அல்லது farm coordinates manually கொடுக்கவும்.',
      'weather_location_name': 'Farm அல்லது கிராம பெயர்',
      'latitude': 'Latitude',
      'longitude': 'Longitude',
      'weather_location_invalid':
          'பெயர், valid latitude (-90 முதல் 90), longitude (-180 முதல் 180) கொடுக்கவும்.',
      'save_weather_location': 'Save செய்து forecast புதுப்பி',
      'loading_weather': 'புதிய farm forecast பெறப்படுகிறது…',
      'weather_unavailable':
          'Live weather கிடைக்கவில்லை. Internet இணைத்து மீண்டும் முயலுங்கள்.',
      'weather_cached':
          'Network இல்லாததால் கடைசியாக save செய்த forecast காட்டப்படுகிறது.',
      'weather_stale':
          'Save செய்த forecast 12 மணி நேரத்திற்கு மேல் பழையது; reference-க்கு மட்டும் காட்டப்படும், alerts மற்றும் irrigation advice-ல் பயன்படுத்தாது.',
      'five_day_forecast': '5 நாள் forecast',
      'weather_alert_note':
          'மழை, ஈரப்பதம், வெப்பநிலை இணைத்து PhytoSense AI early farm alert தருகிறது. வயல் நிலையை நேரில் உறுதி செய்யவும்.',
      'weather_attribution': 'Forecast data: Open-Meteo',
      'weather_risk_heavy_rain': 'கனமழை அபாயம்',
      'weather_risk_heavy_rain_body':
          'அதிக மழை வாய்ப்பு உள்ளது. Drainage பார்த்து இளம் நாற்றுகளை பாதுகாக்கவும்.',
      'weather_risk_disease': 'வானிலை சார்ந்த நோய் அபாயம்',
      'weather_risk_disease_body':
          'அதிக ஈரப்பதம் மற்றும் மழை fungal disease-க்கு சாதகமாகலாம். இலைகளை முன்கூட்டியே பாருங்கள்.',
      'weather_risk_dry': 'வறண்ட நாட்கள் கண்காணிப்பு',
      'weather_risk_dry_body':
          'பல நாட்கள் மழை குறைவாக இருக்கும். Soil moisture பார்த்து irrigation plan செய்யவும்.',
      'weather_risk_clear': 'பெரிய வானிலை அபாயம் இல்லை',
      'weather_risk_clear_body':
          'தற்போதைய 5 நாள் forecast PhytoSense AI alert வரம்பை கடக்கவில்லை.',
      'wind': 'காற்று',
      'degrees_celsius': 'டிகிரி செல்சியஸ்',
      'rain_probability': 'மழை வாய்ப்பு',
      'weekday_1': 'திங்கள்',
      'weekday_2': 'செவ்வாய்',
      'weekday_3': 'புதன்',
      'weekday_4': 'வியாழன்',
      'weekday_5': 'வெள்ளி',
      'weekday_6': 'சனி',
      'weekday_7': 'ஞாயிறு',
      'irrigation_advisor': 'Smart irrigation advisor',
      'irrigation_menu_body':
          'Soil reading மற்றும் rain forecast இணைத்து பாதுகாப்பான action தருகிறது.',
      'smart_irrigation': 'வானிலை சார்ந்த நீர்ப்பாசனம்',
      'smart_irrigation_body':
          'ஆலோசனைக்கு முன் sensor evidence மற்றும் forecast ஒன்றாக பார்க்கப்படும்.',
      'irrigation_waiting': 'Sensor reading காத்திருக்கிறது',
      'irrigation_waiting_body':
          'Irrigation advice-க்கு validated soil moisture reading தேவை.',
      'irrigation_waiting_action':
          'Sensor connection பார்க்கவும் அல்லது தெளிவாக label செய்த simulation பயன்படுத்தவும்.',
      'irrigation_no_sensor_evidence':
          'Validated soil reading இன்னும் கிடைக்கவில்லை.',
      'irrigation_delay': 'நீர்ப்பாசனத்தை தள்ளி வைத்து மீண்டும் பார்க்கவும்',
      'irrigation_delay_body':
          'விரைவில் மழை வாய்ப்பு உள்ளது; soil moisture critical ஆக இல்லை.',
      'irrigation_delay_action':
          'Watering-ஐ தள்ளி வைத்து drainage பார்த்து forecast பிறகு மீண்டும் அளவிடவும்.',
      'irrigation_rain_evidence':
          'Rain forecast மற்றும் soil moisture cross-check செய்யப்பட்டது.',
      'irrigation_urgent': 'அவசர moisture check',
      'irrigation_urgent_body':
          'Soil moisture மிகவும் குறைவு; பயிர் water stress-ல் இருக்கலாம்.',
      'irrigation_urgent_action':
          'Root zone-ஐ இப்போது பார்த்து reading உறுதியானால் crop practice படி நீர்ப்பாசனம் செய்யவும்.',
      'irrigation_dry_evidence':
          'Validated soil moisture urgent வரம்புக்கு கீழே உள்ளது.',
      'irrigation_recommended': 'நீர்ப்பாசனம் தேவைப்படலாம்',
      'irrigation_recommended_body':
          'Soil moisture preferred range-க்கு கீழே உள்ளது; மழை signal இல்லை.',
      'irrigation_recommended_action':
          'Root zone பார்த்து dryness உறுதியானால் குளிர்ந்த நேரத்தில் irrigation plan செய்யவும்.',
      'irrigation_low_evidence':
          'Soil moisture preferred operating range-க்கு கீழே உள்ளது.',
      'irrigation_stop': 'நீர்ப்பாசனத்தை நிறுத்தவும்',
      'irrigation_stop_body':
          'Soil moisture மிக அதிகம்; கூடுதல் நீர் root stress அதிகரிக்கலாம்.',
      'irrigation_stop_action':
          'Watering நிறுத்தி drainage பார்த்து அடுத்த cycle முன் மீண்டும் அளவிடவும்.',
      'irrigation_wet_evidence':
          'Soil moisture high threshold-க்கு மேலே உள்ளது.',
      'irrigation_paddy_water':
          'திட்டமிட்ட நெல் வயல் நீர் நிலையை பராமரிக்கவும்',
      'irrigation_paddy_water_body':
          'நீர் நிறைந்த நெல் வயலில் அதிக மண் ஈரம் இயல்பானது; அது மட்டும் அதிக பாசனத்தை நிரூபிக்காது.',
      'irrigation_paddy_water_action':
          'நீர் சேர்க்க அல்லது வெளியேற்ற முன் வயலின் நீர் ஆழத்தையும் வடிகாலையும் நேரில் பாருங்கள்.',
      'irrigation_paddy_water_evidence':
          'நெல் வயல் சூழல் தவறான பொதுவான அதிக பாசன எச்சரிக்கையை தவிர்த்தது; சென்சார் மண் ஈரத்தையே அளவிடும், நீர் ஆழத்தை அல்ல.',
      'irrigation_balanced': 'இப்போது நீர்ப்பாசனம் தேவையில்லை',
      'irrigation_balanced_body':
          'தற்போதைய soil moisture preferred range-ல் உள்ளது.',
      'irrigation_balanced_action':
          'தொடர்ந்து கண்காணித்து அடுத்த weather update பார்க்கவும்.',
      'irrigation_balanced_evidence':
          'Sensor மற்றும் forecast அவசர water action காட்டவில்லை.',
      'irrigation_confirmation_note':
          'PhytoSense AI decision support மட்டும் தருகிறது. Irrigation முன் விவசாயி வயல் நிலையை உறுதி செய்ய வேண்டும்; app pump-ஐ தானாக தொடங்காது.',
      'offline_sync_title': 'Offline data மற்றும் sync',
      'offline_sync_menu_body':
          'Reading-களை phone-ல் வைத்து server அமைந்த பிறகு upload செய்யுங்கள்.',
      'offline_first': 'Network இல்லாத இடத்திற்காக உருவாக்கப்பட்டது',
      'offline_first_body':
          'Validated ESP32 readings முதலில் local queue-ல் save ஆகும்; internet இல்லாததால் field evidence அழியாது. Demo readings upload ஆகாது.',
      'pending_records': 'Pending records',
      'local_history_records': 'Chart history',
      'last_sync': 'கடைசி sync',
      'never': 'இன்னும் இல்லை',
      'sync_server': 'Synchronization server',
      'sync_server_body':
          'Optional: farm backend base URL கொடுக்கவும். PhytoSense AI /api/sync-க்கு batch அனுப்பும்.',
      'sync_endpoint': 'Server base URL',
      'sync_endpoint_saved': 'Sync endpoint save செய்யப்பட்டது.',
      'save_endpoint': 'Endpoint save செய்',
      'sync_now': 'இப்போது sync செய்',
      'syncing_now': 'Sync செய்யப்படுகிறது…',
      'sync_success': 'அனைத்து records-மும் sync ஆனது.',
      'sync_failed':
          'Sync தோல்வி. Records இந்த device-ல் பாதுகாப்பாக இருக்கும்; பின்னர் முயலலாம்.',
      'sync_endpoint_required':
          'முதலில் sync server சேர்க்கவும். அதுவரை records local queue-ல் பாதுகாப்பாக இருக்கும்.',
      'sync_privacy_note':
          'Queue numeric sensor readings மற்றும் source label மட்டும் save செய்யும்; leaf photo இல்லை. Server success பிறகே pending queue clear ஆகும்.',
      'crop_management': 'PhytoSense Farm — பயிர் management',
      'crop_management_menu_body':
          'Field crop மற்றும் zone growth stage-ஐ புதுப்பிக்கவும்.',
      'crop_management_body':
          'Field மற்றும் zone தகவலை சரியாக வைத்திருங்கள். மாற்றங்கள் local-ஆக save ஆகி offline-லும் இருக்கும்.',
      'field_crop': 'Field crop',
      'growth_stages': 'Zone growth stages',
      'stage_seedling': 'நாற்று',
      'stage_vegetative': 'வளர்ச்சி',
      'stage_maturity': 'முதிர்ச்சி',
      'alert_heavy_rain': 'கனமழை தயாரிப்பு',
      'alert_heavy_rain_message':
          'கனமழை forecast உள்ளது. Drainage பார்த்து பாதிக்கக்கூடிய crop பகுதியை பாதுகாக்கவும்.',
      'alert_disease_risk': 'வானிலை சார்ந்த disease watch',
      'alert_disease_risk_message':
          'ஈரப்பதம் மற்றும் மழை நோய்க்கு சாதகமாகலாம். சில representative இலைகளை முன்கூட்டியே பாருங்கள்.',
      'alert_dry_spell': 'வறண்ட நாட்கள் forecast',
      'alert_dry_spell_message':
          'பல நாட்கள் மழை குறைவாக இருக்கும். Soil moisture-ஐ நெருக்கமாக கண்காணிக்கவும்.',
      'alert_low_battery': 'Sensor-node battery குறைவு',
      'alert_low_battery_message':
          'Reading நிற்கும் முன் node power source-ஐ charge அல்லது replace செய்யவும்.',
      'alert_weak_signal': 'Sensor-node signal பலவீனம்',
      'alert_weak_signal_message':
          'Node அல்லது gateway இடத்தை மாற்றி link தடைகளை பார்க்கவும்.',
      'alert_abnormal_sensor': 'அசாதாரண sensor values',
      'alert_abnormal_sensor_message':
          'ஒரு reading validation-ல் தோல்வி. அதன்படி செயல்படும் முன் sensor மற்றும் wiring பார்க்கவும்.',
      'about_capabilities_title': 'PhytoSense AI திறன்கள்',
      'about_capabilities_body':
          'Sensing, crop-specific multimodal screening, weather மற்றும் farmer guidance ஒரே workflow-ல் இணைகிறது.',
      'about_capabilities_1':
          'Physical ESP32 node மற்றும் தெளிவாக label செய்த demo data இடையே runtime switching.',
      'about_capabilities_2':
          'Camera, electrode, sensor மற்றும் weather இணைந்த crop-specific potential issue ranking.',
      'about_capabilities_3':
          'Weather-aware irrigation advice மற்றும் drought, heat, heavy-rain, disease-risk alerts.',
      'about_capabilities_4':
          'Offline queue, optional server sync, editable crops/growth stages மற்றும் historical charts.',
      'validation_camera': 'On-device multimodal disease-candidate screening',
      'validation_weather_voice':
          'Live weather மற்றும் bilingual voice guidance',
      'validation_offline_sync':
          'Offline queue மற்றும் configurable server sync',
      'validation_trained_model':
          'Crop-confirmed multi-crop screening மற்றும் invalid image rejection',
      'weather_source': 'வானிலை',
      'nav_device': 'நேரடி node',
      'data_source_separation_note':
          'Demo மற்றும் ESP32 readings தனித்தனி workspace மற்றும் history பயன்படுத்தும். மாற்றும்போது values கலக்காது.',
      'live_workspace_enabled':
          'ESP32 Live workspace இயங்குகிறது. Farm demo data மறைக்கப்பட்டது.',
      'demo_workspace_enabled':
          'Simulation workspace இயங்குகிறது. ESP32 நேரடி values தனியாக பாதுகாக்கப்படும்.',
      'live_node_dashboard': 'VayPulse Node • ESP32 நேரடி',
      'live_session_badge': 'நேரடி SESSION',
      'live_session_body':
          'ஒரு sensor node-க்கான தெளிவான workspace. சரிபார்க்கப்பட்ட ESP32 readings மட்டும் இங்கே காட்டப்படும்.',
      'live_node_name': 'VayPulse Node 01',
      'live_reference_crop': 'DEMO REFERENCE பயிர்',
      'tomato_reference_title': 'தக்காளி ஆரோக்கிய கண்காணிப்பு',
      'live_health_body':
          'இந்த physical node-ன் மண், வானிலை மற்றும் electrode evidence கொண்டு health கணக்கிடப்படுகிறது. Simulation values பயன்படுத்தப்படாது.',
      'validated_reading': 'சரிபார்க்கப்பட்ட sensor reading',
      'data_fresh': 'புதிய data',
      'data_delayed': 'தாமதமான data',
      'data_stale': 'பழைய data',
      'waiting_validation': 'சரிபார்ப்புக்காக காத்திருக்கிறது',
      'range_validated': 'Range சரிபார்க்கப்பட்டது',
      'endpoint': 'Endpoint',
      'reconnect': 'மீண்டும் இணை',
      'live_waiting_title': 'ESP32 node-க்காக காத்திருக்கிறது',
      'live_waiting_body':
          'Phone மற்றும் ESP32-ஐ தேவையான network-ல் இணைத்து, Settings-ல் endpoint உறுதி செய்து மீண்டும் இணைக்கவும்.',
      'electrode_input': 'Electrode input',
      'tomato_demo_ready': 'தக்காளி demo தயார்',
      'tomato_demo_ready_body':
          'இந்த build-ல் தக்காளிக்கு விரிவான symptom questionnaire உள்ளது. Crop உறுதி செய்து, தெளிவான ஒரு இலையை படம் எடுத்து, field checks-க்கு பதில் அளிக்கவும்.',
      'profile_live_workspace': 'ஒரு ESP32 node workspace',
      'more_title_live': 'VayPulse Node & செயலி',
      'engineering_center': 'Engineering Evidence Center',
      'engineering_center_menu_body':
          'Live pipeline, trials, calibration, farmer outcomes மற்றும் judge report.',
      'engineering_center_body':
          'விவசாயி dashboard எளிமையாக இருக்கும்; judges ஒவ்வொரு reading evidence மற்றும் action ஆக மாறுவதை தனியாக பார்க்கலாம்.',
      'engineering_evidence': 'ஆய்வுக்காக உருவாக்கப்பட்டது',
      'engineering_evidence_subtitle':
          'தெளிவான architecture • அளவிடக்கூடிய trials • responsible AI',
      'system_xray': 'Live System X-Ray',
      'system_xray_body':
          'ESP32 அல்லது demo data validation, fusion, reasoning, alerts மற்றும் evidence வழியாக செல்வதைப் பாருங்கள்.',
      'experiment_lab': 'Experiment Evidence Lab',
      'experiment_lab_body':
          'Baseline, response மற்றும் recovery trials-ஐ sensor evidence உடன் பதிவு செய்யுங்கள்.',
      'calibration_wizard': 'Sensor Calibration Wizard',
      'calibration_wizard_body':
          'Stable baseline capture செய்து noisy readings கண்டறிந்து Sensor Trust Score save செய்யுங்கள்.',
      'judge_report': 'One-tap Judge Report',
      'judge_report_body':
          'System, evidence, calibration மற்றும் limitations உடன் தற்போதைய engineering report உருவாக்கும்.',
      'feedback_evidence': 'Farmer Confirmation Evidence',
      'feedback_evidence_body':
          'Confirmed conditions, useful recommendations, recovery மற்றும் false alerts அளவிடும்.',
      'responsible_ai_card': 'Responsible-AI Model Card',
      'responsible_ai_card_body':
          'Intended use, inputs, reasoning, limitations, privacy மற்றும் validation விவரங்கள்.',
      'xray_live_pipeline': 'நேரடி decision pipeline',
      'xray_live_pipeline_body':
          'ஒவ்வொரு stage-மும் active provider-ஐ காட்டும். தேவையான evidence இருந்தால் மட்டுமே complete ஆகும்.',
      'xray_source': 'Data acquisition',
      'xray_validation': 'Range மற்றும் freshness validation',
      'xray_validation_complete':
          'Numeric ranges மற்றும் timestamp சரிபார்க்கப்பட்டது',
      'xray_fusion': 'Multimodal sensor fusion',
      'xray_fusion_detail':
          'Soil, climate, light மற்றும் plant-electrode evidence ஒன்றாக மதிப்பிடப்படும்.',
      'xray_reasoning': 'Explainable reasoning',
      'xray_action': 'Farmer alert மற்றும் action',
      'xray_no_alert': 'இப்போது alert தேவைப்படும் condition இல்லை',
      'xray_alert_ready': 'Alert மற்றும் evidence trail கிடைக்கிறது',
      'xray_evidence': 'Offline evidence record',
      'xray_evidence_detail':
          '{trials} completed trials • {records} saved readings',
      'experiment_evidence_title': 'Claim அல்ல, measurement',
      'experiment_evidence_body':
          'தெளிவாக பெயரிட்ட condition-ல் repeated observation பதிவு செய்யுங்கள். Demo trials DEMO என்றும் live trials LIVE என்றும் இருக்கும்.',
      'trial_name': 'Trial பெயர்',
      'trial_name_hint': 'உதாரணம்: Healthy tomato baseline',
      'trial_started': 'Trial recording தொடங்கியது.',
      'start_trial': 'Trial recording தொடங்கு',
      'recorded_trials': 'பதிவு செய்த trials',
      'no_trials':
          'Completed trial இல்லை. Presentation முன் baseline மற்றும் repeated response trials பதிவு செய்யுங்கள்.',
      'trial_recording': 'Sensor evidence பதிவு செய்யப்படுகிறது',
      'samples': 'Samples',
      'minimum_health': 'குறைந்த health',
      'maximum_stress': 'அதிக stress',
      'cancel_trial': 'Trial cancel செய்',
      'finish_trial': 'Trial முடி',
      'trial_outcome': 'Observed outcome',
      'outcome_detected': 'Condition கண்டறியப்பட்டது',
      'outcome_recovered': 'Recovery காணப்பட்டது',
      'outcome_no_change': 'முக்கிய மாற்றம் இல்லை',
      'outcome_inconclusive': 'தெளிவில்லை',
      'notes': 'குறிப்புகள்',
      'save_trial': 'Trial evidence save செய்',
      'trial_minutes': '{value} நிமிடம்',
      'trial_samples': '{value} samples',
      'calibration_trust_title': 'Sensor நம்பகத்தன்மையை அறியுங்கள்',
      'calibration_trust_body':
          'குறைந்தது 3 stable readings capture செய்யுங்கள். Consistency கணக்கிடப்படும்; இது laboratory certification அல்ல.',
      'trust_score': 'Trust',
      'saved_calibration': 'Save செய்த calibration profile',
      'calibration_samples_count': '{value} baseline samples',
      'calibration_step_connect': 'Node connect மற்றும் validate செய்',
      'calibration_step_connect_body': 'தற்போதைய range-checked reading தேவை.',
      'calibration_step_stabilize': 'Stable baseline samples capture செய்',
      'calibration_step_stabilize_body':
          'Node மற்றும் plant condition steady-ஆக வைத்து பல readings capture செய்யுங்கள்.',
      'calibration_step_save': 'Trust evidence கணக்கிட்டு save செய்',
      'calibration_step_save_body':
          'Soil, climate, light மற்றும் electrode variation மூலம் consistency score உருவாகும்.',
      'calibration_progress':
          'பரிந்துரைக்கப்பட்ட 5-ல் {value} samples capture செய்யப்பட்டது',
      'capture_sample': 'Sample capture செய்',
      'save_calibration': 'Calibration save செய்',
      'reset_samples': 'Samples reset செய்',
      'calibration_saved':
          '{value}% consistency உடன் calibration save செய்யப்பட்டது.',
      'calibration_note_title': 'Calibration integrity',
      'calibration_note_body':
          'இந்த score short-term stability மட்டும் அளவிடும். Physical accuracy claim முன் reference instrument உடன் compare செய்யவும்.',
      'report_snapshot_title': 'Presentation-ready evidence snapshot',
      'report_snapshot_body':
          'Current app state, saved trials, farmer outcomes மற்றும் calibration evidence-ல் இருந்து report உருவாகும்; hard-coded claim அல்ல.',
      'copy_report': 'முழு report copy செய்',
      'report_copied': 'Judge report clipboard-க்கு copy செய்யப்பட்டது.',
      'feedback_loop_title': 'Decision loop-ஐ complete செய்யுங்கள்',
      'feedback_loop_body':
          'Alert பிறகு விவசாயி பார்த்த outcome பதிவு செய்யலாம். இது useful guidance மற்றும் false alert-ஐ காட்டும்; model accuracy claim அல்ல.',
      'feedback_total': 'பதிவு செய்த outcomes',
      'feedback_confirmed': 'Confirmed conditions',
      'feedback_useful': 'Useful recommendations',
      'feedback_false_alerts': 'False alerts',
      'record_feedback_how': 'Evidence பதிவு செய்வது எப்படி',
      'record_feedback_how_body':
          'Plant inspect செய்த பிறகு Alerts திறந்து alert கீழே Record outcome தேர்வு செய்யுங்கள்.',
      'feedback_recorded': 'Outcome பதிவு செய்யப்பட்டது',
      'record_outcome': 'Outcome பதிவு செய்',
      'farmer_outcome_title': 'விவசாயி observation',
      'farmer_outcome_body':
          'நேரில் பார்த்ததை மட்டும் பதிவு செய்யுங்கள். External sync அமைக்காத வரை feedback device-ல் இருக்கும்.',
      'condition_confirmed': 'Condition இருந்தது',
      'recommendation_useful': 'Recommendation பயனுள்ளதாக இருந்தது',
      'plant_recovered': 'பின்னர் recovery காணப்பட்டது',
      'mark_false_alert': 'இது false alert போல உள்ளது',
      'save_outcome': 'Observation save செய்',
      'model_card_title': 'PhytoSense AI decision-support model card',
      'model_card_intro':
          'App-ஐ எப்படி பயன்படுத்த வேண்டும் மற்றும் எதற்குப் பயன்படுத்தக்கூடாது என்பதன் தெளிவான விளக்கம்.',
      'model_intended_use': 'Intended use',
      'model_intended_use_body':
          'Early plant-stress screening மற்றும் crop-specific potential issue inspection. Disease confirm அல்லது chemical prescribe செய்யாது.',
      'model_inputs': 'Inputs மற்றும் crop scope',
      'model_inputs_body':
          'Camera colour evidence, crop confirmation, soil moisture, temperature, humidity, light, electrode signal மற்றும் optional fresh weather. 10 Tamil Nadu crop contexts; tomato-க்கு விரிவான questionnaire.',
      'model_method': 'Reasoning method',
      'model_method_body':
          'Validated thresholds, recent trends, crop context மற்றும் explainable evidence rules மூலம் ranked candidates மற்றும் inspection guidance தரப்படும்.',
      'model_limitations': 'Known limitations',
      'model_limitations_body':
          'Lighting, leaf angle, sensor placement, crop variety மற்றும் unmeasured causes result-ஐ மாற்றலாம். Match score accuracy அல்லது confirmed diagnosis அல்ல.',
      'model_privacy': 'Privacy மற்றும் ownership',
      'model_privacy_body':
          'Leaf analysis device-ல் நடக்கும். Offline queue numeric ESP32 readings மட்டும் store செய்யும்; photos இல்லை. Demo readings upload ஆகாது.',
      'model_validation': 'Validation status',
      'model_validation_body':
          'Software flow மற்றும் range checks செயல்படுத்தப்பட்டுள்ளது. Physical accuracy-க்கு calibration, repeated trials, expert labels மற்றும் false-alert measurement தேவை.',
      'experience_mode': 'App அனுபவம்',
      'experience_mode_body':
          'தினசரி விவசாய பயன்பாட்டை எளிமையாக வைத்துக்கொள்ளவும் அல்லது முழு engineering மற்றும் competition workspace-ஐ பார்க்கவும்.',
      'farmer_mode': 'Farmer Mode',
      'farmer_mode_body':
          'பெரிய actions, எளிய guidance மற்றும் கேட்டால் மட்டும் technical details.',
      'judge_mode': 'Judge Mode',
      'judge_mode_body':
          'Architecture, evidence, calibration, experiments மற்றும் presentation tools.',
      'large_text': 'பெரிய எழுத்து',
      'large_text_body':
          'Responsive layout மாறாமல் வாசிப்பு அளவை அதிகரிக்கும்.',
      'reduced_motion': 'Motion குறை',
      'reduced_motion_body':
          'தேவையற்ற pulse மற்றும் visual transition-ஐ குறைக்கும்.',
      'onboarding_experience_title': 'உங்கள் அனுபவத்தை தேர்வு செய்யுங்கள்',
      'onboarding_experience_body':
          'Farmer Mode நேரடியாக இருக்கும். Judge Mode விரிவான technical evidence-ஐ காட்டும். இதை எப்போது வேண்டுமானாலும் மாற்றலாம்.',
      'observation_timeline': 'Plant Observation Timeline',
      'observation_timeline_menu_body':
          'Reading, alert, trial, calibration மற்றும் weather ஒரே evidence trail-ல்.',
      'observation_timeline_body':
          'System அளந்தது, விளக்கியது மற்றும் பதிவு செய்ததற்கான source-isolated history.',
      'timeline_latest_reading': 'சமீபத்திய validated reading',
      'timeline_latest_reading_body':
          '{node} plant health score {health} என்று தெரிவித்தது.',
      'timeline_trial_body': '{samples} samples • {outcome}',
      'timeline_calibration': 'Calibration profile save செய்யப்பட்டது',
      'timeline_calibration_body':
          '{samples} baseline samples-ல் {score}% consistency.',
      'timeline_weather': 'Weather context புதுப்பிக்கப்பட்டது',
      'timeline_system': 'System',
      'timeline_empty': 'இந்த view-ல் observation இல்லை',
      'timeline_empty_body':
          'புதிய readings, alerts மற்றும் measured trials தானாக இங்கே வரும்.',
      'daily_briefing': 'இன்றைய plant briefing',
      'daily_briefing_waiting':
          'Guidance உருவாக்க validated reading-க்காக காத்திருக்கிறது.',
      'daily_alert_count': '{value} unread alerts',
      'farmer_next_action': 'இப்போது செய்ய வேண்டியது',
      'hear_guidance': 'Guidance கேளுங்கள்',
      'history': 'History',
      'preferred_soil_range': 'சிறந்த அளவு: 45–75%',
      'preferred_temperature_range': 'சிறந்த அளவு: 20–32°C',
      'preferred_humidity_range': 'சிறந்த அளவு: 45–80%',
      'preferred_light_range': 'சிறந்த அளவு: 35–90%',
      'preferred_signal_range': 'Calibrated baseline உடன் ஒப்பிடவும்',
      'preferred_stress_range': 'குறைவாக இருப்பது நல்லது',
      'view_sensor_details': 'Sensor details பார்க்கவும்',
      'view_sensor_details_body':
          'Technical values, trends மற்றும் preferred ranges-ஐ திறக்கவும்.',
      'clear_alerts_confirm_title': 'இந்த alert session-ஐ clear செய்யவா?',
      'clear_alerts_confirm_body':
          'Visible alerts மட்டும் நீங்கும். Saved farmer outcomes மற்றும் experiment evidence delete ஆகாது.',
      'alert_archived': 'Alert archive செய்யப்பட்டது.',
      'undo': 'மீட்டெடு',
      'screening_step_crop': 'பயிர்',
      'screening_step_photo': 'படம்',
      'screening_step_evidence': 'Evidence',
      'screening_step_result': 'முடிவு',
      'reset_presentation': 'Presentation reset செய்',
      'presentation_dashboard_title': 'ஒரே screen decision dashboard',
      'presentation_dashboard_body':
          'Active source, plant condition, validated sensors மற்றும் explainable reasoning ஒன்றாக காட்டும்.',
      'presentation_dashboard_1':
          'Demo மற்றும் ESP32 history கலக்காமல் live snapshot update ஆகும்.',
      'presentation_dashboard_2':
          'ஒவ்வொரு recommendation-மும் visible evidence உடன் இணைந்திருக்கும்.',
      'alert_needs_action': 'Action தேவை',
      'monitor': 'கண்காணி',
      'resolved': 'தீர்வு பதிவு',
      'system': 'System',
      'command_search': 'App-ல் தேடுங்கள்',
      'command_search_hint': 'PhytoSense AI-ல் தேடுங்கள்',
      'command_no_results':
          'பொருத்தமான tool கிடைக்கவில்லை. “sensor”, “timeline” அல்லது “settings” என்று தேடுங்கள்.',
      'clear_search': 'Search-ஐ clear செய்',
      'presentation_mode_body':
          'Live evidence snapshot உடன் guided, reset செய்யக்கூடிய judge story.',
    },
  };
}

extension AppStringsContext on BuildContext {
  AppStrings get strings =>
      AppStrings(AppScope.of(this).settings.value.languageCode);

  String tr(String key, [Map<String, Object> values = const {}]) =>
      strings.text(key, values);
}
