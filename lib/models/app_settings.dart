import 'package:flutter/material.dart';

class AppSettings {
  ThemeMode themeMode = ThemeMode.system;
  bool metricUnits = true;
  bool notificationsEnabled = true;
  bool onboardingComplete = false;
  String languageCode = 'en';
  String demoScenario = 'healthy';
  String dataSource = 'simulation';
  String esp32Endpoint = 'http://192.168.4.1';
  String hardwareTransportMode = 'AUTO';
  String syncEndpoint = '';
  String experienceMode = 'farmer';
  bool reducedMotion = false;
  bool largeText = false;
}
