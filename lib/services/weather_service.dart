import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/weather_snapshot.dart';
import 'location_name_resolver.dart';

class WeatherService extends ChangeNotifier {
  double latitude = 11.0168;
  double longitude = 76.9558;
  String location = 'Coimbatore, Tamil Nadu';

  WeatherSnapshot? snapshot;
  bool loading = false;
  bool usingCachedData = false;
  bool locating = false;
  String? errorKey;
  String? locationErrorKey;

  bool get isFresh =>
      snapshot != null &&
      DateTime.now().difference(snapshot!.updatedAt).inHours < 12;

  Future<void> load() async {
    final preferences = await SharedPreferences.getInstance();
    latitude = preferences.getDouble('weatherLatitude') ?? latitude;
    longitude = preferences.getDouble('weatherLongitude') ?? longitude;
    location = preferences.getString('weatherLocation') ?? location;
    final cached = preferences.getString('weatherCache');
    if (cached != null) {
      try {
        snapshot = WeatherSnapshot.fromJson(
          Map<String, dynamic>.from(jsonDecode(cached) as Map),
        );
        usingCachedData = true;
      } catch (_) {
        // A corrupt cache is ignored and replaced by the next live response.
      }
    }
    notifyListeners();
    await refresh();
  }

  Future<bool> refresh() async {
    if (loading) return false;
    loading = true;
    errorKey = null;
    notifyListeners();
    try {
      final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
        'latitude': '$latitude',
        'longitude': '$longitude',
        'current':
            'temperature_2m,relative_humidity_2m,weather_code,wind_speed_10m',
        'daily': 'weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max,precipitation_sum',
        'forecast_days': '5',
        'timezone': 'auto',
      });
      final response = await http.get(uri).timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) throw Exception('weather http');
      final json = Map<String, dynamic>.from(jsonDecode(response.body) as Map);
      final current = Map<String, dynamic>.from(json['current'] as Map);
      final daily = Map<String, dynamic>.from(json['daily'] as Map);
      final dates = List<dynamic>.from(daily['time'] as List);
      final weatherCodes = List<dynamic>.from(daily['weather_code'] as List);
      final maximums = List<dynamic>.from(daily['temperature_2m_max'] as List);
      final minimums = List<dynamic>.from(daily['temperature_2m_min'] as List);
      final rainProbabilities = List<dynamic>.from(
        daily['precipitation_probability_max'] as List,
      );
      final rainTotals = List<dynamic>.from(daily['precipitation_sum'] as List);
      final days = <WeatherDay>[];
      for (var index = 0; index < dates.length; index++) {
        days.add(
          WeatherDay(
            date: DateTime.parse('${dates[index]}'),
            minimumTemperature: _number(minimums[index]),
            maximumTemperature: _number(maximums[index]),
            precipitationProbability: _number(rainProbabilities[index]),
            precipitationMillimetres: _number(rainTotals[index]),
            weatherCode: _number(weatherCodes[index]).round(),
          ),
        );
      }
      snapshot = WeatherSnapshot(
        location: location,
        updatedAt: DateTime.now(),
        temperature: _number(current['temperature_2m']),
        humidity: _number(current['relative_humidity_2m']),
        windSpeed: _number(current['wind_speed_10m']),
        weatherCode: _number(current['weather_code']).round(),
        forecast: days,
      );
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(
        'weatherCache',
        jsonEncode(snapshot!.toJson()),
      );
      usingCachedData = false;
      loading = false;
      notifyListeners();
      return true;
    } catch (_) {
      loading = false;
      usingCachedData = snapshot != null;
      errorKey = snapshot == null ? 'weather_unavailable' : 'weather_cached';
      notifyListeners();
      return false;
    }
  }

  static double _number(dynamic value) =>
      value is num ? value.toDouble() : double.tryParse('$value') ?? 0;

  Future<void> configureLocation({
    required String name,
    required double latitude,
    required double longitude,
  }) async {
    this.latitude = latitude;
    this.longitude = longitude;
    location = name.trim();
    snapshot = null;
    usingCachedData = false;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setDouble('weatherLatitude', latitude);
    await preferences.setDouble('weatherLongitude', longitude);
    await preferences.setString('weatherLocation', location);
    await preferences.remove('weatherCache');
    notifyListeners();
    await refresh();
  }

  Future<bool> useDeviceLocation() async {
    if (locating) return false;
    locating = true;
    locationErrorKey = null;
    notifyListeners();
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        locationErrorKey = 'location_service_disabled';
        return false;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        locationErrorKey = 'location_permission_denied';
        return false;
      }
      if (permission == LocationPermission.deniedForever) {
        locationErrorKey = 'location_permission_denied_forever';
        return false;
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 15),
        ),
      );
      await configureLocation(
        name: LocationNameResolver.resolve(
          position.latitude,
          position.longitude,
        ),
        latitude: position.latitude,
        longitude: position.longitude,
      );
      return true;
    } catch (_) {
      locationErrorKey = 'location_unavailable';
      return false;
    } finally {
      locating = false;
      notifyListeners();
    }
  }
}
