import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_settings.dart';

class SettingsService extends ChangeNotifier {
  final value = AppSettings();
  bool isLoaded = false;

  Future<void> load() async {
    try {
      final p = await SharedPreferences.getInstance();
      value.metricUnits = p.getBool('metricUnits') ?? true;
      value.notificationsEnabled = p.getBool('notifications') ?? true;
      value.languageCode = p.getString('languageCode') ?? 'en';
      value.demoScenario = p.getString('scenario') ?? 'healthy';
      value.dataSource = p.getString('dataSource') ?? 'simulation';
      value.esp32Endpoint =
          p.getString('esp32Endpoint') ?? 'http://192.168.4.1';
      value.syncEndpoint = p.getString('syncEndpoint') ?? '';
      value.reducedMotion = p.getBool('reducedMotion') ?? false;
      value.largeText = p.getBool('largeText') ?? false;
      final dark = p.getBool('dark');
      value.themeMode = dark == null
          ? ThemeMode.system
          : (dark ? ThemeMode.dark : ThemeMode.light);
    } finally {
      isLoaded = true;
      notifyListeners();
    }
  }

  Future<void> setTheme(ThemeMode mode) async {
    value.themeMode = mode;
    final p = await SharedPreferences.getInstance();
    if (mode == ThemeMode.system) {
      await p.remove('dark');
    } else {
      await p.setBool('dark', mode == ThemeMode.dark);
    }
    notifyListeners();
  }

  Future<void> setScenario(String scenario) async {
    value.demoScenario = scenario;
    final p = await SharedPreferences.getInstance();
    await p.setString('scenario', scenario);
    notifyListeners();
  }

  Future<void> setDataSource(String source) async {
    value.dataSource = source;
    final p = await SharedPreferences.getInstance();
    await p.setString('dataSource', source);
    notifyListeners();
  }

  Future<void> setEsp32Endpoint(String endpoint) async {
    value.esp32Endpoint = endpoint.trim().replaceFirst(RegExp(r'/$'), '');
    final p = await SharedPreferences.getInstance();
    await p.setString('esp32Endpoint', value.esp32Endpoint);
    notifyListeners();
  }

  Future<void> setSyncEndpoint(String endpoint) async {
    value.syncEndpoint = endpoint.trim().replaceFirst(RegExp(r'/$'), '');
    final p = await SharedPreferences.getInstance();
    await p.setString('syncEndpoint', value.syncEndpoint);
    notifyListeners();
  }

  Future<void> setMetricUnits(bool metric) async {
    value.metricUnits = metric;
    final p = await SharedPreferences.getInstance();
    await p.setBool('metricUnits', metric);
    notifyListeners();
  }

  Future<void> setNotifications(bool enabled) async {
    value.notificationsEnabled = enabled;
    final p = await SharedPreferences.getInstance();
    await p.setBool('notifications', enabled);
    notifyListeners();
  }

  Future<void> setLanguage(String languageCode) async {
    value.languageCode = languageCode;
    final p = await SharedPreferences.getInstance();
    await p.setString('languageCode', languageCode);
    notifyListeners();
  }


  Future<void> setReducedMotion(bool enabled) async {
    value.reducedMotion = enabled;
    final p = await SharedPreferences.getInstance();
    await p.setBool('reducedMotion', enabled);
    notifyListeners();
  }

  Future<void> setLargeText(bool enabled) async {
    value.largeText = enabled;
    final p = await SharedPreferences.getInstance();
    await p.setBool('largeText', enabled);
    notifyListeners();
  }


}
