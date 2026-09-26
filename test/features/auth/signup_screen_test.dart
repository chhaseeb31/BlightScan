import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:blightscan/features/auth/presentation/screens/signup_screen.dart';
import 'package:blightscan/core/widgets/gs_button.dart';
import 'package:blightscan/core/widgets/gs_input_field.dart';

void main() {
  group('SignupScreen Widget Tests', () {
    testWidgets('renders all required UI elements',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SignupScreen(),
        ),
      );

      expect(find.text('Create Account'), findsOneWidget);
      expect(find.text('Full Name'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.byType(GSInputField), findsNWidgets(3));
      expect(find.byType(GSButton), findsOneWidget);
      expect(find.text('Sign Up'), findsOneWidget);
      expect(find.text('Already have an account?'), findsOneWidget);
      expect(find.text('Login'), findsOneWidget);
    });

    testWidgets('shows validation error for empty name',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SignupScreen(),
        ),
      );

      await tester.tap(find.byType(GSButton));
      await tester.pumpAndSettle();

      expect(find.text('Please enter your full name'), findsOneWidget);
    });

    testWidgets('shows validation error for invalid email',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SignupScreen(),
        ),
      );

      final nameField = find.byType(GSInputField).first;
      await tester.enterText(nameField, 'John Doe');

      final emailField = find.byType(GSInputField).at(1);
      await tester.enterText(emailField, 'invalid-email');

      await tester.tap(find.byType(GSButton));
      await tester.pumpAndSettle();

      expect(find.text('Please enter your email'), findsOneWidget);
    });

    testWidgets('shows validation error for weak password',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SignupScreen(),
        ),
      );

      final nameField = find.byType(GSInputField).first;
      await tester.enterText(nameField, 'John Doe');

      final emailField = find.byType(GSInputField).at(1);
      await tester.enterText(emailField, 'john@example.com');

      final passwordField = find.byType(GSInputField).at(2);
      await tester.enterText(passwordField, 'weak');

      await tester.tap(find.byType(GSButton));
      await tester.pumpAndSettle();

      expect(
          find.text('Password must be at least 8 characters'), findsOneWidget);
    });

    testWidgets('shows validation error for password without uppercase',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SignupScreen(),
        ),
      );

      final nameField = find.byType(GSInputField).first;
      await tester.enterText(nameField, 'John Doe');

      final emailField = find.byType(GSInputField).at(1);
      await tester.enterText(emailField, 'john@example.com');

      final passwordField = find.byType(GSInputField).at(2);
      await tester.enterText(passwordField, 'password123');

      await tester.tap(find.byType(GSButton));
      await tester.pumpAndSettle();

      expect(find.text('Password must contain at least one uppercase letter'),
          findsOneWidget);
    });
  });
}
