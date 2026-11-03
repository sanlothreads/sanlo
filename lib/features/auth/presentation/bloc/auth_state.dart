import 'package:equatable/equatable.dart';

import '../../domain/entities/auth_user.dart';
import '../../domain/entities/otp_session.dart';

/// The lifecycle phase of the authentication flow.
///
/// Modelled as a single enum on [AuthState] so UI widgets can switch on the
/// current phase and transitions are trivial to assert in tests.
enum AuthPhase {
  /// Nothing in progress; the initial state.
  idle,

  /// An OTP send request is in flight.
  sendingOtp,

  /// The OTP was sent; [AuthState.session] is populated.
  otpSent,

  /// An OTP verification request is in flight.
  verifying,

  /// A user is signed in (including guests); [AuthState.user] is populated.
  authenticated,

  /// OTP was verified for a number that has no profile yet: the user is
  /// signed in but must complete the Sign up form. [AuthState.user] carries
  /// the signed-in identity (uid + mobile) to seed that form.
  needsRegistration,

  /// An account-creation request is in flight.
  creating,

  /// An error occurred; [AuthState.errorMessage] describes it.
  error,
}

/// Immutable state for the [AuthBloc].
///
/// A single object carrying the current [phase] plus the data gathered along
/// the way ([session] after an OTP is sent, [user] once authenticated, and an
/// [errorMessage] when something goes wrong).
class AuthState extends Equatable {
  const AuthState({
    required this.phase,
    this.session,
    this.user,
    this.errorMessage,
  });

  /// The initial, idle state with no session, user, or error.
  const AuthState.idle()
    : phase = AuthPhase.idle,
      session = null,
      user = null,
      errorMessage = null;

  /// Current lifecycle phase.
  final AuthPhase phase;

  /// The active OTP session, present once [AuthPhase.otpSent] is reached.
  final OtpSession? session;

  /// The signed-in user, present once [AuthPhase.authenticated] is reached.
  final AuthUser? user;

  /// A human-readable error message, present in [AuthPhase.error].
  final String? errorMessage;

  /// Returns a copy with the given fields replaced.
  ///
  /// Because `session`, `user`, and `errorMessage` are nullable, pass the
  /// matching `clear*` flag to explicitly reset a field to `null` (a plain
  /// `null` argument is treated as "leave unchanged"). This is what lets a
  /// successful OTP send clear a previous [errorMessage].
  AuthState copyWith({
    AuthPhase? phase,
    OtpSession? session,
    AuthUser? user,
    String? errorMessage,
    bool clearSession = false,
    bool clearUser = false,
    bool clearError = false,
  }) {
    return AuthState(
      phase: phase ?? this.phase,
      session: clearSession ? null : (session ?? this.session),
      user: clearUser ? null : (user ?? this.user),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [phase, session, user, errorMessage];
}
