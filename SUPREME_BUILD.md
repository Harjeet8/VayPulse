# PhytoSense AI SUPREME

This branch is the competition-ready PhytoSense AI build.

## Hardware contract

- ESP32 DevKit V1
- AP SSID: `PhytoSense_AI`
- Local address: `http://192.168.4.1`
- Primary sensor API: `http://192.168.4.1/api/sensors`
- Works directly over the ESP32 access point without internet, router or cloud.

## Real sensors

AHT10, BH1750, capacitive soil moisture, DS18B20 root-zone temperature, leaf-wetness sensor, ADS1115 + AD620 + plant electrodes, DS3231 RTC and SH1106 OLED. There is no EC sensor dependency.

## Health analysis

Both simulation and ESP32 hardware data are routed through the same offline `HealthAnalysisEngine`. The app shows a **PhytoSense Health Index** as decision support, while preserving the embedded ESP32 health score separately for diagnostics. Missing sensors are excluded and weights are renormalized; they reduce analysis confidence instead of making plant condition zero.

Tomato is the primary portable live-demo crop. Sugarcane remains only as an optional crop in the wider catalog.

## Physical calibration still required

Replace the firmware's provisional soil and leaf dry/wet ADC references with measurements from the actual installed probes. Bioelectric interpretation uses the plant/node's learned baseline rather than a universal millivolt threshold.
