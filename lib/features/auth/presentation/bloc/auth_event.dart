import 'package:equatable/equatable.dart';

import '../../domain/entities/auth_user.dart';

/// Events accepted by the [AuthBloc].
///
/// Sealed so the bloc's `on<Event>` handlers exhaustively cover every case and
/// the compiler flags any new event that lacks a handler.
sealed class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => const [];
}

/// Requests a one-time code for [mobile] (the 10-digit local part; the UI adds
/// the +91 prefix). Invalid numbers surface an inline error without sending.
final class OtpRequested extends AuthEvent {
  const OtpRequested(this.mobile);

  /// The mobile number entered by the user.
  final String mobile;

  @override
  List<Object?> get props => [mobile];
}

/// Submits the [code] the user typed to verify the active OTP session.
final class OtpVerified extends AuthEvent {
  const OtpVerified(this.code);

  /// The OTP code entered by the user.
  final String code;

  @override
  List<Object?> get props => [code];
}

/// Requests a guest session (no credentials).
final class GuestRequested extends AuthEvent {
  const GuestRequested();
}

/// Dispatched once at startup to restore any persisted session. If a user is
/// already signed in (Firebase keeps the session across restarts), the bloc
/// loads their stored profile and moves to [AuthPhase.authenticated].
final class AppStarted extends AuthEvent {
  const AppStarted();
}

/// Signs the current user out and returns the flow to a signed-out state.
final class SignOutRequested extends AuthEvent {
  const SignOutRequested();
}

/// Submits edited profile fields for the signed-in user to be persisted. The
/// [user] carries the updated first/last name, email, gender, and address; the
/// mobile and uid are preserved by the repository.
final class ProfileUpdated extends AuthEvent {
  const ProfileUpdated(this.user);

  /// The edited user to persist.
  final AuthUser user;

  @override
  List<Object?> get props => [user];
}

/// Submits a sign-up draft to create a new account.
final class AccountSubmitted extends AuthEvent {
  const AccountSubmitted(this.draft);

  /// The draft user assembled from the sign-up form.
  final AuthUser draft;

  @override
  List<Object?> get props => [draft];
}

/// Resets the bloc back to its initial idle state.
final class AuthReset extends AuthEvent {
  const AuthReset();
}
