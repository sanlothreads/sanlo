import 'package:equatable/equatable.dart';

/// A matched admin record from the Firebase `admin` node.
class AdminAccount extends Equatable {
  const AdminAccount({required this.name, required this.mobile});

  /// Display name, e.g. "SANLO THREADS".
  final String name;

  /// Stored mobile number (E.164, e.g. "+917665773775").
  final String mobile;

  @override
  List<Object?> get props => [name, mobile];
}

/// Decides whether a signed-in mobile number belongs to a shop admin and, when
/// it does, returns the matching admin record.
///
/// Backed by the Firebase Realtime Database `admin` node in production; a mock
/// implementation is used in tests. The presentation layer (router gate / sign
/// in) depends only on this interface.
abstract interface class AdminAccessRepository {
  /// Returns the matching [AdminAccount] when [mobile] is an admin, else null.
  Future<AdminAccount?> lookupAdmin(String? mobile);

  /// Convenience: true when [mobile] matches an admin entry.
  Future<bool> isAdmin(String? mobile);
}

/// Normalises a phone number to its last 10 digits for comparison, so
/// country-code and spacing differences do not matter
/// (e.g. "+91 76657 73775" and "7665773775" compare equal).
String normalizeMobile(String? mobile) {
  if (mobile == null) return '';
  final String digits = mobile.replaceAll(RegExp(r'\D'), '');
  if (digits.length <= 10) return digits;
  return digits.substring(digits.length - 10);
}
