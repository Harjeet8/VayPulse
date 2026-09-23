import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:phytosense_ai/models/alert.dart';
import 'package:phytosense_ai/services/alert_service.dart';
import 'package:phytosense_ai/services/farm_repository.dart';
import 'package:phytosense_ai/services/phone_notification_service.dart';
import 'package:phytosense_ai/services/sensor_provider_manager.dart';
import 'package:phytosense_ai/services/settings_service.dart';
import 'package:phytosense_ai/services/weather_service.dart';
import 'package:phytosense_ai/services/sensor_data_provider.dart';

class TestAlerts extends AlertService {
  TestAlerts(super.sensors, super.settings, super.weather, super.farms);
  void emit(String id) {
    alerts.add(PlantAlert(
        id: id,
        nodeId: 'plant',
        timestamp: DateTime.now(),
        titleKey: 'alert_severe_dryness',
        messageKey: 'alert_severe_dryness_message',
        severity: AlertSeverity.critical));
    notifyListeners();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('ai.phytosense.app/notifications');
  final calls = <MethodCall>[];
  bool permission = true;
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    calls.clear();
    permission = true;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      if (call.method == 'requestPermission' ||
          call.method == 'notificationsEnabled') return permission;
      return null;
    });
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  for (final language in ['en', 'ta']) {
    testWidgets(
        'notification respects $language and suppresses duplicate conditions',
        (tester) async {
      final settings = SettingsService()..value.languageCode = language;
      final sensors = SensorProviderManager(),
          weather = WeatherService(),
          farms = FarmRepository();
      sensors.configure(source: SensorDataSource.simulation, endpoint: sensors.hardwareEndpoint);
      final alerts = TestAlerts(sensors, settings, weather, farms);
      final service = PhoneNotificationService(alerts, settings)..start();
      alerts.emit('one');
      await tester.pump();
      final sent = calls.where((c) => c.method == 'showNotification').toList();
      expect(sent.length, 1);
      final args = sent.single.arguments as Map;
      expect(args['title'],
          language == 'ta' ? 'மண் மிகவும் உலர்ந்துள்ளது' : 'Soil is very dry');
      expect(
          args['sourceLabel'], language == 'ta' ? 'மாதிரி தரவு' : 'Simulation');
      if (language == 'ta') {
        expect(args['body'], isNot(matches(RegExp('[A-Za-z]'))));
        expect(args['actionLabel'], 'செயலியைத் திற');
      }
      alerts.emit('two');
      await tester.pump();
      expect(calls.where((c) => c.method == 'showNotification').length, 1);
      service.dispose();
      alerts.dispose();
      sensors.dispose();
      weather.dispose();
      settings.dispose();
    }, variant: TargetPlatformVariant.only(TargetPlatform.android));
  }

  testWidgets('permission granted in settings is detected without restarting',
      (tester) async {
    final settings = SettingsService();
    final sensors = SensorProviderManager(),
        weather = WeatherService(),
        farms = FarmRepository();
    final alerts = TestAlerts(sensors, settings, weather, farms);
    final service = PhoneNotificationService(alerts, settings)..start();
    permission = false;
    alerts.emit('denied');
    await tester.pump();
    expect(calls.where((c) => c.method == 'showNotification'), isEmpty);
    permission = true;
    alerts.emit('allowed');
    await tester.pump();
    expect(calls.where((c) => c.method == 'showNotification').length, 1);
    expect(calls.where((c) => c.method == 'requestPermission').length, 1);
    service.dispose();
    alerts.dispose();
    sensors.dispose();
    weather.dispose();
    settings.dispose();
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  test('preview is clearly labelled and never fabricates plant data', () async {
    expect(await PhoneNotificationService.showPreview('ta'), isTrue);
    final args = calls.last.arguments as Map;
    expect(args['title'], 'அறிவிப்பு மாதிரி');
    expect(args['summary'], contains('நேரடி அளவீடு அல்ல'));
    expect(args['notificationTag'], 'phytosense:preview');
  });
}
