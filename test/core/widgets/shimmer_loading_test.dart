import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:blightscan/core/widgets/shimmer_loading.dart';

void main() {
  group('ShimmerLoading Widget Tests', () {
    testWidgets('renders with correct dimensions', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ShimmerLoading(
              width: 100,
              height: 50,
              borderRadius: 8.0,
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(find.byType(Container).first);
      expect(container.constraints?.maxWidth, equals(100));
      expect(container.constraints?.maxHeight, equals(50));
    });

    testWidgets('ShimmerBox fills width by default', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ShimmerBox(height: 50),
          ),
        ),
      );

      final container = tester.widget<Container>(find.byType(Container).first);
      expect(container.constraints?.maxWidth, equals(double.infinity));
    });

    testWidgets('ShimmerCircle renders as circular', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ShimmerCircle(size: 50),
          ),
        ),
      );

      final container = tester.widget<Container>(find.byType(Container).first);
      expect(container.constraints?.maxWidth, equals(50));
      expect(container.constraints?.maxHeight, equals(50));
    });

    testWidgets('ShimmerList renders multiple items', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ShimmerList(itemCount: 3, itemHeight: 80),
          ),
        ),
      );

      expect(find.byType(ShimmerCard), findsNWidgets(3));
    });

    testWidgets('ShimmerText renders multiple lines', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ShimmerText(lines: 3),
          ),
        ),
      );

      expect(find.byType(ShimmerLoading), findsNWidgets(3));
    });
  });
}
