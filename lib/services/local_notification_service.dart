import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Bridges PhytoSense in-app alerts to the device notification tray.
///
/// Sensor/ESP32 logic stays authoritative; this service only presents alerts
/// that [AlertService] has already decided should be shown.
class LocalNotificationService {
  static const _channelId = 'phytosense_plant_health';
  static const _channelName = 'Plant health alerts';
  static const _channelDescription =
      'Important crop, sensor and PhytoSense edge-intelligence alerts.';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> initialize({required bool requestPermission}) async {
    if (kIsWeb || _initialized) return;

    try {
      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      const darwin = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      const settings = InitializationSettings(
        android: android,
        iOS: darwin,
        macOS: darwin,
      );

      await _plugin.initialize(settings);
      _initialized = true;

      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.createNotificationChannel(
        const AndroidNotificationChannel(
          _channelId,
          _channelName,
          description: _channelDescription,
          importance: Importance.high,
        ),
      );

      if (requestPermission) {
        await androidPlugin?.requestNotificationsPermission();
        await _plugin
            .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(alert: true, badge: true, sound: true);
        await _plugin
            .resolvePlatformSpecificImplementation<
                MacOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(alert: true, badge: true, sound: true);
      }
    } catch (error, stackTrace) {
      _initialized = false;
      debugPrint('Local notifications unavailable: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> showAlert({
    required String title,
    required String body,
    required bool critical,
  }) async {
    if (kIsWeb) return;
    if (!_initialized) {
      await initialize(requestPermission: false);
    }
    if (!_initialized) return;

    try {
      final androidDetails = AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: critical ? Importance.max : Importance.high,
        priority: critical ? Priority.max : Priority.high,
        category: AndroidNotificationCategory.alarm,
        visibility: NotificationVisibility.public,
        ticker: title,
      );
      const darwinDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      await _plugin.show(
        DateTime.now().millisecondsSinceEpoch.remainder(2147483647),
        title,
        body,
        NotificationDetails(
          android: androidDetails,
          iOS: darwinDetails,
          macOS: darwinDetails,
        ),
      );
    } catch (error, stackTrace) {
      debugPrint('Could not show local notification: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }
}
