import 'package:flutter_test/flutter_test.dart';
import 'package:sanlo/core/utils/date_format.dart';

void main() {
  group('DateFormatX.formatTimestamp', () {
    test('formats DateTime as dd-MMM-YYYY hh:mm AM/PM', () {
      final dt = DateTime(2025, 5, 24, 14, 30);
      final formatted = DateFormatX.formatTimestamp(dt);
      expect(formatted, '24-May-2025 02:30 PM');
    });

    test('formats morning times with AM and padded zeroes', () {
      final dt = DateTime(2025, 1, 5, 9, 5);
      final formatted = DateFormatX.formatTimestamp(dt);
      expect(formatted, '05-Jan-2025 09:05 AM');
    });

    test('formats midnight properly as 12:00 AM', () {
      final dt = DateTime(2025, 12, 31, 0, 0);
      final formatted = DateFormatX.formatTimestamp(dt);
      expect(formatted, '31-Dec-2025 12:00 AM');
    });
  });
}
