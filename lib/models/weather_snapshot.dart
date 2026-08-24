class WeatherDay {
  final DateTime date;
  final double minimumTemperature;
  final double maximumTemperature;
  final double precipitationProbability;
  final double precipitationMillimetres;
  final int weatherCode;

  const WeatherDay({
    required this.date,
    required this.minimumTemperature,
    required this.maximumTemperature,
    required this.precipitationProbability,
    required this.precipitationMillimetres,
    required this.weatherCode,
  });

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'minimumTemperature': minimumTemperature,
        'maximumTemperature': maximumTemperature,
        'precipitationProbability': precipitationProbability,
        'precipitationMillimetres': precipitationMillimetres,
        'weatherCode': weatherCode,
      };

  factory WeatherDay.fromJson(Map<String, dynamic> json) => WeatherDay(
        date: DateTime.tryParse('${json['date']}') ?? DateTime.now(),
        minimumTemperature: _number(json['minimumTemperature']),
        maximumTemperature: _number(json['maximumTemperature']),
        precipitationProbability: _number(json['precipitationProbability']),
        precipitationMillimetres: _number(json['precipitationMillimetres']),
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

  const WeatherSnapshot({
    required this.location,
    required this.updatedAt,
    required this.temperature,
    required this.humidity,
    required this.windSpeed,
    required this.weatherCode,
    required this.forecast,
  });

  WeatherDay? get today => forecast.isEmpty ? null : forecast.first;

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
      };

  factory WeatherSnapshot.fromJson(Map<String, dynamic> json) =>
      WeatherSnapshot(
        location: '${json['location'] ?? 'Coimbatore, Tamil Nadu'}',
        updatedAt: DateTime.tryParse('${json['updatedAt']}') ?? DateTime.now(),
        temperature: _number(json['temperature']),
        humidity: _number(json['humidity']),
        windSpeed: _number(json['windSpeed']),
        weatherCode: _number(json['weatherCode']).round(),
        forecast: (json['forecast'] as List? ?? const [])
            .map((item) => WeatherDay.fromJson(
                  Map<String, dynamic>.from(item as Map),
                ))
            .toList(),
      );

  static double _number(dynamic value) =>
      value is num ? value.toDouble() : double.tryParse('$value') ?? 0;
}
