import '../entities/auth_user.dart';
import '../entities/otp_session.dart';

/// Contract for authentication: OTP sign-in, account creation, and guest
/// sessions. Implementations may throw an [InvalidOtpFailure] from
/// [verifyOtp] when the code is wrong or expired.
abstract interface class AuthRepository {
  /// Requests an OTP for [mobile] (+91). Returns a session (mock: code "0000").
  Future<OtpSession> sendOtp({required String mobile});

  /// Verifies [code] against [sessionId]. Returns the signed-in user on
  /// success; throws an `InvalidOtpFailure` on an incorrect or expired code.
  Future<AuthUser> verifyOtp({required String sessionId, required String code});

  /// Creates an account from the sign-up form (mock: always succeeds).
  Future<AuthUser> createAccount(AuthUser draftUser);

  /// Starts a guest session (no credentials).
  Future<AuthUser> continueAsGuest();

  /// Currently signed-in user, or `null` if none.
  AuthUser? get currentUser;
}
