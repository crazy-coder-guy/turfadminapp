import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turf_admin_app/shared/widgets/app_button.dart';

void main() {
  testWidgets('AppButton invokes onPressed when tapped', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppButton(label: 'Continue', onPressed: () => tapped = true),
        ),
      ),
    );

    await tester.tap(find.text('Continue'));
    await tester.pump();

    expect(tapped, isTrue);
  });

  testWidgets('AppButton shows a spinner and is not tappable while loading', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppButton(label: 'Continue', isLoading: true, onPressed: () => tapped = true),
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Continue'), findsNothing);

    await tester.tap(find.byType(AppButton), warnIfMissed: false);
    await tester.pump();
    expect(tapped, isFalse);
  });

  testWidgets('AppButton with null onPressed is disabled', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: AppButton(label: 'Continue', onPressed: null)),
      ),
    );

    final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(button.onPressed, isNull);
  });
}
