import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Firebase bootstrap for MVP.
///
/// We intentionally avoid embedding any Firebase secrets/config in source.
/// If the project isn't configured yet (e.g. missing web/firebase options),
/// initialization may fail; in that case we continue to run UI-only.
class FirebaseBootstrap {
  static bool _initialized = false;

  static bool get initialized => _initialized;

  static Future<void> initialize() async {
    // On Web, calling Firebase.initializeApp() without FirebaseOptions
    // can cause runtime JS errors in firebase_core.
    // Until we add flutterfire-generated options, we skip init on Web.
    if (kIsWeb) {
      debugPrint('Firebase init skipped on web (not configured yet)');
      _initialized = false;
      return;
    }

    try {
      await Firebase.initializeApp();
      debugPrint('Firebase initialized');
      _initialized = true;
    } catch (e, st) {
      debugPrint('Firebase init skipped (not configured yet): $e');
      _initialized = false;
      if (kDebugMode) {
        debugPrintStack(stackTrace: st);
      }
    }
  }
}
