import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Wires Flutter's own error channels (widget build errors and errors
/// escaping the root zone) into Crashlytics. Call once from `main()`,
/// inside the same `runZonedGuarded` that runs the app, before `runApp`.
class CrashlyticsService {
  CrashlyticsService._();

  static void install() {
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  }
}
