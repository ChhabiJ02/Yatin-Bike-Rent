import 'package:flutter_test/flutter_test.dart';
import 'package:street_bike_rental/services/challan_service.dart';
import 'package:street_bike_rental/services/document_scan_validator.dart';

void main() {
  test('accepts a driving license number split across OCR lines', () {
    expect(
      isDrivingLicenseFrontText('GJ05\n20190012345\nDRIVING LICENCE'),
      isTrue,
    );
  });

  test(
    'accepts a standard four-part license number without OCR title text',
    () {
      expect(isDrivingLicenseFrontText('GJ-05-2019-0012345'), isTrue);
    },
  );

  test('accepts license OCR with inconsistent spacing and punctuation', () {
    expect(
      isDrivingLicenseFrontText('DRIV1NG LICENCE GJ O5 / 2O19 / 0012345'),
      isTrue,
    );
  });

  test('accepts Aadhaar OCR when digits are split across lines', () {
    expect(isAadhaarFrontText('1234\n5678\n9012'), isTrue);
  });

  test('rejects a document without a license number', () {
    expect(isDrivingLicenseFrontText('DRIVING LICENCE CUSTOMER NAME'), isFalse);
  });

  test('extracts the license name without treating city as the name', () {
    const text = '''
DRIVING LICENCE
NAME: Ramesh Patel
ADDRESS: 12 Main Road
Ahmedabad
GJ-05-2019-0012345
''';
    expect(extractDrivingLicenseName(text), 'Ramesh Patel');
  });

  test('buildCustomerCode formats the financial year prefix correctly', () {
    expect(ChallanService.buildCustomerCode('2025-2026', 1), '25260001');
    expect(ChallanService.buildCustomerCode('2026-2027', 1), '26270001');
  });

  test(
    'getNextCustomerCodeFromHighest returns the first code for a new financial year',
    () {
      expect(
        ChallanService.getNextCustomerCodeFromHighest('2026-2027', null),
        '26270001',
      );
    },
  );

  test(
    'getNextCustomerCodeFromHighest increments the last four digits only',
    () {
      expect(
        ChallanService.getNextCustomerCodeFromHighest('2026-2027', '26270015'),
        '26270016',
      );
      expect(
        ChallanService.getNextCustomerCodeFromHighest('2026-2027', '26270099'),
        '26270100',
      );
    },
  );

  test(
    'getNextCustomerCodeFromHighest respects the provided financial year prefix',
    () {
      expect(
        ChallanService.getNextCustomerCodeFromHighest('2026-2027', '26270500'),
        '26270501',
      );
    },
  );
}
