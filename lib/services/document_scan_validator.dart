bool isDrivingLicenseFrontText(String text) {
  final compact = text
      .toUpperCase()
      .replaceAll(RegExp(r'[^A-Z0-9]'), '')
      .replaceAll('O', '0');
  final hasNumber = RegExp(r'[A-Z]{2}\d{2}\d{8,15}').hasMatch(compact);
  final hasLicenseText =
      text.toLowerCase().contains('driv') ||
      text.toLowerCase().contains('licen') ||
      text.toLowerCase().contains('transport');
  return hasNumber || (hasLicenseText && RegExp(r'\d{8,15}').hasMatch(compact));
}

bool isAadhaarFrontText(String text) {
  final digits = text.replaceAll(RegExp(r'\D'), '');
  return RegExp(r'\d{12}').hasMatch(digits);
}

final drivingLicenseNumberPattern = RegExp(
  r'\b[A-Z]{2}\s*[-/]?\s*\d{2}\s*[-/]?\s*(?:\d{4}\s*[-/]?\s*)?\d{4,11}\b',
  caseSensitive: false,
);

String? extractDrivingLicenseNumber(String text) {
  final compact = text
      .toUpperCase()
      .replaceAll(RegExp(r'[^A-Z0-9]'), '')
      .replaceAll('O', '0');
  final match = RegExp(r'[A-Z]{2}\d{2}\d{8,15}').firstMatch(compact);
  return match?.group(0);
}

List<String> _textLines(String text) => text
    .split(RegExp(r'[\r\n]+'))
    .map((line) => line.replaceAll(RegExp(r'\s+'), ' ').trim())
    .where((line) => line.isNotEmpty)
    .toList();

String? extractDrivingLicenseName(String text) {
  final lines = _textLines(text);
  final labelledName = RegExp(
    r'^(?:name|नाम)\s*[:.-]?\s*(.+)$',
    caseSensitive: false,
  );
  for (final line in lines) {
    final match = labelledName.firstMatch(line);
    if (match != null && _isPersonName(match.group(1)!))
      return match.group(1)!.trim();
  }
  return lines.cast<String?>().firstWhere(
    (line) => line != null && _isPersonName(line),
    orElse: () => null,
  );
}

String? extractDrivingLicenseCity(String text) {
  final lines = _textLines(text);
  final labelledCity = RegExp(
    r'^(?:city|town|place)\s*[:.-]?\s*(.+)$',
    caseSensitive: false,
  );
  for (final line in lines) {
    final match = labelledCity.firstMatch(line);
    if (match != null && _isLocation(match.group(1)!))
      return match.group(1)!.trim();
  }
  final addressIndex = lines.indexWhere(
    (line) => RegExp(
      r'address|residing|r/o|s/o',
      caseSensitive: false,
    ).hasMatch(line),
  );
  if (addressIndex >= 0) {
    for (final line in lines.skip(addressIndex + 1)) {
      if (_isLocation(line)) return line;
    }
  }
  return lines.reversed.cast<String?>().firstWhere(
    (line) => line != null && _isLocation(line),
    orElse: () => null,
  );
}

bool _isPersonName(String value) {
  final normalized = value.toLowerCase();
  return RegExp(r'^[a-z .]{3,40}$').hasMatch(normalized) &&
      !RegExp(
        r'driving|licen|transport|government|india|address|valid|dob|blood|class',
      ).hasMatch(normalized);
}

bool _isLocation(String value) {
  final normalized = value.toLowerCase();
  return RegExp(r'^[a-z .-]{3,40}$').hasMatch(normalized) &&
      !RegExp(
        r'driving|licen|transport|government|india|name|address|dob|blood|class',
      ).hasMatch(normalized);
}
