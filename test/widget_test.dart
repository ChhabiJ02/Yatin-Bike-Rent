import 'package:flutter_test/flutter_test.dart';
import 'package:street_bike_rental/app.dart';

void main() {
  testWidgets('App loads smoke test', (WidgetTester tester) async {
    // This test is very basic and will likely need to be expanded.
    // It ensures the app can be built without crashing.
    await tester.pumpWidget(const StreetBikeRentalApp());

    expect(find.text('StreetBike Rental'), findsWidgets);
  });
}
