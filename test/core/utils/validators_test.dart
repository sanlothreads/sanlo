import 'package:flutter_test/flutter_test.dart';
import 'package:sanlo/core/utils/validators.dart';

void main() {
  group('isValidIndianMobile', () {
    test('accepts plain 10-digit numbers with leading 6-9', () {
      expect(Validators.isValidIndianMobile('9876543210'), isTrue);
      expect(Validators.isValidIndianMobile('6000000000'), isTrue);
    });

    test('tolerates +91 / 91 / 0 prefixes and separators', () {
      expect(Validators.isValidIndianMobile('+91 98765 43210'), isTrue);
      expect(Validators.isValidIndianMobile('09876543210'), isTrue);
      expect(Validators.isValidIndianMobile('98765-43210'), isTrue);
    });

    test('rejects bad leading digit, wrong length, and nulls', () {
      expect(Validators.isValidIndianMobile('1234567890'), isFalse);
      expect(Validators.isValidIndianMobile('98765'), isFalse);
      expect(Validators.isValidIndianMobile('98765432100'), isFalse);
      expect(Validators.isValidIndianMobile(null), isFalse);
      expect(Validators.isValidIndianMobile(''), isFalse);
    });

    test('mobileError surfaces the spec inline message', () {
      expect(Validators.mobileError('12345'), 'Enter a valid 10-digit mobile');
      expect(Validators.mobileError('9876543210'), isNull);
    });
  });

  group('isValidOtp', () {
    test('accepts 6-digit codes including 000000', () {
      expect(Validators.isValidOtp('000000'), isTrue);
      expect(Validators.isValidOtp('123456'), isTrue);
    });

    test('rejects wrong length or non-digits', () {
      expect(Validators.isValidOtp('123'), isFalse);
      expect(Validators.isValidOtp('1234'), isFalse);
      expect(Validators.isValidOtp('1234567'), isFalse);
      expect(Validators.isValidOtp('12a456'), isFalse);
      expect(Validators.isValidOtp(null), isFalse);
    });
  });

  group('isValidEmail (optional-friendly)', () {
    test('treats null/empty/whitespace as valid', () {
      expect(Validators.isValidEmail(null), isTrue);
      expect(Validators.isValidEmail(''), isTrue);
      expect(Validators.isValidEmail('   '), isTrue);
    });

    test('accepts well-formed addresses', () {
      expect(Validators.isValidEmail('a@b.com'), isTrue);
      expect(Validators.isValidEmail('first.last@sub.example.co'), isTrue);
    });

    test('rejects malformed non-empty addresses', () {
      expect(Validators.isValidEmail('not-an-email'), isFalse);
      expect(Validators.isValidEmail('a@b'), isFalse);
      expect(Validators.isValidEmail('a@@b.com'), isFalse);
    });
  });

  group('isValidMeasurement', () {
    test('accepts positive numbers', () {
      expect(Validators.isValidMeasurement('34.5'), isTrue);
      expect(Validators.isValidMeasurement('1'), isTrue);
      expect(Validators.isValidMeasurementValue(10), isTrue);
    });

    test('rejects zero, negatives, non-numeric, empty, null', () {
      expect(Validators.isValidMeasurement('0'), isFalse);
      expect(Validators.isValidMeasurement('-3'), isFalse);
      expect(Validators.isValidMeasurement('abc'), isFalse);
      expect(Validators.isValidMeasurement(''), isFalse);
      expect(Validators.isValidMeasurement(null), isFalse);
      expect(Validators.isValidMeasurementValue(0), isFalse);
    });
  });

  group('required helpers', () {
    test('isNonEmpty trims', () {
      expect(Validators.isNonEmpty('x'), isTrue);
      expect(Validators.isNonEmpty('   '), isFalse);
      expect(Validators.isNonEmpty(null), isFalse);
    });

    test('requiredError names the field', () {
      expect(
        Validators.requiredError('', fieldLabel: 'Full name'),
        'Full name is required',
      );
      expect(Validators.requiredError('Asha'), isNull);
    });
  });
}
