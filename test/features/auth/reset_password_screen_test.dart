import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:blightscan/features/auth/presentation/screens/reset_password_screen.dart';
import 'package:blightscan/core/widgets/gs_button.dart';
import 'package:blightscan/core/widgets/gs_input_field.dart';

void main() {
  group('ResetPasswordScreen Widget Tests', () {
    testWidgets('renders all required UI elements',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ResetPasswordScreen(),
        ),
      );

      expect(find.text('Secure Your Account'), findsOneWidget);
      expect(find.text('New Password'), findsOneWidget);
      expect(find.text('Confirm New Password'), findsOneWidget);
      expect(find.byType(GSInputField), findsNWidgets(2));
      expect(find.byType(GSButton), findsOneWidget);
      expect(find.text('Save New Password'), findsOneWidget);
    });

    testWidgets('shows validation error for empty password',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ResetPasswordScreen(),
        ),
      );

      await tester.tap(find.byType(GSButton));
      await tester.pumpAndSettle();

      expect(find.text('Please create a password'), findsOneWidget);
    });

    testWidgets('shows validation error for short password',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ResetPasswordScreen(),
        ),
      );

      final passwordField = find.byType(GSInputField).first;
      await tester.enterText(passwordField, 'short');

      await tester.tap(find.byType(GSButton));
      await tester.pumpAndSettle();

      expect(
          find.text('Password must be at least 8 characters'), findsOneWidget);
    });

    testWidgets('shows validation error for password without uppercase',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ResetPasswordScreen(),
        ),
      );

      final passwordField = find.byType(GSInputField).first;
      await tester.enterText(passwordField, 'password123');

      await tester.tap(find.byType(GSButton));
      await tester.pumpAndSettle();

      expect(find.text('Password must contain at least one uppercase letter'),
          findsOneWidget);
    });

    testWidgets('shows validation error for password without lowercase',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ResetPasswordScreen(),
        ),
      );

      final passwordField = find.byType(GSInputField).first;
      await tester.enterText(passwordField, 'PASSWORD123');

      await tester.tap(find.byType(GSButton));
      await tester.pumpAndSettle();

      expect(find.text('Password must contain at least one lowercase letter'),
          findsOneWidget);
    });

    testWidgets('shows validation error for password without number',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ResetPasswordScreen(),
        ),
      );

      final passwordField = find.byType(GSInputField).first;
      await tester.enterText(passwordField, 'PasswordABC');

      await tester.tap(find.byType(GSButton));
      await tester.pumpAndSettle();

      expect(find.text('Password must contain at least one number'),
          findsOneWidget);
    });

    testWidgets('shows validation error when passwords do not match',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ResetPasswordScreen(),
        ),
      );

      final passwordField = find.byType(GSInputField).first;
      await tester.enterText(passwordField, 'Password123');

      final confirmField = find.byType(GSInputField).at(1);
      await tester.enterText(confirmField, 'DifferentPass123');

      await tester.tap(find.byType(GSButton));
      await tester.pumpAndSettle();

      expect(find.text('Passwords do not match'), findsOneWidget);
    });
  });
}
