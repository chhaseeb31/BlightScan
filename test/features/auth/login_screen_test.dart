import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:blightscan/features/auth/presentation/screens/login_screen.dart';
import 'package:blightscan/core/widgets/gs_input_field.dart';

void main() {
  group('LoginScreen Widget Tests', () {
    testWidgets('renders all required UI elements',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LoginScreen(),
        ),
      );

      expect(find.text('Welcome Back'), findsOneWidget);
      expect(find.text("Let's check your tomato leaves today"), findsOneWidget);
      expect(find.text('Remember me'), findsOneWidget);
      expect(find.text('Forgot Password?'), findsOneWidget);
      expect(find.text("Don't have an account? "), findsOneWidget);
      expect(find.text('Sign Up'), findsOneWidget);
      expect(find.byType(GSInputField), findsNWidgets(2));
    });

    testWidgets('toggles remember me state', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LoginScreen(),
        ),
      );

      expect(find.byIcon(Icons.check_rounded), findsOneWidget);

      await tester.tap(find.text('Remember me'));
      await tester.pump();

      expect(find.byIcon(Icons.check_rounded), findsNothing);

      await tester.tap(find.text('Remember me'));
      await tester.pump();

      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    });
  });
}
