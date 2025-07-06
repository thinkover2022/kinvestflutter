// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kinvestflutter/main.dart';

void main() {
  testWidgets('KInvest app loads correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: KInvestApp(),
      ),
    );

    // Verify that the app title is displayed
    expect(find.text('KInvest Flutter'), findsOneWidget);
    
    // Verify that login is required message is shown
    expect(find.text('로그인이 필요합니다'), findsOneWidget);
    
    // Verify that login button is present
    expect(find.byIcon(Icons.login), findsOneWidget);
  });
}
