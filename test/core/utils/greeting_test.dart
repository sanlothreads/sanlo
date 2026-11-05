import 'package:flutter_test/flutter_test.dart';
import 'package:sanlo/core/utils/greeting.dart';

void main() {
  group('greetingFor', () {
    DateTime at(int hour) => DateTime(2025, 10, 25, hour, 30);

    test('boundaries map to the right greeting', () {
      expect(greetingFor(at(5)), 'Good morning');
      expect(greetingFor(at(11)), 'Good morning');
      expect(greetingFor(at(12)), 'Good afternoon');
      expect(greetingFor(at(16)), 'Good afternoon');
      expect(greetingFor(at(17)), 'Good evening');
      expect(greetingFor(at(20)), 'Good evening');
      expect(greetingFor(at(21)), 'Good night');
      expect(greetingFor(at(4)), 'Good night');
      expect(greetingFor(DateTime(2025, 10, 25, 0, 0)), 'Good night');
    });

    test('is total: every hour yields one of the four greetings', () {
      const Set<String> valid = <String>{
        'Good morning',
        'Good afternoon',
        'Good evening',
        'Good night',
      };
      for (int h = 0; h < 24; h++) {
        expect(valid.contains(greetingFor(at(h))), isTrue);
      }
    });
  });
}
