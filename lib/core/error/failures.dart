import 'package:equatable/equatable.dart';

/// Base type for domain-level failures thrown by repositories.
///
/// Repositories throw subclasses of [Failure] to signal expected,
/// recoverable error conditions (as opposed to unexpected runtime errors),
/// so the presentation layer can map them to user-facing messages.
sealed class Failure extends Equatable implements Exception {
  const Failure([this.message]);

  /// Optional human-readable detail about what went wrong.
  final String? message;

  @override
  List<Object?> get props => [message];

  @override
  String toString() =>
      message == null ? runtimeType.toString() : '$runtimeType: $message';
}

/// Thrown when a requested resource (product, order, profile, ...) does not
/// exist.
final class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message]);
}

/// Thrown when an OTP code is invalid, expired, or does not match the session.
final class InvalidOtpFailure extends Failure {
  const InvalidOtpFailure([super.message]);
}

/// Thrown for authentication errors that are not a bad OTP code — e.g. the
/// verification code could not be sent, or sign-in failed for another reason.
final class AuthFailure extends Failure {
  const AuthFailure([super.message]);
}
