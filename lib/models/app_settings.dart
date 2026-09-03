import 'package:flutter/material.dart';

class AppSettings {
  ThemeMode themeMode = ThemeMode.system;
  bool metricUnits = true;
  bool notificationsEnabled = true;
  String languageCode = 'en';
  String demoScenario = 'healthy';
  String demoNodeId = 'node-tomato-a1';
  String dataSource = 'simulation';
  String esp32Endpoint = 'http://192.168.4.1';
  String syncEndpoint = '';
  bool reducedMotion = false;
  bool largeText = false;
}
