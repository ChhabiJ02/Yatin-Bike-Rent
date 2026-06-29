// Basic smoke test for Yatin Bike Rent app.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:streetbike_rental/main.dart';

void main() {
  testWidgets('YatinBikeRentApp builds without throwing', (WidgetTester tester) async {
    // Build the app and trigger a frame.
    await tester.pumpWidget(const YatinBikeRentApp());
    await tester.pump();

    // Verify the app root widget is present.
    expect(find.byType(YatinBikeRentApp), findsOneWidget);
    expect(find.byType(MaterialApp), findsOneWidget);
  });

  test('YatinBikeRentApp is a StatelessWidget', () {
    expect(const YatinBikeRentApp(), isA<StatelessWidget>());
  });
}
