// This is a basic Flutter widget test for WoTi Attendance app.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:woti_attendance/main.dart';

void main() {
  testWidgets('App launches and shows login screen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(MyApp());

    // Verify that the login screen is displayed with WoTi Attendance title
    expect(find.text('WoTi Attendance'), findsWidgets);
    expect(find.text('Welcome Back!'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(2)); // Email and password fields
    expect(find.text('Login'), findsOneWidget);
  });

  testWidgets('Register button navigates to register screen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(MyApp());

    // Find and tap the register button
    await tester.tap(find.text("Don't have an account? Register"));
    await tester.pumpAndSettle(); // Wait for navigation to complete

    // Verify that we're on the register screen
    expect(find.text('Register for WoTi Attendance'), findsOneWidget);
  });
}
