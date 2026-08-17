import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flousi_app/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const FlousiApp());

    // Verify that the splash screen shows
    expect(find.text('فلوسي'), findsOneWidget);
    expect(find.text('My Money'), findsOneWidget);
  });
}
