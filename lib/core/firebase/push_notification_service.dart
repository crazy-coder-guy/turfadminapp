import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Must be a top-level (or static) function - FCM runs it in a separate
/// isolate when a data/notification message arrives while the app is
/// backgrounded or terminated. Register it in `main()` BEFORE `runApp`,
/// via `FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler)`.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase.initializeApp() must already have run in this isolate before
  // this handler fires; the plugin re-invokes main()'s init automatically
  // as long as Firebase.initializeApp() is the first thing main() does.
  debugPrint('[push] background message: ${message.messageId}');
}

final firebaseMessagingProvider = Provider<FirebaseMessaging>((ref) => FirebaseMessaging.instance);

/// Holds the current FCM device token so the rest of the app (once a
/// backend "register device token" endpoint exists) can push it up on
/// login. No such endpoint exists yet - this only tracks the token
/// locally today.
final fcmTokenProvider = StateProvider<String?>((ref) => null);

class PushNotificationService {
  PushNotificationService(this._ref);

  final Ref _ref;

  FirebaseMessaging get _messaging => _ref.read(firebaseMessagingProvider);

  Future<void> initialize() async {
    await _messaging.requestPermission(alert: true, badge: true, sound: true);

    await _messaging.setForegroundNotificationPresentationOptions(alert: true, badge: true, sound: true);

    final token = await _messaging.getToken();
    _ref.read(fcmTokenProvider.notifier).state = token;
    _messaging.onTokenRefresh.listen((newToken) {
      _ref.read(fcmTokenProvider.notifier).state = newToken;
    });

    FirebaseMessaging.onMessage.listen((message) {
      debugPrint('[push] foreground message: ${message.notification?.title}');
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      debugPrint('[push] notification tapped: ${message.messageId}');
      // TODO: route to the relevant screen (e.g. a specific turf/court)
      // once notification payloads carry a deep-link target.
    });
  }
}

final pushNotificationServiceProvider = Provider<PushNotificationService>((ref) {
  return PushNotificationService(ref);
});
