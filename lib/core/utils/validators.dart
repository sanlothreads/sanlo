/// Pure, dependency-free input validators used across the Sanlo app.
///
/// Two flavours are provided for most fields:
///   * `isValid*` predicates returning a [bool] (handy for Bloc/Cubit logic
///     and property tests), and
///   * `*Error` helpers returning a nullable error [String] in the shape
///     Flutter's `TextFormField.validator` expects (`null` == valid).
///
/// All functions are pure static methods with no side effects.
class Validators {
  Validators._();

  /// Expected OTP length (matches the mock code `"0000"`).
  static const int otpLength = 4;

  /// Indian mobile numbers are 10 digits locally (the UI adds the +91 prefix).
  static const int indianMobileLength = 10;

  // Matches a 10-digit Indian mobile number whose leading digit is 6-9.
  static final RegExp _indianMobile = RegExp(r'^[6-9]\d{9}$');

  // A pragmatic, single-line email check: non-space local part, "@", a
  // dotted domain with a 2+ char TLD. Deliberately not the full RFC 5322
  // grammar, which is impractical and rejects almost nothing extra in practice.
  static final RegExp _email = RegExp(
    r'^[\w.!#$%&*+/=?^`{|}~-]+@[A-Za-z0-9](?:[A-Za-z0-9-]*[A-Za-z0-9])?(?:\.[A-Za-z0-9](?:[A-Za-z0-9-]*[A-Za-z0-9])?)+$',
  );

  /// Normalises a mobile string to its 10-digit local part.
  ///
  /// Strips spaces, dashes, parentheses and a leading `+91`/`91`/`0`, so both
  /// `"+91 98765 43210"` and `"9876543210"` reduce to `"9876543210"`.
  static String normalizeMobile(String input) {
    var digits = input.replaceAll(RegExp(r'[\s()\-]'), '');
    if (digits.startsWith('+')) digits = digits.substring(1);
    if (digits.startsWith('91') && digits.length > indianMobileLength) {
      digits = digits.substring(2);
    } else if (digits.startsWith('0') &&
        digits.length > indianMobileLength) {
      digits = digits.substring(1);
    }
    return digits;
  }

  /// Returns `true` when [input] is a valid 10-digit Indian mobile number.
  ///
  /// The UI collects the number behind a `+91` prefix, so this validates the
  /// 10-digit local part. Any `+91`/`91`/`0` prefix and common separators are
  /// tolerated via [normalizeMobile]; the leading local digit must be 6-9.
  ///
  /// Validates Requirement 1.2.
  static bool isValidIndianMobile(String? input) {
    if (input == null) return false;
    return _indianMobile.hasMatch(normalizeMobile(input));
  }

  /// Form-field helper for the mobile field. Returns `null` when valid, or the
  /// inline message the Auth_System surfaces on an invalid number.
  ///
  /// Validates Requirement 1.2.
  static String? mobileError(String? input) {
    return isValidIndianMobile(input) ? null : 'Enter a valid 10-digit mobile';
  }

  /// Returns `true` when [input] is a well-formed OTP: exactly [otpLength]
  /// digits (matching the mock `"0000"` format). This checks format only; the
  /// Auth_System compares the value against the session's expected code.
  static bool isValidOtp(String? input) {
    if (input == null) return false;
    return RegExp('^\\d{$otpLength}\$').hasMatch(input);
  }

  /// Form-field helper for the OTP field. Returns `null` when valid.
  static String? otpError(String? input) {
    return isValidOtp(input) ? null : 'Enter the $otpLength-digit code';
  }

  /// Returns `true` when [input] is a well-formed email address.
  ///
  /// Optional-friendly: a `null`, empty, or whitespace-only value is treated as
  /// valid (callers use email as an optional field). A non-empty value must be
  /// well-formed.
  ///
  /// Validates Requirement 4.2.
  static bool isValidEmail(String? input) {
    if (input == null) return true;
    final trimmed = input.trim();
    if (trimmed.isEmpty) return true;
    return _email.hasMatch(trimmed);
  }

  /// Form-field helper for an optional email field. Returns `null` when valid
  /// (including when empty), or an error message for a malformed value.
  ///
  /// Validates Requirement 4.2.
  static String? emailError(String? input) {
    return isValidEmail(input) ? null : 'Enter a valid email';
  }

  /// Returns `true` when [input] parses to a positive measurement (in inches).
  ///
  /// Zero and negatives are rejected. Non-numeric or empty input is invalid.
  /// Used by the measurements step on the "I know" path.
  static bool isValidMeasurement(String? input) {
    if (input == null) return false;
    final value = double.tryParse(input.trim());
    if (value == null) return false;
    return value > 0 && value.isFinite;
  }

  /// Validates a measurement value directly (e.g. a parsed `double`).
  static bool isValidMeasurementValue(num? value) {
    if (value == null) return false;
    return value > 0 && value.isFinite;
  }

  /// Form-field helper for an in-inches measurement field. Returns `null` when
  /// valid, or an error message otherwise.
  static String? measurementError(String? input) {
    return isValidMeasurement(input) ? null : 'Enter a valid measurement in inches';
  }

  /// Returns `true` when [input] is a non-empty value after trimming.
  ///
  /// Used for required fields such as full name on the order details step.
  ///
  /// Validates Requirement 4.2.
  static bool isNonEmpty(String? input) {
    return input != null && input.trim().isNotEmpty;
  }

  /// Form-field helper for a generic required field. Returns `null` when a
  /// value is present, or a message naming the [fieldLabel].
  ///
  /// Validates Requirement 4.2.
  static String? requiredError(String? input, {String fieldLabel = 'This field'}) {
    return isNonEmpty(input) ? null : '$fieldLabel is required';
  }
}
