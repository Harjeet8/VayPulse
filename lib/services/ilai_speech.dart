import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class IlaiSpeech extends ChangeNotifier {
  static const channel = MethodChannel('com.harjeet.phytosense/speech');
  bool busy = false, listening = false, _disposed = false;
  int _generation = 0;
  IlaiSpeech() {
    channel.setMethodCallHandler((call) async {
      if (!_disposed && busy && call.method == 'state') {
        listening = call.arguments == 'listening';
        notifyListeners();
      }
    });
  }
  Future<String?> listen(String language) async {
    if (busy) return null;
    final ticket = ++_generation;
    busy = true;
    notifyListeners();
    try {
      final text = await channel.invokeMethod<String>('listen', {'language': language});
      return ticket == _generation && !_disposed ? text : null;
    } finally {
      if (!_disposed && ticket == _generation) {
        busy = false;
        listening = false;
        notifyListeners();
      }
    }
  }
  Future<void> cancel() async {
    _generation++;
    busy = false;
    listening = false;
    if (!_disposed) notifyListeners();
    try { await channel.invokeMethod<void>('cancel'); } catch (_) {}
  }
  @override
  void dispose() {
    _disposed = true;
    cancel();
    channel.setMethodCallHandler(null);
    super.dispose();
  }
}
