import 'package:flutter_test/flutter_test.dart';
import 'package:street_bike_rental/services/challan_service.dart';

void main() {
  test('buildCustomerCode formats the financial year prefix correctly', () {
    expect(ChallanService.buildCustomerCode('2025-2026', 1), '25260001');
    expect(ChallanService.buildCustomerCode('2026-2027', 1), '26270001');
  });

  test('getNextCustomerCodeFromHighest returns the first code for a new financial year', () {
    expect(
      ChallanService.getNextCustomerCodeFromHighest('2026-2027', null),
      '26270001',
    );
  });

  test('getNextCustomerCodeFromHighest increments the last four digits only', () {
    expect(
      ChallanService.getNextCustomerCodeFromHighest('2026-2027', '26270015'),
      '26270016',
    );
    expect(
      ChallanService.getNextCustomerCodeFromHighest('2026-2027', '26270099'),
      '26270100',
    );
  });

  test('getNextCustomerCodeFromHighest respects the provided financial year prefix', () {
    expect(
      ChallanService.getNextCustomerCodeFromHighest('2026-2027', '26270500'),
      '26270501',
    );
  });
}
