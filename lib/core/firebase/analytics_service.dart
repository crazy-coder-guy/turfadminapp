import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final firebaseAnalyticsProvider = Provider<FirebaseAnalytics>((ref) => FirebaseAnalytics.instance);

/// Attach to `GoRouter(observers: [...])` to get automatic screen_view
/// events as the tenant admin navigates between sections.
final firebaseAnalyticsObserverProvider = Provider<FirebaseAnalyticsObserver>((ref) {
  return FirebaseAnalyticsObserver(analytics: ref.watch(firebaseAnalyticsProvider));
});
