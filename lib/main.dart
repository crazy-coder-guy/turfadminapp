import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/firebase/analytics_service.dart';
import 'core/firebase/crashlytics_service.dart';
import 'core/firebase/push_notification_service.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'firebase_options.dart';

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

    CrashlyticsService.install();
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    runApp(const ProviderScope(child: TurfAdminApp()));
  }, (error, stack) => FirebaseCrashlytics.instance.recordError(error, stack, fatal: true));
}

class TurfAdminApp extends ConsumerStatefulWidget {
  const TurfAdminApp({super.key});

  @override
  ConsumerState<TurfAdminApp> createState() => _TurfAdminAppState();
}

class _TurfAdminAppState extends ConsumerState<TurfAdminApp> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(pushNotificationServiceProvider).initialize());
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Turf Admin',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: router,
    );
  }
}
