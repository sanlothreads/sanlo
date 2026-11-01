import 'package:equatable/equatable.dart';

/// An OTP verification session created when a user requests a one-time code
/// for a mobile number.
class OtpSession extends Equatable {
  /// Opaque identifier for this verification session.
  final String sessionId;

  /// The mobile number (e.g. "+91...") the code was sent to.
  final String mobile;

  /// When the session (and its code) expires.
  final DateTime expiresAt;

  const OtpSession({
    required this.sessionId,
    required this.mobile,
    required this.expiresAt,
  });

  @override
  List<Object?> get props => [sessionId, mobile, expiresAt];
}
