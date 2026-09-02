class WeatherDay {
  final DateTime date;
  final double minimumTemperature;
  final double maximumTemperature;
  final double precipitationProbability;
  final double precipitationMillimetres;
  final int weatherCode;
  final double? uvIndex;

  const WeatherDay({
    required this.date,
    required this.minimumTemperature,
    required this.maximumTemperature,
    required this.precipitationProbability,
    required this.precipitationMillimetres,
    required this.weatherCode,
    this.uvIndex,
  });

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'minimumTemperature': minimumTemperature,
        'maximumTemperature': maximumTemperature,
        'precipitationProbability': precipitationProbability,
        'precipitationMillimetres': precipitationMillimetres,
        'weatherCode': weatherCode,
        'uvIndex': uvIndex,
      };

  factory WeatherDay.fromJson(Map<String, dynamic> json) => WeatherDay(
        date: DateTime.tryParse('${json['date']}') ?? DateTime.now(),
        minimumTemperature: _number(json['minimumTemperature']),
        maximumTemperature: _number(json['maximumTemperature']),
        precipitationProbability: _number(json['precipitationProbability']),
        precipitationMillimetres: _number(json['precipitationMillimetres']),
        weatherCode: _number(json['weatherCode']).round(),
        uvIndex: json['uvIndex'] == null ? null : _number(json['uvIndex']),
      );

  static double _number(dynamic value) =>
      value is num ? value.toDouble() : double.tryParse('$value') ?? 0;
}

class WeatherHour {
  final DateTime time;
  final double temperature;
  final double precipitationProbability;
  final int weatherCode;

  const WeatherHour({
    required this.time,
    required this.temperature,
    required this.precipitationProbability,
    required this.weatherCode,
  });

  Map<String, dynamic> toJson() => {
        'time': time.toIso8601String(),
        'temperature': temperature,
        'precipitationProbability': precipitationProbability,
        'weatherCode': weatherCode,
      };

  factory WeatherHour.fromJson(Map<String, dynamic> json) => WeatherHour(
        time: DateTime.tryParse('${json['time']}') ?? DateTime.now(),
        temperature: _number(json['temperature']),
        precipitationProbability: _number(json['precipitationProbability']),
        weatherCode: _number(json['weatherCode']).round(),
      );

  static double _number(dynamic value) =>
      value is num ? value.toDouble() : double.tryParse('$value') ?? 0;
}

class WeatherSnapshot {
  final String location;
  final DateTime updatedAt;
  final double temperature;
  final double humidity;
  final double windSpeed;
  final int weatherCode;
  final List<WeatherDay> forecast;
  final double? apparentTemperature;
  final double? currentRainMillimetres;
  final List<WeatherHour> hourly;

  const WeatherSnapshot({
    required this.location,
    required this.updatedAt,
    required this.temperature,
    required this.humidity,
    required this.windSpeed,
    required this.weatherCode,
    required this.forecast,
    this.apparentTemperature,
    this.currentRainMillimetres,
    this.hourly = const [],
  });

  WeatherDay? get today => forecast.isEmpty ? null : forecast.first;

  double? get currentRainChance =>
      hourly.isEmpty ? today?.precipitationProbability : hourly.first.precipitationProbability;

  double? get uvIndex => today?.uvIndex;

  bool get heavyRainRisk => forecast.take(2).any(
        (day) =>
            day.precipitationMillimetres >= 30 ||
            day.precipitationProbability >= 90,
      );

  bool get diseaseRisk {
    final rain = forecast.take(2).any(
          (day) => day.precipitationMillimetres >= 4,
        );
    return humidity >= 82 && rain && temperature >= 18 && temperature <= 33;
  }

  bool get drySpellRisk =>
      forecast.length >= 4 &&
      forecast.take(4).every(
            (day) =>
                day.precipitationProbability < 25 &&
                day.precipitationMillimetres < 1,
          );

  Map<String, dynamic> toJson() => {
        'location': location,
        'updatedAt': updatedAt.toIso8601String(),
        'temperature': temperature,
        'humidity': humidity,
        'windSpeed': windSpeed,
        'weatherCode': weatherCode,
        'forecast': forecast.map((day) => day.toJson()).toList(),
        'apparentTemperature': apparentTemperature,
        'currentRainMillimetres': currentRainMillimetres,
        'hourly': hourly.map((hour) => hour.toJson()).toList(),
      };

  factory WeatherSnapshot.fromJson(Map<String, dynamic> json) =>
      WeatherSnapshot(
        location: '${json['location'] ?? 'Tiruchirappalli, Tamil Nadu'}',
        updatedAt: DateTime.tryParse('${json['updatedAt']}') ?? DateTime.now(),
        temperature: _number(json['temperature']),
        humidity: _number(json['humidity']),
        windSpeed: _number(json['windSpeed']),
        weatherCode: _number(json['weatherCode']).round(),
        apparentTemperature: json['apparentTemperature'] == null
            ? null
            : _number(json['apparentTemperature']),
        currentRainMillimetres: json['currentRainMillimetres'] == null
            ? null
            : _number(json['currentRainMillimetres']),
        forecast: (json['forecast'] as List? ?? const [])
            .map((item) => WeatherDay.fromJson(
                  Map<String, dynamic>.from(item as Map),
                ))
            .toList(),
        hourly: (json['hourly'] as List? ?? const [])
            .map((item) => WeatherHour.fromJson(
                  Map<String, dynamic>.from(item as Map),
                ))
            .toList(),
      );

  static double _number(dynamic value) =>
      value is num ? value.toDouble() : double.tryParse('$value') ?? 0;
}
