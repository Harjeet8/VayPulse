import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

/// Firebase project configuration for the PhytoSense Android app.
///
/// These values identify the Firebase project; they are not the ESP32
/// authentication credentials. Hardware secrets remain outside the APK.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'PhytoSense remote hardware monitoring is configured for Android.',
      );
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'PhytoSense remote hardware monitoring is configured for Android.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCWW6BUmajZmXoW2_OnUyun2eQMWHGZZ64',
    appId: '1:395432351362:android:22ecc99cf11fdd991ec69b',
    messagingSenderId: '395432351362',
    projectId: 'phytosense-ai-1b0d8',
    databaseURL:
        'https://phytosense-ai-1b0d8-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'phytosense-ai-1b0d8.firebasestorage.app',
  );
}
