import 'package:flutter_test/flutter_test.dart';
import 'package:streetbike_rental/main.dart';

void main() {
  testWidgets('App loads smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const YatinBikeRentApp());

    expect(find.text('StreetBike Rental'), findsWidgets);
  });
}
