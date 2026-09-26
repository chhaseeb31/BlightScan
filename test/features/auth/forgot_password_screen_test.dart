import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:blightscan/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:blightscan/core/widgets/gs_button.dart';
import 'package:blightscan/core/widgets/gs_input_field.dart';

void main() {
  group('ForgotPasswordScreen Widget Tests', () {
    testWidgets('renders all required UI elements',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ForgotPasswordScreen(),
        ),
      );

      expect(find.text('Reset Your Password'), findsOneWidget);
      expect(find.text('Your Registered Email'), findsOneWidget);
      expect(find.byType(GSInputField), findsOneWidget);
      expect(find.byType(GSButton), findsOneWidget);
      expect(find.text('Send Reset Link'), findsOneWidget);
    });

    testWidgets('shows validation error for empty email',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ForgotPasswordScreen(),
        ),
      );

      await tester.tap(find.byType(GSButton));
      await tester.pumpAndSettle();

      expect(find.text('Please enter your email'), findsOneWidget);
    });

    testWidgets('shows validation error for invalid email format',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ForgotPasswordScreen(),
        ),
      );

      final emailField = find.byType(GSInputField).first;
      await tester.enterText(emailField, 'invalid-email');

      await tester.tap(find.byType(GSButton));
      await tester.pumpAndSettle();

      expect(find.text('Please enter a valid email address'), findsOneWidget);
    });
  });
}
